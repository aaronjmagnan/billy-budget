extends MiniGame
## PRESSURE LOCK: a needle sweeps across a bar. Lock it inside the green zone.
## Four locks, each one faster and tighter. 4/4 = WIN, 3/4 = NEAR.

const ROUNDS := 4
const ZONE_WIDTHS: Array[float] = [0.2, 0.15, 0.11, 0.08]
const SPEEDS: Array[float] = [0.8, 1.0, 1.25, 1.5]
const LOCK_TIME := 4.0  # seconds per lock before it counts as a miss

var round_index := 0
var needle := 0.0
var direction := 1.0
var zone_center := 0.5
var hits := 0
var marks: Array = []  # each: {"pos": float, "ok": bool}
var _pause_t := 0.0
var _lock_t := LOCK_TIME


func _game_ready() -> void:
	title = "PRESSURE LOCK"
	instructions = "Press SPACE or J when the needle is inside the green zone."
	_new_zone()


func _new_zone() -> void:
	zone_center = randf_range(0.15, 0.85)
	needle = 0.0
	direction = 1.0
	_lock_t = LOCK_TIME


func _game_process(delta: float) -> void:
	if _pause_t > 0.0:
		_pause_t -= delta
		if _pause_t <= 0.0:
			if round_index >= ROUNDS:
				if hits >= 4:
					end_game(Result.WIN)
				elif hits == 3:
					end_game(Result.NEAR)
				else:
					end_game(Result.FAIL)
			else:
				_new_zone()
		return
	_lock_t -= delta
	if _lock_t <= 0.0:
		_lock(false)
		return
	needle += direction * SPEEDS[round_index] * delta
	if needle >= 1.0:
		needle = 1.0
		direction = -1.0
	elif needle <= 0.0:
		needle = 0.0
		direction = 1.0


func _game_input(event: InputEvent) -> void:
	if _pause_t > 0.0 or round_index >= ROUNDS:
		return
	if not event.is_action_pressed("strike"):
		return
	_lock(absf(needle - zone_center) <= ZONE_WIDTHS[round_index] / 2.0)


func _lock(ok: bool) -> void:
	if ok:
		hits += 1
	marks.append({"pos": needle, "ok": ok})
	round_index += 1
	_pause_t = 0.6


func _game_draw(area: Rect2) -> void:
	var bar := Rect2(area.position.x + 40.0, area.get_center().y - 22.0, area.size.x - 80.0, 44.0)
	draw_rect(bar, Color(0.1, 0.09, 0.16))
	if round_index < ROUNDS:
		var w := ZONE_WIDTHS[round_index]
		var zone := Rect2(bar.position.x + (zone_center - w / 2.0) * bar.size.x, bar.position.y, w * bar.size.x, bar.size.y)
		draw_rect(zone, Color(0.3, 1.0, 0.45, 0.85))
	draw_rect(bar, accent, false, 2.0)
	var nx := bar.position.x + needle * bar.size.x
	draw_line(Vector2(nx, bar.position.y - 16.0), Vector2(nx, bar.end.y + 16.0), Color.WHITE, 4.0)

	# Results of previous locks
	for i in marks.size():
		var m: Dictionary = marks[i]
		var c := Color(0.4, 1, 0.5) if m["ok"] else Color(1, 0.3, 0.35)
		draw_circle(Vector2(area.get_center().x + (float(i) - 1.5) * 34.0, bar.end.y + 56.0), 10.0, c)
	for i in range(marks.size(), ROUNDS):
		draw_arc(Vector2(area.get_center().x + (float(i) - 1.5) * 34.0, bar.end.y + 56.0), 10.0, 0, TAU, 16, accent.darkened(0.4), 1.5)

	var label := "LOCK %d / %d   ·   %ds" % [mini(round_index + 1, ROUNDS), ROUNDS, ceili(maxf(_lock_t, 0.0))]
	draw_string(font, Vector2(area.position.x, area.end.y - 6.0), label, HORIZONTAL_ALIGNMENT_CENTER, area.size.x, 16, Color(0.8, 0.8, 0.9))
