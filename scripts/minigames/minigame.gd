class_name MiniGame
extends Control
## Base class for every cabinet mini-game. Runs while the rest of the floor is paused.
## A subclass overrides the _game_* hooks and calls end_game() with a Result.
##   WIN  -> pure item
##   NEAR -> cracked item (weaker)
##   FAIL -> the cabinet's containment cracks

signal finished(result: int)

enum Result { WIN, NEAR, FAIL }

const PANEL_SIZE := Vector2(760, 440)
const INTRO_TIME := 2.2
const RESULT_TIME := 1.5

var title := "CABINET"
var instructions := ""
var accent := Color(0.3, 0.9, 1.0)
var phase := "intro"  # intro, play, result
var font: Font

var _timer := 0.0
var _result := Result.FAIL
var _emitted := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	font = ThemeDB.fallback_font
	_timer = INTRO_TIME
	_game_ready()


func _process(delta: float) -> void:
	match phase:
		"intro":
			_timer -= delta
			if _timer <= 0.0:
				phase = "play"
				_game_start()
		"play":
			_game_process(delta)
		"result":
			_timer -= delta
			if _timer <= 0.0 and not _emitted:
				_emitted = true
				finished.emit(_result)
				queue_free()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if phase == "play":
		_game_input(event)
	if event.is_action_pressed("restart"):
		return  # let the global restart handle it
	get_viewport().set_input_as_handled()


func end_game(result: int) -> void:
	if phase != "play":
		return
	_result = result
	phase = "result"
	_timer = RESULT_TIME


# --- Hooks for subclasses -------------------------------------------------

func _game_ready() -> void:
	pass


func _game_start() -> void:
	pass


func _game_process(_delta: float) -> void:
	pass


func _game_input(_event: InputEvent) -> void:
	pass


func _game_draw(_area: Rect2) -> void:
	pass


# --- Layout and drawing helpers ------------------------------------------

func panel_rect() -> Rect2:
	var vp := get_viewport_rect().size
	return Rect2((vp - PANEL_SIZE) / 2.0, PANEL_SIZE)


## The area inside the panel where the mini-game draws itself.
func play_rect() -> Rect2:
	var r := panel_rect()
	return Rect2(r.position + Vector2(30, 70), r.size - Vector2(60, 100))


func center_text(y: float, text: String, size: int, color: Color) -> void:
	var r := panel_rect()
	draw_string(font, Vector2(r.position.x, y), text, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, size, color)


func _draw() -> void:
	var vp := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.72))
	var r := panel_rect()
	draw_rect(r, Color(0.04, 0.03, 0.08))
	draw_rect(r, accent, false, 3.0)
	draw_rect(r.grow(-7.0), accent.darkened(0.6), false, 1.0)
	center_text(r.position.y + 46.0, title, 30, accent)

	var area := play_rect()
	_game_draw(area)

	if phase == "intro":
		draw_rect(area, Color(0, 0, 0, 0.8))
		center_text(area.get_center().y - 12.0, instructions, 20, Color.WHITE)
		center_text(area.get_center().y + 34.0, "GET READY  %d" % ceili(_timer), 24, accent)
	elif phase == "result":
		draw_rect(area, Color(0, 0, 0, 0.75))
		var text := ""
		var color := Color.WHITE
		match _result:
			Result.WIN:
				text = "CLEAN WIN  ·  PURE ITEM"
				color = Color(0.5, 1.0, 0.6)
			Result.NEAR:
				text = "NEAR MISS  ·  CRACKED ITEM"
				color = Color(1.0, 0.85, 0.35)
			_:
				text = "FAILED  ·  CONTAINMENT CRACKS"
				color = Color(1.0, 0.3, 0.35)
		center_text(area.get_center().y + 10.0, text, 28, color)
