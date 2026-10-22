class_name Player
extends CharacterBody2D
## The kid. Moves, dashes (brief invulnerability), and strikes in the facing direction.
## Placeholder visuals are drawn in _draw(); swap in a sprite later without changing the logic.

signal hearts_changed
signal died

@export var move_speed := 230.0
@export var dash_speed_multiplier := 3.2
@export var dash_time := 0.16
@export var dash_cooldown := 0.6
@export var strike_cooldown := 0.35
@export var strike_range := 58.0
@export var invulnerable_time := 0.9

var max_hearts := 6
var hearts := 6
var strike_damage := 1
var facing := Vector2.DOWN
var radius := 12.0
var dead := false

var _dash_t := 0.0
var _dash_cd := 0.0
var _strike_cd := 0.0
var _swing_t := 0.0
var _invuln_t := 0.0


func _physics_process(delta: float) -> void:
	_dash_t = maxf(_dash_t - delta, 0.0)
	_dash_cd = maxf(_dash_cd - delta, 0.0)
	_strike_cd = maxf(_strike_cd - delta, 0.0)
	_swing_t = maxf(_swing_t - delta, 0.0)
	_invuln_t = maxf(_invuln_t - delta, 0.0)
	queue_redraw()
	if dead:
		velocity = Vector2.ZERO
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


func is_dashing() -> bool:
	return _dash_t > 0.0


func _strike() -> void:
	_strike_cd = strike_cooldown
	_swing_t = 0.14
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


func _draw() -> void:
	var blink := _invuln_t > 0.0 and int(_invuln_t * 20.0) % 2 == 0
	var body_color := Color(1.0, 0.82, 0.55) if not dead else Color(0.35, 0.3, 0.3)
	if blink:
		body_color.a = 0.35
	# Shadow
	draw_circle(Vector2(0, 10), 11.0, Color(0, 0, 0, 0.35))
	# Dash trail
	if is_dashing():
		draw_circle(-facing * 14.0, radius * 0.8, Color(1, 0.82, 0.55, 0.25))
	# Body (hoodie) and head
	draw_circle(Vector2(0, 2), radius, Color(0.25, 0.45, 0.95, body_color.a))
	draw_circle(Vector2(0, -8), 8.0, body_color)
	# Eyes look where the kid faces
	var eye_offset := facing * 3.0
	draw_circle(Vector2(-3, -9) + eye_offset, 1.6, Color(0.1, 0.1, 0.15, body_color.a))
	draw_circle(Vector2(3, -9) + eye_offset, 1.6, Color(0.1, 0.1, 0.15, body_color.a))
	# Strike swing
	if _swing_t > 0.0:
		var a := facing.angle()
		var alpha := _swing_t / 0.14
		draw_arc(Vector2.ZERO, strike_range * 0.75, a - 0.9, a + 0.9, 16, Color(1, 1, 1, alpha), 5.0)
