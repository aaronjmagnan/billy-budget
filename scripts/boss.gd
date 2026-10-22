class_name Boss
extends Node2D
## The floor boss: the oldest beast on the floor. It has four facets, one per cabinet.
## Each item you bring from a cabinet strips (or weakens) the matching facet.
## Intact facets shield the boss and make its attacks denser.

signal defeated

@export var max_hp := 16.0

## 1.0 = facet intact, 0.5 = weakened by a cracked item, 0.0 = stripped.
var facet_strength: Array[float] = [1.0, 1.0, 1.0, 1.0]
var facet_colors: Array[Color] = [Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE]
var hp := 16.0
var active := false
var dead := false
var hit_radius := 38.0
var player: Player = null
var arena := Rect2()

var _attack_t := 2.0
var _telegraph := 0.0
var _flash := 0.0
var _spin := 0.0


func _ready() -> void:
	hp = max_hp
	add_to_group("hittable")


func intact_total() -> float:
	var total := 0.0
	for s in facet_strength:
		total += s
	return total


## Fraction of strike damage that gets through. 4 intact facets: almost nothing. 0: everything.
func damage_multiplier() -> float:
	return clampf(1.0 - 0.22 * intact_total(), 0.12, 1.0)


func weaken_facet(index: int, amount: float) -> void:
	if index < 0 or index >= facet_strength.size():
		return
	facet_strength[index] = maxf(facet_strength[index] - amount, 0.0)
	queue_redraw()


func activate() -> void:
	active = true
	_attack_t = 1.4


func take_hit(damage: float, _direction: Vector2) -> void:
	if not active or dead:
		return
	hp -= damage * damage_multiplier()
	_flash = 0.12
	if hp <= 0.0:
		hp = 0.0
		dead = true
		active = false
		defeated.emit()


func _physics_process(delta: float) -> void:
	_spin += delta * (0.4 + 0.3 * intact_total())
	_flash = maxf(_flash - delta, 0.0)
	queue_redraw()
	if not active or player == null or player.dead:
		return

	var to := player.global_position - global_position
	if to.length() > 90.0:
		position += to.normalized() * 38.0 * delta
	position = position.clamp(arena.position + Vector2(50, 50), arena.end - Vector2(50, 50))
	if to.length() < hit_radius + player.radius:
		player.take_damage(1)

	if _telegraph > 0.0:
		_telegraph -= delta
		if _telegraph <= 0.0:
			_fire()
	else:
		_attack_t -= delta
		if _attack_t <= 0.0:
			_telegraph = 0.55
			_attack_t = 2.3 - 0.15 * intact_total()


func _fire() -> void:
	var t := intact_total()
	var count := 8 + int(round(t * 3.0))
	var speed := 160.0 + 25.0 * t
	var offset := randf() * TAU
	for i in count:
		_spawn_shot(offset + TAU * float(i) / float(count), speed)
	if t >= 2.5:
		# Heavily shielded bosses fire a slower second ring between the gaps.
		for i in count:
			_spawn_shot(offset + TAU * (float(i) + 0.5) / float(count), speed * 0.65)


func _spawn_shot(angle: float, speed: float) -> void:
	var shot := BossProjectile.new()
	shot.position = position + Vector2.from_angle(angle) * hit_radius
	shot.velocity = Vector2.from_angle(angle) * speed
	shot.bounds = arena
	shot.player = player
	get_parent().add_child(shot)


func _draw() -> void:
	var core := Color(0.22, 0.08, 0.3)
	if _flash > 0.0:
		core = Color.WHITE
	elif not active and not dead:
		core = Color(0.14, 0.07, 0.18)
	if dead:
		core = Color(0.1, 0.1, 0.1)
	draw_circle(Vector2(0, 30), 34.0, Color(0, 0, 0, 0.35))
	draw_circle(Vector2.ZERO, 30.0, core)
	draw_arc(Vector2.ZERO, 30.0, 0, TAU, 32, Color(1, 0.3, 0.45, 0.6), 2.0)

	# Four facets orbit the core, colored by the cabinet whose item counters them.
	if not dead:
		for i in 4:
			var s := facet_strength[i]
			if s <= 0.0:
				continue
			var start := _spin + float(i) * PI / 2.0 + 0.12
			var finish := start + PI / 2.0 - 0.24
			var c := facet_colors[i]
			c.a = 0.35 + 0.65 * s
			draw_arc(Vector2.ZERO, hit_radius + 8.0, start, finish, 16, c, 3.0 + 7.0 * s)

	# Eye
	if dead:
		draw_line(Vector2(-10, -4), Vector2(10, 4), Color(0.5, 0.5, 0.5), 3.0)
		draw_line(Vector2(-10, 4), Vector2(10, -4), Color(0.5, 0.5, 0.5), 3.0)
	elif not active:
		draw_line(Vector2(-11, 0), Vector2(11, 0), Color(1, 0.3, 0.45, 0.7), 3.0)
	else:
		var look := Vector2.ZERO
		if player != null:
			look = (player.global_position - global_position).normalized() * 6.0
		draw_circle(Vector2.ZERO, 11.0, Color(1, 0.9, 0.9))
		draw_circle(look, 5.0, Color(0.6, 0.05, 0.15))

	# Telegraph before each volley
	if _telegraph > 0.0:
		var t := 1.0 - _telegraph / 0.55
		draw_arc(Vector2.ZERO, hit_radius + 14.0 + 30.0 * t, 0, TAU, 40, Color(1, 1, 1, 1.0 - t), 3.0)
