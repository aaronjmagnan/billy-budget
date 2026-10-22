extends SceneTree
## Headless smoke test. Plays through the stage 1 loop with no keyboard:
## lose a cabinet, win one, near-miss one, break one open and beat its beast,
## cross the threshold, and defeat the boss. Also checks the forced-crossing cost.
##
## Run from the project folder:
##   godot --headless --path . -s res://tests/smoke_test.gd

const STEP := 1.0 / 30.0

var failures := 0


func _initialize() -> void:
	_run()


func check(condition: bool, label: String) -> void:
	if condition:
		print("PASS  ", label)
	else:
		failures += 1
		printerr("FAIL  ", label)


func frames(n: int) -> void:
	for i in n:
		await process_frame


func load_level() -> Node:
	var level: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await frames(5)
	return level


## Starts a cabinet's mini-game and either lets it run out with no input
## (forced_result = -1) or ends it with the given result.
func play_cabinet(level: Node, cabinet: Cabinet, forced_result: int) -> void:
	level._start_minigame(cabinet)
	var game: MiniGame = level.overlay.get_child(level.overlay.get_child_count() - 1)
	var done := [false]
	game.finished.connect(func(_r: int) -> void: done[0] = true)
	var t := 0.0
	while not done[0] and t < 60.0:
		if forced_result >= 0 and game.phase == "play":
			game.end_game(forced_result)
		game._process(STEP)
		t += STEP
	check(done[0], "%s mini-game finished (%.0fs simulated)" % [cabinet.cabinet_name, t])
	await frames(3)


func _run() -> void:
	# --- Full loop -------------------------------------------------------
	var level := await load_level()
	check(level.cabinets.size() == 4, "four cabinets on the floor")
	check(level.boss != null, "boss spawned")
	var beat: Cabinet = level.get_node("BeatKeeper")
	var echo: Cabinet = level.get_node("EchoGrid")
	var lock: Cabinet = level.get_node("PressureLock")
	var player: Player = level.player
	check(player._sprite != null, "Bud's sprite sheet loaded")
	check(player._sprite.sprite_frames.get_animation_names().size() == Player.BUD_ANIMATIONS.size(), "all of Bud's animations built")
	var wisp: Beast = null
	for e in level.get_tree().get_nodes_in_group("enemies"):
		if e is Beast and e.escaped_from == null:
			wisp = e
	if wisp != null:
		var hp_before := wisp.hp
		wisp.take_hit(0.1, Vector2.RIGHT)  # a paper-weak hit
		check(is_equal_approx(wisp.hp, hp_before - 0.1), "fractional damage lands (0.1)")

	# Each mini-game type runs to completion on its own (no input = a loss).
	await play_cabinet(level, beat, -1)
	check(beat.containment == 2, "losing BEAT KEEPER cracks its containment")
	check(not paused, "game unpauses after a mini-game")
	await play_cabinet(level, echo, -1)
	await play_cabinet(level, lock, -1)
	await play_cabinet(level, level.get_node("StaticRain"), -1)

	# STATIC RAIN can pay out a cracked item even with no input, so count from here.
	var before: int = level.items.size()
	await play_cabinet(level, beat, MiniGame.Result.WIN)
	check(beat.state == Cabinet.State.DONE, "winning marks the cabinet done")
	check(level.items.size() == before + 1 and level.items[-1]["kind"] == "pure", "win grants a pure item")
	check(level.boss.facet_strength[0] == 0.0, "pure item strips its boss facet")

	# ECHO GRID has 2 containment and already lost once: a near miss still pays out.
	await play_cabinet(level, echo, MiniGame.Result.NEAR)
	check(level.items[-1]["kind"] == "cracked", "near miss grants a cracked item")
	check(level.boss.facet_strength[1] == 0.5, "cracked item half-weakens its facet")

	# Break PRESSURE LOCK open (3 containment, already lost once).
	await play_cabinet(level, lock, MiniGame.Result.FAIL)
	await play_cabinet(level, lock, MiniGame.Result.FAIL)
	check(lock.state == Cabinet.State.BREACHED, "PRESSURE LOCK breached after running out of containment")
	var escaped: Beast = null
	for e in level.get_tree().get_nodes_in_group("enemies"):
		if e is Beast and e.escaped_from == lock:
			escaped = e
	check(escaped != null, "an escaped beast appeared")
	var wait := 0
	while is_instance_valid(escaped) and escaped._spawn_t > 0.0 and wait < 600:
		await physics_frame  # let it finish tearing free
		wait += 1
	before = level.items.size()
	var guard := 0
	while is_instance_valid(escaped) and guard < 20:
		escaped.take_hit(1, Vector2.RIGHT)
		guard += 1
	await frames(2)
	check(level.items.size() == before + 1 and level.items[-1]["kind"] == "raw", "beating the escaped beast grants a raw item")
	check(player.strike_damage == 2 and player.max_hearts == 5, "raw item side effect applied")

	# Cross the threshold and fight the boss.
	level._try_door()
	check(level.door_open, "door opens with enough items")
	player.global_position = Vector2(640, 200)
	await frames(5)
	check(level.state == "boss" and level.boss.active, "entering the arena wakes the boss and seals the door")
	await frames(60)  # let it fire at least once
	player.hearts = 99  # keep the test kid alive
	guard = 0
	while not level.boss.dead and guard < 200:
		level.boss.take_hit(player.strike_damage, Vector2.UP)
		guard += 1
	await frames(2)
	check(level.state == "won", "defeating the boss clears the floor (%d hits)" % guard)
	level.queue_free()
	await frames(3)

	# --- Forcing the threshold with no items ------------------------------
	level = await load_level()
	var p: Player = level.player
	level._try_door()
	check(not level.door_open, "first try at the door only warns")
	level._try_door()
	check(level.door_open and p.hearts == p.max_hearts - level.threshold_heart_cost, "forcing the door costs hearts")
	level.queue_free()
	await frames(3)

	print("")
	print("SMOKE TEST: %s (%d failure%s)" % ["OK" if failures == 0 else "FAILED", failures, "" if failures == 1 else "s"])
	quit(1 if failures > 0 else 0)
