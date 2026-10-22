extends MiniGame
## STATIC RAIN: steer a little ship left and right, avoid the falling static.
## Survive 14 seconds. No hits = WIN, 1 or 2 hits = NEAR, 3 hits = FAIL.

const DURATION := 14.0
const MAX_HITS := 3
const SHIP_SPEED := 0.95  # fraction of the play area per second

var ship_x := 0.5
var blocks: Array = []  # each: {"x": float 0..1, "y": float px, "w": float 0..1, "speed": float}
var elapsed := 0.0
var hits := 0
var _spawn_t := 0.0
var _invuln := 0.0


func _game_ready() -> void:
	title = "STATIC RAIN"
	instructions = "Move with A/D or the arrow keys. Avoid the static for 14 seconds."


func _game_process(delta: float) -> void:
	elapsed += delta
	_invuln = maxf(_invuln - delta, 0.0)
	var axis := Input.get_axis("move_left", "move_right")
	ship_x = clampf(ship_x + axis * SHIP_SPEED * delta, 0.03, 0.97)

	_spawn_t -= delta
	if _spawn_t <= 0.0:
		_spawn_t = lerpf(0.45, 0.2, elapsed / DURATION)
		blocks.append({
			"x": randf(), "y": -20.0, "w": randf_range(0.04, 0.09), "speed": randf_range(220.0, 360.0),
		})

	var area := play_rect()
	var ship := _ship_rect(area)
	for b: Dictionary in blocks:
		b["y"] = float(b["y"]) + float(b["speed"]) * delta
		if _invuln <= 0.0 and _block_rect(area, b).intersects(ship):
			hits += 1
			_invuln = 0.8
			b["y"] = 99999.0
	blocks = blocks.filter(func(b: Dictionary) -> bool: return float(b["y"]) < area.size.y)

	if hits >= MAX_HITS:
		end_game(Result.FAIL)
	elif elapsed >= DURATION:
		end_game(Result.WIN if hits == 0 else Result.NEAR)


func _ship_rect(area: Rect2) -> Rect2:
	var x := area.position.x + ship_x * area.size.x
	return Rect2(x - 14.0, area.end.y - 34.0, 28.0, 20.0)


func _block_rect(area: Rect2, b: Dictionary) -> Rect2:
	var w := float(b["w"]) * area.size.x
	return Rect2(area.position.x + float(b["x"]) * area.size.x - w / 2.0, area.position.y + float(b["y"]), w, 16.0)


func _game_draw(area: Rect2) -> void:
	draw_rect(area, Color(0.05, 0.05, 0.09))
	for b: Dictionary in blocks:
		var r := _block_rect(area, b).intersection(area)
		if r.has_area():
			draw_rect(r, accent)
	var ship := _ship_rect(area)
	var ship_color := Color.WHITE
	if _invuln > 0.0 and int(_invuln * 20.0) % 2 == 0:
		ship_color.a = 0.3
	draw_colored_polygon(PackedVector2Array([
		Vector2(ship.get_center().x, ship.position.y), ship.end, Vector2(ship.position.x, ship.end.y),
	]), ship_color)

	# Time bar
	var t := clampf(elapsed / DURATION, 0.0, 1.0)
	draw_rect(Rect2(area.position.x, area.position.y - 10.0, area.size.x * t, 4.0), accent)
	var label := "HITS %d / %d" % [hits, MAX_HITS]
	draw_string(font, Vector2(area.position.x, area.position.y + 20.0), label, HORIZONTAL_ALIGNMENT_CENTER, area.size.x, 16, Color(0.8, 0.8, 0.9))
