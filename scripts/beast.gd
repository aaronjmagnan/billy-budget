class_name Beast
extends CharacterBody2D
## Anything that crawled out of a screen. Roaming wisps wander until you get close;
## escaped beasts burst out of a cabinet and hunt you immediately.

signal defeated(beast: Beast)

@export var max_hp := 3.0
@export var speed := 90.0
@export var color := Color(0.6, 0.45, 0.95)
@export var hit_radius := 14.0
@export var contact_damage := 1
@export var aggro_range := 280.0
@export var always_hunting := false

## The cabinet this beast escaped from, if any. Beating it grants that cabinet's raw item.
var escaped_from: Cabinet = null
var player: Player = null

var hp := 3.0
var dead := false
var _knockback := Vector2.ZERO
var _flash := 0.0
var _spawn_t := 0.0
var _wander_dir := Vector2.ZERO
var _wander_t := 0.0
var _phase := randf() * TAU


func _ready() -> void:
	hp = max_hp
	add_to_group("hittable")
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1
	var shape := CircleShape2D.new()
	shape.radius = hit_radius * 0.8
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)
	if escaped_from != null:
		_spawn_t = 0.6  # telegraph: the beast tears free before it moves


func _physics_process(delta: float) -> void:
	_flash = maxf(_flash - delta, 0.0)
	_phase += delta * 5.0
	queue_redraw()
	if _spawn_t > 0.0:
		_spawn_t -= delta
		return
	if dead:
		return

	var dir := Vector2.ZERO
	if player != null and not player.dead:
		var to := player.global_position - global_position
		if always_hunting or to.length() < aggro_range:
			dir = to.normalized()
			if to.length() < hit_radius + player.radius + 2.0:
				player.take_damage(contact_damage)
	if dir == Vector2.ZERO:
		_wander_t -= delta
		if _wander_t <= 0.0:
			_wander_t = randf_range(0.8, 2.0)
			_wander_dir = Vector2.from_angle(randf() * TAU) if randf() < 0.7 else Vector2.ZERO
		dir = _wander_dir * 0.5

	velocity = dir * speed + _knockback
	_knockback = _knockback.move_toward(Vector2.ZERO, 1100.0 * delta)
	move_and_slide()


func take_hit(damage: float, direction: Vector2) -> void:
	if dead or _spawn_t > 0.0:
		return
	hp -= damage
	_flash = 0.1
	_knockback = direction * 340.0
	if hp <= 0.0:
		dead = true
		remove_from_group("hittable")
		remove_from_group("enemies")
		defeated.emit(self)
		queue_free()


func _draw() -> void:
	var r := hit_radius
	var c := Color.WHITE if _flash > 0.0 else color
	if _spawn_t > 0.0:
		# Tearing free: a pulsing ring that grows into the beast
		var t := 1.0 - _spawn_t / 0.6
		draw_arc(Vector2.ZERO, r * (0.4 + t), 0, TAU, 24, Color(1, 0.2, 0.3, 0.9), 3.0)
		c.a = t
	draw_circle(Vector2(0, r * 0.7), r * 0.8, Color(0, 0, 0, 0.3))
	# Jagged glitchy body
	var pts := PackedVector2Array()
	var spikes := 9
	for i in spikes * 2:
		var a := TAU * float(i) / float(spikes * 2)
		var rr := r if i % 2 == 0 else r * (0.62 + 0.12 * sin(_phase + i))
		pts.append(Vector2.from_angle(a) * rr)
	draw_colored_polygon(pts, c)
	# Eyes that track the kid
	var look := Vector2.ZERO
	if player != null:
		look = (player.global_position - global_position).normalized() * 2.5
	draw_circle(Vector2(-r * 0.3, -r * 0.15) + look, r * 0.16, Color(0.05, 0.02, 0.05))
	draw_circle(Vector2(r * 0.3, -r * 0.15) + look, r * 0.16, Color(0.05, 0.02, 0.05))
