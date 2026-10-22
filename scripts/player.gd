class_name Player
extends CharacterBody2D
## Bud. Laid back until a beast shows up, then a boxer.
## Moves, dashes (a ducking slip with brief invulnerability), and jabs in the facing direction.
## Art comes from assets/sprites/characters/bud/bud_<outfit>.png (see tools/make_bud.py for the grid).
## If that file is missing, a simple placeholder is drawn instead.

signal hearts_changed
signal died

@export_enum("white", "gray", "black") var outfit := "white"
@export var move_speed := 230.0
@export var dash_speed_multiplier := 3.2
@export var dash_time := 0.16
@export var dash_cooldown := 0.6
@export var strike_cooldown := 0.35
@export var strike_range := 58.0
@export var invulnerable_time := 0.9
## Bud drops into his boxing guard when a beast is this close.
@export var guard_range := 230.0

const SHEET_PATH := "res://assets/sprites/characters/bud/bud_%s.png"
const FRAME := 32
## name: [row, first column, frame count, fps, loops]. Must match tools/make_bud.py.
const BUD_ANIMATIONS := {
	"idle_down": [0, 0, 4, 3.0, true],
	"walk_down": [1, 0, 4, 8.0, true],
	"walk_up": [2, 0, 4, 8.0, true],
	"walk_side": [3, 0, 4, 8.0, true],
	"punch_down": [4, 0, 3, 18.0, false],
	"punch_up": [5, 0, 3, 18.0, false],
	"punch_side": [6, 0, 3, 18.0, false],
	"dash_down": [7, 0, 1, 1.0, false],
	"dash_up": [7, 1, 1, 1.0, false],
	"dash_side": [7, 2, 1, 1.0, false],
	"hurt": [7, 3, 1, 1.0, false],
	"defeated": [8, 0, 1, 1.0, false],
}

var max_hearts := 6
var hearts := 6
## Damage per jab. Can be fractional: items will hit for more or (much) less.
var strike_damage := 1.0
var facing := Vector2.DOWN
var radius := 12.0
var dead := false

var _sprite: AnimatedSprite2D
var _dash_t := 0.0
var _dash_cd := 0.0
var _strike_cd := 0.0
var _swing_t := 0.0
var _punch_t := 0.0
var _invuln_t := 0.0


func _ready() -> void:
	_build_sprite()


func _physics_process(delta: float) -> void:
	_dash_t = maxf(_dash_t - delta, 0.0)
	_dash_cd = maxf(_dash_cd - delta, 0.0)
	_strike_cd = maxf(_strike_cd - delta, 0.0)
	_swing_t = maxf(_swing_t - delta, 0.0)
	_punch_t = maxf(_punch_t - delta, 0.0)
	_invuln_t = maxf(_invuln_t - delta, 0.0)
	queue_redraw()
	if dead:
		velocity = Vector2.ZERO
		_update_animation()
		return

	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input != Vector2.ZERO:
		facing = input.normalized()

	if Input.is_action_just_pressed("dash") and _dash_cd <= 0.0:
		_dash_t = dash_time
		_dash_cd = dash_cooldown

	var dir := input
	if is_dashing() and dir == Vector2.ZERO:
		dir = facing
	var speed := move_speed * (dash_speed_multiplier if is_dashing() else 1.0)
	velocity = dir * speed
	move_and_slide()

	if Input.is_action_just_pressed("strike") and _strike_cd <= 0.0:
		_strike()
	_update_animation()


func is_dashing() -> bool:
	return _dash_t > 0.0


func _strike() -> void:
	_strike_cd = strike_cooldown
	_swing_t = 0.14
	_punch_t = 0.17
	if _sprite != null:
		_sprite.play("punch_" + _dir_name())
	for target in get_tree().get_nodes_in_group("hittable"):
		if not is_instance_valid(target):
			continue
		var to: Vector2 = target.global_position - global_position
		var target_radius: float = target.hit_radius
		var dist := to.length()
		if dist > strike_range + target_radius:
			continue
		var in_front := dist < target_radius + 20.0 or facing.dot(to.normalized()) > 0.3
		if in_front:
			target.take_hit(strike_damage, to.normalized())


