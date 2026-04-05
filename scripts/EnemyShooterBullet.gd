extends CharacterBody2D
## Bullet fired by shooter enemies.

@export var speed: float = 200.0
@export var damage: float = 15.0
@export var lifetime: float = 4.0

var _direction: Vector2 = Vector2.RIGHT
var _lifetime_timer: float = 0.0
var _hit: bool = false
var _owner_shooter: Node = null
var _spawn_pos: Vector2 = Vector2.ZERO  # Track where we spawned
var _frame_count: int = 0

func _ready() -> void:
	# Disable shape for 2 frames to avoid self-hit on spawn
	var shape := $CollisionShape2D as CollisionShape2D
	shape.set_deferred("disabled", true)
	await get_tree().physics_frame
	await get_tree().physics_frame
	shape.set_deferred("disabled", false)

func setup(dir: Vector2, shooter: Node = null) -> void:
	_direction = dir.normalized()
	rotation = dir.angle()
	_owner_shooter = shooter
	_spawn_pos = global_position
	velocity = _direction * speed

func _physics_process(delta: float) -> void:
	_frame_count += 1
	if _hit:
		return
	_lifetime_timer += delta
	if _lifetime_timer >= lifetime:
		queue_free()
		return

	velocity = _direction * speed
	var motion := velocity * delta

	# Pure checkpoint-based collision: move first, then check if the path crosses a tree.
	# intersect_point hits ANY body regardless of mask, so skip shooter explicitly.
	global_position += motion

	# Player hit check via proximity
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("take_damage"):
		if global_position.distance_to(player.global_position) < 12.0:
			player.take_damage(damage)
			queue_free()
			return

	# Tree collision via intersect_point — not masked by collision_mask
	var space := get_world_2d().direct_space_state
	var qp := PhysicsPointQueryParameters2D.new()
	qp.position = global_position
	qp.collision_mask = 8
	qp.collide_with_bodies = true
	qp.collide_with_areas = false
	var hit := space.intersect_point(qp, 1)
	if hit.size() > 0 and hit[0].collider != _owner_shooter and hit[0].collider.is_in_group("tree"):
		print("[Bullet] frame=", _frame_count, " tree hit at ", global_position)
		queue_free()
		return

func _draw() -> void:
	draw_circle(Vector2.ZERO, 5.0, Color(1.0, 0.2, 0.2, 1.0))
	draw_circle(Vector2.ZERO, 2.5, Color(1.0, 0.6, 0.6, 1.0))
