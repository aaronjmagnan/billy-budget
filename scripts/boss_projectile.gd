class_name BossProjectile
extends Node2D
## A single shot from the floor boss. Despawns when it leaves the arena.

var velocity := Vector2.ZERO
var radius := 7.0
var color := Color(1.0, 0.3, 0.45)
var bounds := Rect2()
var player: Player = null
var life := 6.0


func _physics_process(delta: float) -> void:
	position += velocity * delta
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
	draw_circle(Vector2.ZERO, radius, color)
	draw_circle(Vector2.ZERO, radius * 0.45, Color(1, 1, 1, 0.9))
