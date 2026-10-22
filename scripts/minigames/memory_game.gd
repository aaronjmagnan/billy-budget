extends MiniGame
## ECHO GRID: watch a pattern of four pads light up, then repeat it with the movement keys.
## No mistakes = WIN, one mistake = NEAR, two = FAIL.

const SEQUENCE_LENGTH := 6
const SHOW_ON := 0.5
const SHOW_GAP := 0.2
const INPUT_TIME := 12.0
const ACTIONS := ["move_up", "move_right", "move_down", "move_left"]
const DIRECTIONS := [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]

var sequence: Array[int] = []
var step := "show"  # show, input
var show_index := 0
var input_index := 0
var mistakes := 0
var input_time_left := INPUT_TIME
var _show_t := 0.5
var _lit := -1
var _lit_t := 0.0
var _lit_bad := false


func _game_ready() -> void:
	title = "ECHO GRID"
	instructions = "Watch the pattern, then repeat it with WASD or the arrow keys."
	for i in SEQUENCE_LENGTH:
		sequence.append(randi() % 4)


func _game_process(delta: float) -> void:
	if step == "show":
		_show_t -= delta
		if _show_t > 0.0:
			return
		if _lit == -1:
			if show_index >= SEQUENCE_LENGTH:
				step = "input"
				return
			_lit = sequence[show_index]
			_lit_bad = false
			_show_t = SHOW_ON
		else:
			_lit = -1
			show_index += 1
			_show_t = SHOW_GAP
	else:
		_lit_t -= delta
		if _lit_t <= 0.0:
			_lit = -1
		input_time_left -= delta
		if input_time_left <= 0.0:
			end_game(Result.FAIL)


func _game_input(event: InputEvent) -> void:
	if step != "input":
		return
	for i in ACTIONS.size():
		if event.is_action_pressed(ACTIONS[i]):
			_press(i)
			return


func _press(pad: int) -> void:
	_lit = pad
	_lit_t = 0.2
	if pad == sequence[input_index]:
		_lit_bad = false
		input_index += 1
		if input_index >= SEQUENCE_LENGTH:
			end_game(Result.WIN if mistakes == 0 else Result.NEAR)
	else:
		_lit_bad = true
		mistakes += 1
		if mistakes >= 2:
			end_game(Result.FAIL)


func _game_draw(area: Rect2) -> void:
	var center := area.get_center() + Vector2(0, -14)
	for i in 4:
		var dir: Vector2 = DIRECTIONS[i]
		var side := dir.orthogonal()
		var base := center + dir * 40.0
		var tip := center + dir * 110.0
		var tri := PackedVector2Array([tip, base + side * 50.0, base - side * 50.0])
		var c := accent.darkened(0.75)
		if i == _lit:
			c = Color(1, 0.3, 0.35) if _lit_bad else accent
		draw_colored_polygon(tri, c)
		var outline := tri.duplicate()
		outline.append(tri[0])
		draw_polyline(outline, accent.darkened(0.3), 2.0)

	# Progress dots
	var shown := show_index if step == "show" else input_index
	var dot_y := area.end.y - 34.0
	for i in SEQUENCE_LENGTH:
		var x := center.x + (float(i) - float(SEQUENCE_LENGTH - 1) / 2.0) * 22.0
		if i < shown:
			draw_circle(Vector2(x, dot_y), 6.0, accent)
		else:
			draw_arc(Vector2(x, dot_y), 6.0, 0, TAU, 16, accent.darkened(0.4), 1.5)

	var label := "WATCH..." if step == "show" else "YOUR TURN  ·  MISTAKES %d (1 allowed)  ·  %ds" % [mistakes, ceili(input_time_left)]
	draw_string(font, Vector2(area.position.x, area.end.y - 6.0), label, HORIZONTAL_ALIGNMENT_CENTER, area.size.x, 16, Color(0.8, 0.8, 0.9))
