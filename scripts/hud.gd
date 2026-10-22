extends Control
## On-screen info: hearts, items, prompts, messages, boss health, and end screens.

var level: Node = null  # set by floor_level.gd
var font: Font


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	font = ThemeDB.fallback_font


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if level == null:
		return
	var vp := get_viewport_rect().size
	var p: Player = level.player

	# Hearts, top left
	for i in p.max_hearts:
		var c := Vector2(58.0 + float(i) * 28.0, 20.0)
		_draw_heart(c, Color(1, 0.3, 0.4) if i < p.hearts else Color(0.25, 0.2, 0.3))
	if p.strike_damage != 1.0:
		draw_string(font, Vector2(58.0 + float(p.max_hearts) * 28.0, 26.0), "STRIKE x%s" % str(snappedf(p.strike_damage, 0.1)), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 0.8, 0.4))

	# Items, top right
	var x := vp.x - 48.0
	for i in range(level.items.size() - 1, -1, -1):
		var item: Dictionary = level.items[i]
		var tag := "%s (%s)" % [item["name"], String(item["kind"]).to_upper()]
		var w := font.get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 26.0
		x -= w
		var r := Rect2(x, 8.0, w - 6.0, 24.0)
		var c: Color = item["color"]
		draw_rect(r, c.darkened(0.7))
		draw_rect(r, c, false, 1.0)
		draw_string(font, r.position + Vector2(10, 17), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, c.lightened(0.3))
	if level.items.is_empty():
		draw_string(font, Vector2(vp.x - 260.0, 26.0), "No items yet", HORIZONTAL_ALIGNMENT_RIGHT, 212, 14, Color(0.6, 0.55, 0.7))

	# Boss health bar
	var boss: Boss = level.boss
	if boss != null and (boss.active or boss.dead):
		var bar := Rect2(vp.x / 2.0 - 220.0, 64.0, 440.0, 10.0)
		draw_rect(bar, Color(0.15, 0.05, 0.08))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * boss.hp / boss.max_hp, bar.size.y)), Color(1, 0.3, 0.45))
		var shield := "SHIELD %d%%" % int(round((1.0 - boss.damage_multiplier()) * 100.0))
		draw_string(font, Vector2(bar.position.x, bar.end.y + 16.0), "FLOOR GUARDIAN   ·   " + shield, HORIZONTAL_ALIGNMENT_CENTER, bar.size.x, 13, Color(1, 0.6, 0.7))

	# Message, top center
	if level.message_t > 0.0 and level.message != "":
		var alpha := clampf(level.message_t, 0.0, 1.0)
		draw_string(font, Vector2(0, 26.0), level.message, HORIZONTAL_ALIGNMENT_CENTER, vp.x, 16, Color(1, 1, 1, alpha))

	# Interaction prompt, bottom center
	if level.prompt != "":
		var pw := font.get_string_size(level.prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + 30.0
		var pr := Rect2((vp.x - pw) / 2.0, 646.0, pw, 28.0)
		draw_rect(pr, Color(0, 0, 0, 0.7))
		draw_string(font, Vector2(0, 666.0), level.prompt, HORIZONTAL_ALIGNMENT_CENTER, vp.x, 16, Color(1, 1, 0.85))

	# Controls reminder
	draw_string(font, Vector2(0, 714.0), "WASD move   ·   J / Space strike   ·   K / Shift dash   ·   E use   ·   R restart", HORIZONTAL_ALIGNMENT_CENTER, vp.x, 12, Color(0.55, 0.5, 0.65))

	# End screens
	if level.state == "won" or level.state == "lost":
		draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.65))
		var won: bool = level.state == "won"
		var title := "FLOOR CLEARED" if won else "THE ARCADE KEEPS YOU"
		var sub := "The guardian falls silent. The stairs down are open... (next floor coming in stage 4)" if won else "Press R to sneak back in."
		draw_string(font, Vector2(0, vp.y / 2.0 - 10.0), title, HORIZONTAL_ALIGNMENT_CENTER, vp.x, 44, Color(0.5, 1, 0.6) if won else Color(1, 0.35, 0.45))
		draw_string(font, Vector2(0, vp.y / 2.0 + 34.0), sub, HORIZONTAL_ALIGNMENT_CENTER, vp.x, 18, Color(0.9, 0.9, 1))
		if won:
			draw_string(font, Vector2(0, vp.y / 2.0 + 64.0), "Press R to play again.", HORIZONTAL_ALIGNMENT_CENTER, vp.x, 16, Color(0.7, 0.7, 0.8))


func _draw_heart(center: Vector2, color: Color) -> void:
	draw_circle(center + Vector2(-5, -3), 6.0, color)
	draw_circle(center + Vector2(5, -3), 6.0, color)
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-11, -1), center + Vector2(11, -1), center + Vector2(0, 11),
	]), color)
