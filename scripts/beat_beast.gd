class_name BeatBeast
extends Beast
## Beat Beast: the old-school street wolf caged in BEAT KEEPER.
##   - At range he aims his boom box and blasts a fan of sound waves.
##   - Up close he drops into a windmill spin and slides at you,
##     then holds a freeze pose: that's your opening (double damage).
##   - Sometimes he moonwalks right out of a punch.
## While he's loose he owns the music (he joins the "music_takeover" group).
## Art: assets/sprites/beasts/beat_beast.png (see tools/make_beat_beast.py for the grid).

const SHEET_PATH := "res://assets/sprites/beasts/beat_beast.png"
const FRAME := 48
## name: [row, first column, frame count, fps, loops]. Must match tools/make_beat_beast.py.
const ANIMATIONS := {
	"idle": [0, 0, 2, 3.0, true],
	"walk": [1, 0, 4, 8.0, true],
	"blast": [2, 0, 3, 6.0, false],
	"windmill": [3, 0, 4, 14.0, true],
	"moonwalk": [4, 0, 4, 10.0, true],
	"freeze": [5, 0, 1, 1.0, false],
	"hurt": [5, 1, 1, 1.0, false],
	"defeated": [5, 2, 1, 1.0, false],
}

@export var blast_range := 320.0
@export var windmill_range := 150.0
@export var wave_speed := 200.0
@export var waves_per_blast := 5
@export_range(0.0, 1.0) var moonwalk_chance := 0.3
@export var moonwalk_cooldown := 3.0
@export var freeze_damage_multiplier := 2.0
## Where his sound waves stop. The floor sets this to the room.
@export var room_bounds := Rect2(40, 40, 1200, 660)

var state := "approach"  # approach, blast, windmill, freeze, moonwalk

var _state_t := 0.0
var _attack_cd := 1.2
var _moon_cd := 0.0
var _hurt_t := 0.0
var _fired := false
var _move_dir := Vector2.ZERO
var _sprite: AnimatedSprite2D


func _ready() -> void:
	super._ready()
	add_to_group("music_takeover")
	_build_sprite()


func _physics_process(delta: float) -> void:
	_flash = maxf(_flash - delta, 0.0)
	_hurt_t = maxf(_hurt_t - delta, 0.0)
	_moon_cd = maxf(_moon_cd - delta, 0.0)
	_phase += delta * 5.0
	queue_redraw()
	if _spawn_t > 0.0:
		_spawn_t -= delta
		_animate()
		return
	if dead or player == null:
		return

	var to := player.global_position - global_position
	var dist := to.length()
	var dir := to / dist if dist > 0.01 else Vector2.ZERO
	_state_t -= delta
	var move := Vector2.ZERO

	match state:
		"approach":
			_attack_cd -= delta
			if dist > 60.0:
				move = dir * speed
			if _attack_cd <= 0.0 and not player.dead:
				if dist < windmill_range:
					_move_dir = dir
					_enter("windmill", 1.2)
				elif dist < blast_range:
					_fired = false
					_enter("blast", 0.9)
			if dist < hit_radius + player.radius + 2.0:
				player.take_damage(contact_damage)
		"blast":
			if not _fired and _state_t <= 0.45:  # half a second of wind-up, then the drop
				_fired = true
				_fire_waves(dir)
			if _state_t <= 0.0:
				_attack_cd = randf_range(1.2, 2.0)
				_enter("approach", 0.0)
		"windmill":
			_move_dir = _move_dir.lerp(dir, 2.0 * delta).normalized()
			move = _move_dir * speed * 2.3
			if dist < hit_radius + 16.0 + player.radius:
				player.take_damage(contact_damage)
			if _state_t <= 0.0:
				_enter("freeze", 0.9)
		"freeze":
			if _state_t <= 0.0:
				_attack_cd = randf_range(1.0, 1.8)
				_enter("approach", 0.0)
		"moonwalk":
			move = _move_dir * speed * 2.0
			if _state_t <= 0.0:
				_attack_cd = 0.4  # glides back in swinging
				_enter("approach", 0.0)

	velocity = move + _knockback
	_knockback = _knockback.move_toward(Vector2.ZERO, 1100.0 * delta)
	move_and_slide()
	_animate()


