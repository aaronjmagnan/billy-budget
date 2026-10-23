@tool
class_name Cabinet
extends StaticBody2D
## An arcade cabinet with a beast trapped inside. Play its mini-game to distill an item.
## Every exported value shows up in Godot's Inspector, so you can retune cabinets there.
## Placeholder art is drawn in _draw() and also shows in the editor (this is a @tool script).

enum State { IDLE, DONE, BREACHED }

@export var cabinet_name := "BEAT KEEPER":
	set(value):
		cabinet_name = value
		queue_redraw()
@export_enum("rhythm", "memory", "timing", "dodge") var game_type := "rhythm"
@export var neon_color := Color(1.0, 0.25, 0.75):
	set(value):
		neon_color = value
		queue_redraw()
## How many losses the cabinet survives before the beast escapes.
@export_range(1, 5) var max_containment := 3:
	set(value):
		max_containment = value
		containment = value
		queue_redraw()
## Which of the boss's four facets this cabinet's item counters (0 to 3).
@export_range(0, 3) var facet_index := 0
@export var item_name := "Boom Box"
## Which beast breaks out when containment fails. "generic" is the placeholder blob.
@export_enum("generic", "beat_beast") var beast_kind := "generic"

const SIZE := Vector2(64, 104)

var state := State.IDLE
var containment := 3
var _glow_t := 0.0


func _ready() -> void:
	containment = max_containment


func _process(delta: float) -> void:
	_glow_t += delta
	queue_redraw()


func cracks() -> int:
	return max_containment - containment


func is_playable() -> bool:
	return state == State.IDLE


## Called when a mini-game is lost. Returns true if the beast broke free.
func crack() -> bool:
	containment = maxi(containment - 1, 0)
	return containment <= 0


func interact_point() -> Vector2:
	return global_position + Vector2(0, 14)


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var w := SIZE.x
	var h := SIZE.y
	var body := Rect2(-w / 2.0, -h, w, h)
	var outline := neon_color
	match state:
		State.DONE:
			outline = neon_color.darkened(0.65)
		State.BREACHED:
			outline = Color(1.0, 0.2, 0.25)

	# Shadow, body, outline
	draw_rect(Rect2(-w / 2.0 - 4.0, -6.0, w + 8.0, 12.0), Color(0, 0, 0, 0.35))
	draw_rect(body, Color(0.07, 0.06, 0.12))
	draw_rect(body, outline, false, 2.0)
	# Marquee strip
	draw_rect(Rect2(-w / 2.0 + 4.0, -h + 4.0, w - 8.0, 14.0), outline.darkened(0.25))

	# Screen
	var screen := Rect2(-w / 2.0 + 8.0, -h + 24.0, w - 16.0, 40.0)
	match state:
		State.IDLE:
			var flick := 0.5 + 0.12 * sin(_glow_t * 7.0 + float(facet_index) * 1.7)
			draw_rect(screen, neon_color.darkened(1.0 - flick))
			# Something moves behind the glass
			var eye_x := sin(_glow_t * 1.3 + float(facet_index)) * 12.0
			draw_circle(screen.get_center() + Vector2(eye_x, 0), 4.0, Color(0, 0, 0, 0.55))
			# Cracks from earlier losses
			for i in cracks():
				var cx := screen.position.x + 8.0 + float(i) * 12.0
				draw_line(Vector2(cx, screen.position.y), Vector2(cx + 6.0, screen.end.y), Color(1, 0.2, 0.25), 1.5)
		State.DONE:
			draw_rect(screen, Color(0.12, 0.12, 0.14))
		State.BREACHED:
			draw_rect(screen, Color(0.02, 0.0, 0.0))
			var pts := PackedVector2Array([
				screen.position, screen.get_center() + Vector2(-4, -3), screen.get_center() + Vector2(5, 4), screen.end,
			])
			draw_polyline(pts, Color(1, 0.2, 0.25), 2.0)

	# Control panel
	draw_circle(Vector2(-10, -h + 80.0), 4.5, outline)
	draw_circle(Vector2(8, -h + 80.0), 3.5, outline.darkened(0.3))
	draw_circle(Vector2(18, -h + 80.0), 3.5, outline.darkened(0.3))

	# Name above the cabinet
	var label := cabinet_name if state != State.DONE else cabinet_name + " (EMPTY)"
	draw_string(font, Vector2(-80, -h - 10.0), label, HORIZONTAL_ALIGNMENT_CENTER, 160, 13, outline)

	# Containment gauge: one pip per loss the cabinet can absorb
	var pip_w := 10.0
	var total_w := float(max_containment) * (pip_w + 4.0) - 4.0
	for i in max_containment:
		var r := Rect2(-total_w / 2.0 + float(i) * (pip_w + 4.0), 10.0, pip_w, 6.0)
		if i < containment and state != State.BREACHED:
			draw_rect(r, neon_color if state == State.IDLE else neon_color.darkened(0.65))
		else:
			draw_rect(r, Color(1, 0.2, 0.25), false, 1.0)
