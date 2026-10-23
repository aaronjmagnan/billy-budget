extends Node2D
## One arcade floor. Lower half: four cabinets and roaming beasts.
## Upper half: the boss arena, behind a sealed door.
##
## Rules (see DESIGN.md):
##   - Play a cabinet: WIN = pure item, NEAR = cracked item, FAIL = containment cracks.
##   - Containment hits zero: the beast escapes. Beat it for a RAW item.
##   - Cracked cabinets can fail on their own later.
##   - The door needs `items_to_cross` items. Crossing with fewer costs hearts.
##   - Each item strips or weakens one of the boss's four facets.
##
## The exported values below show up in the Inspector when you select the Floor node.

@export_group("Threshold")
@export var items_to_cross := 2
@export var threshold_heart_cost := 2

@export_group("Player")
@export var player_max_hearts := 6

@export_group("Camera")
## How close the camera sits. 1.0 shows the whole room; higher = bigger characters.
@export_range(1.0, 3.0, 0.1) var camera_zoom := 1.7

@export_group("Containment")
## Seconds between checks for cracked cabinets failing on their own.
@export var late_breach_interval := 12.0
## Chance per crack, per check, that a cracked cabinet bursts.
@export_range(0.0, 1.0) var late_breach_chance_per_crack := 0.12

@export_group("Enemies")
@export var roaming_beasts := 2
@export var boss_max_hp := 16.0

const ROOM := Rect2(40, 40, 1200, 660)
const WALL := 16.0
const DIVIDER_Y := 292.0
const DOOR_LEFT := 580.0
const DOOR_RIGHT := 700.0
const ARENA := Rect2(56, 56, 1168, 236)
const BOSS_START := Vector2(640, 160)

const MINIGAMES := {
	"rhythm": preload("res://scripts/minigames/rhythm_game.gd"),
	"memory": preload("res://scripts/minigames/memory_game.gd"),
	"timing": preload("res://scripts/minigames/timing_game.gd"),
	"dodge": preload("res://scripts/minigames/dodge_game.gd"),
}

@onready var player: Player = $Player
@onready var overlay: CanvasLayer = $Overlay
@onready var hud: Control = $HUD/HUDView

var cabinets: Array[Cabinet] = []
var items: Array = []  # each: {"name", "color", "facet", "kind": "pure" | "cracked" | "raw"}
var boss: Boss
var state := "explore"  # explore, minigame, boss, won, lost
var door_open := false
var door_locked_behind := false
var prompt := ""
var message := ""
var message_t := 0.0

var _door_shape: CollisionShape2D
var _door_warned := false
var _active_cabinet: Cabinet
var _breach_t := 0.0
var _target_cabinet: Cabinet = null
var _target_door := false


func _ready() -> void:
	_build_walls()
	_add_camera()
	for child in get_children():
		if child is Cabinet:
			cabinets.append(child)

	player.max_hearts = player_max_hearts
	player.hearts = player_max_hearts
	player.died.connect(_on_player_died)

	boss = Boss.new()
	boss.max_hp = boss_max_hp
	boss.position = BOSS_START
	boss.arena = ARENA
	boss.player = player
	for c in cabinets:
		boss.facet_colors[c.facet_index] = c.neon_color
	boss.defeated.connect(_on_boss_defeated)
	add_child(boss)

	var spots := [Vector2(150, 640), Vector2(1130, 640), Vector2(640, 380), Vector2(330, 360)]
	for i in mini(roaming_beasts, spots.size()):
		_spawn_beast(spots[i], null)

	_breach_t = late_breach_interval
	hud.level = self
	show_message("Get at least %d items, then cross the door." % items_to_cross, 5.0)


func _process(delta: float) -> void:
	message_t = maxf(message_t - delta, 0.0)
	queue_redraw()
	if state == "won" or state == "lost" or state == "minigame":
		prompt = ""
		return

	_update_interaction()
	if Input.is_action_just_pressed("interact"):
		if _target_cabinet != null:
			_start_minigame(_target_cabinet)
		elif _target_door:
			_try_door()

	_breach_t -= delta
	if _breach_t <= 0.0:
		_breach_t = late_breach_interval
		_roll_late_breaches()

	if door_open and not door_locked_behind and player.global_position.y < DIVIDER_Y - 34.0:
		door_locked_behind = true
		_door_shape.set_deferred("disabled", false)
		state = "boss"
		boss.activate()
		show_message("The door seals behind you.", 2.5)


# --- Interaction -----------------------------------------------------------

