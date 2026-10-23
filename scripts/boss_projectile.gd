class_name BossProjectile
extends Node2D
## A single shot from the floor boss. Despawns when it leaves the arena.

var velocity := Vector2.ZERO
var radius := 7.0
var color := Color(1.0, 0.3, 0.45)
var bounds := Rect2()
var player: Player = null
var life := 6.0
## "orb" (boss shots) or "wave" (Beat Beast's sound waves, drawn as arcs that widen).
var style := "orb"


func _physics_process(delta: float) -> void:
	position += velocity * delta
	if style == "wave":
		radius = minf(radius + 8.0 * delta, 16.0)
	life -= delta
	if life <= 0.0 or not bounds.has_point(global_position):
		queue_free()
		return
	if player != null and not player.dead:
		if global_position.distance_to(player.global_position) < radius + player.radius:
			player.take_damage(1)
			queue_free()
			return
	queue_redraw()


func _draw() -> void:
	if style == "wave":
		var a := velocity.angle()
		draw_arc(Vector2.ZERO, radius, a - 0.9, a + 0.9, 12, color, 3.0)
		draw_arc(Vector2.ZERO, radius * 0.6, a - 0.8, a + 0.8, 10, Color(1, 1, 1, 0.8), 2.0)
		return
	draw_circle(Vector2.ZERO, radius, color)
	draw_circle(Vector2.ZERO, radius * 0.45, Color(1, 1, 1, 0.9))
