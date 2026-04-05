extends CharacterBody2D
## Bullet fired by shooter enemies.

@export var speed: float = 200.0
@export var damage: float = 15.0
@export var lifetime: float = 4.0

var _direction: Vector2 = Vector2.RIGHT
var _lifetime_timer: float = 0.0
var _hit: bool = false
var _owner_shooter: Node = null

func _ready() -> void:
	print("[Bullet] _ready at global_pos=", global_position)
	# Disable shape for 2 frames to avoid self-hit on spawn
	var shape := $CollisionShape2D as CollisionShape2D
	shape.set_deferred("disabled", true)
	await get_tree().physics_frame
	await get_tree().physics_frame
	shape.set_deferred("disabled", false)
	print("[Bullet] shape enabled, global_pos=", global_position)

func setup(dir: Vector2, shooter: Node = null) -> void:
	_direction = dir.normalized()
	rotation = dir.angle()
	_owner_shooter = shooter
	velocity = _direction * speed
	print("[Bullet] setup done, velocity=", velocity, " global_pos=", global_position)

func _physics_process(delta: float) -> void:
	print("[Bullet] _physics_process delta=", delta, " pos=", position, " vel=", velocity)
	if _hit:
		return
	_lifetime_timer += delta
	if _lifetime_timer >= lifetime:
		queue_free()
		return
	
	velocity = _direction * speed
	move_and_slide()
	print("[Bullet] after slide: pos=", position)
	
	# Check if we hit the player
	for i in get_slide_collision_count():
		var collider = get_slide_collision(i).get_collider()
		if collider == _owner_shooter:
			continue
		if collider.has_method("take_damage"):
			_hit = true
			collider.take_damage(damage)
			queue_free()
			return

func _draw() -> void:
	draw_circle(Vector2.ZERO, 5.0, Color(1.0, 0.2, 0.2, 1.0))
	draw_circle(Vector2.ZERO, 2.5, Color(1.0, 0.6, 0.6, 1.0))