func _update_interaction() -> void:
	_target_cabinet = null
	_target_door = false
	prompt = ""
	var best := 76.0
	for c in cabinets:
		if not c.is_playable():
			continue
		var d := player.global_position.distance_to(c.interact_point())
		if d < best:
			best = d
			_target_cabinet = c
	if not door_open and player.global_position.distance_to(Vector2((DOOR_LEFT + DOOR_RIGHT) / 2.0, DIVIDER_Y + 20.0)) < 80.0:
		_target_cabinet = null
		_target_door = true

	if _target_cabinet != null:
		var c := _target_cabinet
		prompt = "[E] Play %s   ·   containment %d / %d" % [c.cabinet_name, c.containment, c.max_containment]
	elif _target_door:
		if items.size() >= items_to_cross:
			prompt = "[E] Cross the threshold"
		elif _door_warned:
			prompt = "[E] Cross anyway  (costs %d hearts)" % threshold_heart_cost
		else:
			prompt = "[E] The door hums. %d / %d items." % [items.size(), items_to_cross]


func _start_minigame(cabinet: Cabinet) -> void:
	if _active_cabinet != null:
		return
	_active_cabinet = cabinet
	state = "minigame"
	var script: GDScript = MINIGAMES.get(cabinet.game_type, MINIGAMES["rhythm"])
	var game: MiniGame = script.new()
	game.accent = cabinet.neon_color
	game.finished.connect(_on_minigame_finished)
	overlay.add_child(game)
	get_tree().paused = true


func _on_minigame_finished(result: int) -> void:
	get_tree().paused = false
	if _active_cabinet == null:
		return
	state = "boss" if door_locked_behind else "explore"
	var c := _active_cabinet
	_active_cabinet = null
	match result:
		MiniGame.Result.WIN:
			_grant_item(c, "pure")
		MiniGame.Result.NEAR:
			_grant_item(c, "cracked")
		_:
			if c.crack():
				_breach(c)
			else:
				show_message("%s's containment cracked. %d left. Try again?" % [c.cabinet_name, c.containment], 3.0)


func _try_door() -> void:
	if items.size() >= items_to_cross:
		_open_door()
	elif not _door_warned:
		_door_warned = true
		show_message("Not enough items. You can force it, but it will hurt.", 3.0)
	else:
		player.take_damage(threshold_heart_cost, true)
		if not player.dead:
			_open_door()
			show_message("The threshold burns as you push through.", 3.0)


func _open_door() -> void:
	door_open = true
	_door_shape.set_deferred("disabled", true)


# --- Items, breaches, beasts ----------------------------------------------

func _grant_item(c: Cabinet, kind: String) -> void:
	c.state = Cabinet.State.DONE
	items.append({"name": c.item_name, "color": c.neon_color, "facet": c.facet_index, "kind": kind})
	match kind:
		"pure":
			boss.weaken_facet(c.facet_index, 1.0)
			show_message("Pure %s. A facet of the boss goes dark." % c.item_name, 3.0)
		"cracked":
			boss.weaken_facet(c.facet_index, 0.5)
			show_message("Cracked %s. It only half works." % c.item_name, 3.0)
		"raw":
			boss.weaken_facet(c.facet_index, 1.0)
			player.strike_damage += 1.0
			player.change_max_hearts(-1)
			show_message("RAW %s: +1 strike damage, but -1 max heart." % c.item_name, 3.5)


func _breach(c: Cabinet) -> void:
	c.state = Cabinet.State.BREACHED
	var spawn := c.global_position + Vector2(0, 30)
	if door_locked_behind:
		spawn = Vector2(640, DIVIDER_Y - 40.0)  # it follows you into the arena
	var beast := _spawn_beast(spawn, c)
	show_message("The %s beast broke free! Beat it for a RAW item." % c.cabinet_name, 3.0)


func _roll_late_breaches() -> void:
	for c in cabinets:
		if c.is_playable() and c.cracks() > 0:
			if randf() < late_breach_chance_per_crack * float(c.cracks()):
				c.containment = 0
				_breach(c)
				show_message("%s failed on its own!" % c.cabinet_name, 3.0)
				return


func _spawn_beast(at: Vector2, from_cabinet: Cabinet) -> Beast:
	var beast: Beast
	if from_cabinet != null and from_cabinet.beast_kind == "beat_beast":
		var wolf := BeatBeast.new()
		wolf.room_bounds = ROOM
		beast = wolf
	else:
		beast = Beast.new()
	beast.position = at
	beast.player = player
	if from_cabinet != null:
		beast.escaped_from = from_cabinet
		beast.color = from_cabinet.neon_color
		beast.max_hp = 6.0
		beast.speed = 120.0
		beast.hit_radius = 18.0
		beast.always_hunting = true
		beast.defeated.connect(_on_escaped_beast_defeated)
		if beast is BeatBeast:
			beast.max_hp = 9.0
			beast.speed = 105.0
	else:
		beast.color = Color(0.55, 0.45, 0.85)
		beast.max_hp = 2.0
		beast.speed = 85.0
	add_child(beast)
	return beast


func _on_escaped_beast_defeated(beast: Beast) -> void:
	if beast.escaped_from != null:
		_grant_item(beast.escaped_from, "raw")


