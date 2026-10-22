extends MiniGame
## BEAT KEEPER: notes slide toward a line; press strike as each one crosses it.
## Off-beat presses cost you, so mashing doesn't work.

const NOTE_COUNT := 12
const TRAVEL_TIME := 1.8
const HIT_WINDOW := 0.13
const WIN_SCORE := 10
const NEAR_SCORE := 7

var notes: Array = []  # each: {"t": float, "state": 0 pending / 1 hit / 2 missed}
var song_time := -0.3
var hits := 0
var whiffs := 0
var _pulse := 0.0
var _judgement := ""
var _judgement_t := 0.0


func _game_ready() -> void:
	title = "BEAT KEEPER"
	instructions = "Press SPACE or J as each note crosses the line."
	var gaps: Array[float] = [0.5, 0.5, 0.5, 0.75, 0.25]
	var t := 1.0
	for i in NOTE_COUNT:
		notes.append({"t": t, "state": 0})
		t += gaps.pick_random()


func _game_process(delta: float) -> void:
	song_time += delta
	_pulse = maxf(_pulse - delta * 4.0, 0.0)
	_judgement_t -= delta
	for n: Dictionary in notes:
		if n["state"] == 0 and song_time > float(n["t"]) + HIT_WINDOW:
			n["state"] = 2
			_judge("MISS")
	if song_time > float(notes[-1]["t"]) + 0.6:
		var score := hits - whiffs
		if score >= WIN_SCORE:
			end_game(Result.WIN)
		elif score >= NEAR_SCORE:
			end_game(Result.NEAR)
		else:
			end_game(Result.FAIL)


func _game_input(event: InputEvent) -> void:
	if not event.is_action_pressed("strike"):
		return
	var best: Dictionary = {}
	var best_d := 999.0
	for n: Dictionary in notes:
		if n["state"] != 0:
			continue
		var d := absf(float(n["t"]) - song_time)
		if d < best_d:
			best_d = d
			best = n
	if not best.is_empty() and best_d <= HIT_WINDOW:
		best["state"] = 1
		hits += 1
		_pulse = 1.0
		_judge("PERFECT" if best_d < 0.05 else "HIT")
	else:
		whiffs += 1
		_judge("OFF BEAT")


func _judge(text: String) -> void:
	_judgement = text
	_judgement_t = 0.5


func _game_draw(area: Rect2) -> void:
	var lane_y := area.get_center().y
	var line_x := area.position.x + 110.0
	var lane_w := area.size.x - 140.0
	draw_line(Vector2(area.position.x, lane_y), Vector2(area.end.x, lane_y), accent.darkened(0.6), 2.0)
	var line_color := accent.lerp(Color.WHITE, _pulse)
	draw_line(Vector2(line_x, lane_y - 50.0), Vector2(line_x, lane_y + 50.0), line_color, 4.0 + 4.0 * _pulse)

	for n: Dictionary in notes:
		var x := line_x + (float(n["t"]) - song_time) / TRAVEL_TIME * lane_w
		if x < area.position.x - 20.0 or x > area.end.x + 20.0:
			continue
		var c := accent
		if n["state"] == 1:
			continue
		elif n["state"] == 2:
			c = Color(1, 0.25, 0.3, 0.6)
		var s := 14.0
		var diamond := PackedVector2Array([
			Vector2(x, lane_y - s), Vector2(x + s, lane_y), Vector2(x, lane_y + s), Vector2(x - s, lane_y),
		])
		draw_colored_polygon(diamond, c)

	if _judgement_t > 0.0:
		var jc := Color(1, 0.35, 0.4) if _judgement in ["MISS", "OFF BEAT"] else Color(0.6, 1, 0.7)
		draw_string(font, Vector2(line_x - 60.0, lane_y - 70.0), _judgement, HORIZONTAL_ALIGNMENT_CENTER, 120, 18, jc)

	var score_text := "HITS %d / %d    OFF BEAT %d    NEED %d CLEAN" % [hits, NOTE_COUNT, whiffs, WIN_SCORE]
	draw_string(font, Vector2(area.position.x, area.end.y - 10.0), score_text, HORIZONTAL_ALIGNMENT_CENTER, area.size.x, 16, Color(0.8, 0.8, 0.9))