func take_damage(amount: int, ignore_invulnerability := false) -> void:
	if dead:
		return
	if not ignore_invulnerability and (_invuln_t > 0.0 or is_dashing()):
		return
	hearts = maxi(hearts - amount, 0)
	_invuln_t = invulnerable_time
	hearts_changed.emit()
	if hearts <= 0:
		dead = true
		died.emit()


func change_max_hearts(delta_hearts: int) -> void:
	max_hearts = maxi(max_hearts + delta_hearts, 2)
	hearts = mini(hearts, max_hearts)
	hearts_changed.emit()


# --- Animation -------------------------------------------------------------

func _build_sprite() -> void:
	var path := SHEET_PATH % outfit
	if not ResourceLoader.exists(path):
		return
	var sheet: Texture2D = load(path)
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for anim: String in BUD_ANIMATIONS:
		var spec: Array = BUD_ANIMATIONS[anim]
		frames.add_animation(anim)
		frames.set_animation_speed(anim, spec[3])
		frames.set_animation_loop(anim, spec[4])
		for i in int(spec[2]):
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2((int(spec[1]) + i) * FRAME, int(spec[0]) * FRAME, FRAME, FRAME)
			frames.add_frame(anim, atlas)
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = frames
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.position = Vector2(0, -4)  # feet sit just below the collision circle's center
	add_child(_sprite)
	_sprite.play("idle_down")


func _dir_name() -> String:
	if absf(facing.x) > absf(facing.y) * 1.1:
		return "side"
	return "down" if facing.y >= 0.0 else "up"


func _threat_nearby() -> bool:
	for e in get_tree().get_nodes_in_group("hittable"):
		if not is_instance_valid(e):
			continue
		if e is Boss and not e.active:
			continue
		if global_position.distance_to(e.global_position) < guard_range:
			return true
	return false


func _show(anim: String, paused_frame := -1) -> void:
	if paused_frame >= 0:
		_sprite.animation = anim
		_sprite.frame = paused_frame
		_sprite.pause()
	elif _sprite.animation != anim or not _sprite.is_playing():
		_sprite.play(anim)


func _update_animation() -> void:
	if _sprite == null:
		return
	var dir := _dir_name()
	_sprite.flip_h = dir == "side" and facing.x < 0.0
	var blink := _invuln_t > 0.0 and not dead and int(_invuln_t * 20.0) % 2 == 0
	_sprite.modulate.a = 0.4 if blink else 1.0

	if dead:
		_sprite.flip_h = false
		_show("defeated", 0)
	elif _invuln_t > invulnerable_time - 0.25:
		_show("hurt", 0)
	elif _punch_t > 0.0:
		pass  # let the jab play out
	elif is_dashing():
		_show("dash_" + dir, 0)
	elif velocity.length() > 5.0:
		_show("walk_" + dir)
	elif _threat_nearby():
		_show("punch_" + dir, 0)  # boxing guard
	elif dir == "down":
		_show("idle_down")
	else:
		_show("walk_" + dir, 0)


func _draw() -> void:
	# Shadow
	draw_circle(Vector2(0, 11), 10.0, Color(0, 0, 0, 0.35))
	if _sprite == null:
		_draw_placeholder()
	# Jab arc
	if _swing_t > 0.0:
		var a := facing.angle()
		var alpha := _swing_t / 0.14
		draw_arc(Vector2.ZERO, strike_range * 0.75, a - 0.9, a + 0.9, 16, Color(1, 1, 1, alpha * 0.8), 4.0)


func _draw_placeholder() -> void:
	var c := Color(1.0, 0.82, 0.55) if not dead else Color(0.35, 0.3, 0.3)
	draw_circle(Vector2(0, 2), radius, Color(0.9, 0.9, 0.95))
	draw_circle(Vector2(0, -8), 8.0, c)