# --- End states -----------------------------------------------------------

func _on_boss_defeated() -> void:
	state = "won"
	show_message("", 0.0)


func _on_player_died() -> void:
	state = "lost"


func show_message(text: String, seconds: float) -> void:
	message = text
	message_t = seconds


# --- Room building and drawing ------------------------------------------

func _add_camera() -> void:
	var cam := Camera2D.new()
	cam.zoom = Vector2(camera_zoom, camera_zoom)
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 7.0
	cam.limit_left = int(ROOM.position.x) - 20
	cam.limit_top = int(ROOM.position.y) - 40  # room for the HUD strip
	cam.limit_right = int(ROOM.end.x) + 20
	cam.limit_bottom = int(ROOM.end.y) + 40
	player.add_child(cam)
	cam.make_current()


func _build_walls() -> void:
	var rects := [
		Rect2(ROOM.position.x, ROOM.position.y, ROOM.size.x, WALL),
		Rect2(ROOM.position.x, ROOM.end.y - WALL, ROOM.size.x, WALL),
		Rect2(ROOM.position.x, ROOM.position.y, WALL, ROOM.size.y),
		Rect2(ROOM.end.x - WALL, ROOM.position.y, WALL, ROOM.size.y),
		Rect2(ROOM.position.x, DIVIDER_Y, DOOR_LEFT - ROOM.position.x, WALL),
		Rect2(DOOR_RIGHT, DIVIDER_Y, ROOM.end.x - DOOR_RIGHT, WALL),
	]
	for r: Rect2 in rects:
		_add_wall(r)
	_door_shape = _add_wall(Rect2(DOOR_LEFT, DIVIDER_Y, DOOR_RIGHT - DOOR_LEFT, WALL))


func _add_wall(r: Rect2) -> CollisionShape2D:
	var body := StaticBody2D.new()
	body.position = r.get_center()
	var shape := RectangleShape2D.new()
	shape.size = r.size
	var col := CollisionShape2D.new()
	col.shape = shape
	body.add_child(col)
	add_child(body)
	return col


func _draw() -> void:
	# Floor
	draw_rect(ROOM, Color(0.05, 0.04, 0.09))
	var grid_color := Color(0.12, 0.09, 0.2, 0.6)
	var x := ROOM.position.x
	while x < ROOM.end.x:
		draw_line(Vector2(x, DIVIDER_Y + WALL), Vector2(x, ROOM.end.y), grid_color, 1.0)
		x += 48.0
	var y := DIVIDER_Y + WALL
	while y < ROOM.end.y:
		draw_line(Vector2(ROOM.position.x, y), Vector2(ROOM.end.x, y), grid_color, 1.0)
		y += 48.0
	# Arena glows faintly red
	draw_rect(ARENA, Color(0.12, 0.03, 0.07))

	# Walls
	var wall_color := Color(0.16, 0.12, 0.26)
	draw_rect(Rect2(ROOM.position.x, ROOM.position.y, ROOM.size.x, WALL), wall_color)
	draw_rect(Rect2(ROOM.position.x, ROOM.end.y - WALL, ROOM.size.x, WALL), wall_color)
	draw_rect(Rect2(ROOM.position.x, ROOM.position.y, WALL, ROOM.size.y), wall_color)
	draw_rect(Rect2(ROOM.end.x - WALL, ROOM.position.y, WALL, ROOM.size.y), wall_color)
	draw_rect(Rect2(ROOM.position.x, DIVIDER_Y, DOOR_LEFT - ROOM.position.x, WALL), wall_color)
	draw_rect(Rect2(DOOR_RIGHT, DIVIDER_Y, ROOM.end.x - DOOR_RIGHT, WALL), wall_color)

	# The threshold door
	var door := Rect2(DOOR_LEFT, DIVIDER_Y, DOOR_RIGHT - DOOR_LEFT, WALL)
	var closed := not door_open or door_locked_behind
	var can_cross := items.size() >= items_to_cross
	var door_color := Color(0.4, 1.0, 0.5) if can_cross else Color(1.0, 0.3, 0.4)
	if closed:
		draw_rect(door, door_color.darkened(0.5))
		for i in 6:
			var bx := DOOR_LEFT + 10.0 + float(i) * 20.0
			draw_line(Vector2(bx, DIVIDER_Y), Vector2(bx, DIVIDER_Y + WALL), door_color, 3.0)
	else:
		draw_rect(door, door_color, false, 1.0)
	if not door_locked_behind:
		var font := ThemeDB.fallback_font
		var label := "THRESHOLD  %d / %d" % [items.size(), items_to_cross]
		draw_string(font, Vector2(DOOR_LEFT - 40.0, DIVIDER_Y + WALL + 18.0), label, HORIZONTAL_ALIGNMENT_CENTER, DOOR_RIGHT - DOOR_LEFT + 80.0, 13, door_color)