func take_hit(damage: float, direction: Vector2) -> void:
	if dead or _spawn_t > 0.0 or state == "moonwalk":
		return
	if (state == "approach" or state == "blast") and _moon_cd <= 0.0 and randf() < moonwalk_chance:
		_moon_cd = moonwalk_cooldown
		_move_dir = direction  # slides away along the punch
		_enter("moonwalk", 0.55)
		return
	_hurt_t = 0.15
	var multiplier := freeze_damage_multiplier if state == "freeze" else 1.0
	super.take_hit(damage * multiplier, direction)


func _enter(new_state: String, duration: float) -> void:
	state = new_state
	_state_t = duration
	if _sprite != null and ANIMATIONS.has(new_state):
		_sprite.play(new_state)


func _fire_waves(dir: Vector2) -> void:
	var spread := 0.5
	for i in waves_per_blast:
		var t := 0.0 if waves_per_blast == 1 else float(i) / float(waves_per_blast - 1) - 0.5
		var shot := BossProjectile.new()
		shot.style = "wave"
		shot.color = Color(1.0, 0.35, 0.8)
		shot.radius = 9.0
		var d := dir.rotated(t * spread * 2.0)
		shot.position = position + d * (hit_radius + 6.0) + Vector2(0, -12)
		shot.velocity = d * wave_speed
		shot.bounds = room_bounds
		shot.player = player
		get_parent().add_child(shot)


# --- Animation ---------------------------------------------------------------

func _build_sprite() -> void:
	if not ResourceLoader.exists(SHEET_PATH):
		return
	var sheet: Texture2D = load(SHEET_PATH)
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for anim: String in ANIMATIONS:
		var spec: Array = ANIMATIONS[anim]
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
	_sprite.position = Vector2(0, -10)
	add_child(_sprite)
	_sprite.play("idle")


func _animate() -> void:
	if _sprite == null:
		return
	if player != null:
		_sprite.flip_h = player.global_position.x < global_position.x
	var anim := state
	if state == "approach":
		anim = "walk" if velocity.length() > 10.0 else "idle"
	if _hurt_t > 0.0:
		anim = "hurt"
	if _sprite.animation != anim:
		_sprite.play(anim)
	var c := Color(2.5, 2.5, 2.5) if _flash > 0.0 else Color.WHITE
	if _spawn_t > 0.0:
		c.a = 1.0 - _spawn_t / 0.6
	_sprite.modulate = c


func _draw() -> void:
	if _sprite == null:
		super._draw()
		return
	draw_circle(Vector2(0, 12), 15.0, Color(0, 0, 0, 0.3))
	if _spawn_t > 0.0:
		var t := 1.0 - _spawn_t / 0.6
		draw_arc(Vector2(0, -8), 12.0 + 24.0 * t, 0, TAU, 28, Color(1, 0.35, 0.8, 0.9), 3.0)
	# Music notes float off him while he owns the aux
	var note := Color(1, 0.45, 0.85, 0.85)
	for i in 2:
		var p := Vector2(-16.0 + float(i) * 32.0, -40.0 + sin(_phase * 0.6 + float(i) * PI) * 3.0)
		draw_circle(p, 2.5, note)
		draw_line(p + Vector2(2, 0), p + Vector2(2, -8), note, 1.5)
		draw_line(p + Vector2(2, -8), p + Vector2(5, -6), note, 1.5)
	# Freeze: a pulsing ring says "hit me now"
	if state == "freeze":
		draw_arc(Vector2(0, -8), 26.0 + sin(_phase * 3.0) * 2.0, 0, TAU, 28, Color(1, 0.9, 0.3, 0.8), 2.0)
