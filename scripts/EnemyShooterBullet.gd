extends Area2D
## Bullet fired by shooter enemies.

@export var speed: float = 200.0
@export var damage: float = 15.0
@export var lifetime: float = 4.0

var _direction: Vector2 = Vector2.RIGHT
var _lifetime_timer: float = 0.0
var _hit: bool = false
var _owner_shooter: Node = null  # The enemy that fired this bullet

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func setup(dir: Vector2, shooter: Node = null) -> void:
	_direction = dir.normalized()
	rotation = dir.angle()
	_owner_shooter = shooter

func _physics_process(delta: float) -> void:
	if _hit:
		return
	_lifetime_timer += delta
	if _lifetime_timer >= lifetime:
		queue_free()
		return
	
	var total_movement := _direction * speed * delta
	var steps := maxi(1, int(ceil(total_movement.length() / 2.0)))
	var step_vec := total_movement / float(steps)
	for s in range(steps):
		position += step_vec
		# Tree collision check — bullet only damages trees, not enemies
		var space := get_world_2d().direct_space_state
		var params := PhysicsShapeQueryParameters2D.new()
		params.collision_mask = 8  # Layer 8 = trees + player
		params.collide_with_bodies = true
		params.collide_with_areas = false
		var shape := CircleShape2D.new()
		shape.radius = 5.0
		params.shape = shape
		params.transform = Transform2D(0, position)
		var hits = space.intersect_shape(params, 1)
		if hits.size() > 0:
			var hit_body = hits[0].collider
			# Ignore the shooter that fired this bullet (it occupies layer 8)
			if hit_body == _owner_shooter:
				continue
			# Destroy on trees
			if hit_body.is_in_group("tree"):
				queue_free()
				return

func _on_body_entered(body: Node) -> void:
	if _hit:
		return
	_hit = true
	# Don't hit the shooter that fired this
	if body == _owner_shooter:
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 5.0, Color(1.0, 0.2, 0.2, 1.0))
	draw_circle(Vector2.ZERO, 2.5, Color(1.0, 0.6, 0.6, 1.0))
