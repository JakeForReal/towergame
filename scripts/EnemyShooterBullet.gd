extends Area2D
## Bullet fired by shooter enemies.

@export var speed: float = 200.0
@export var damage: float = 15.0
@export var lifetime: float = 4.0

var _direction: Vector2 = Vector2.RIGHT
var _lifetime_timer: float = 0.0
var _hit: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func setup(dir: Vector2) -> void:
	_direction = dir.normalized()
	rotation = dir.angle()

func _physics_process(delta: float) -> void:
	if _hit:
		return
	var total_movement := _direction * speed * delta
	_lifetime_timer += delta
	if _lifetime_timer >= lifetime:
		queue_free()
		return
	# Move in small steps — prevents tunneling
	var steps := maxi(1, int(ceil(total_movement.length() / 2.0)))
	var step_vec := total_movement / float(steps)
	for s in range(steps):
		position += step_vec
		# Check for tree collision using shape queries
		var space := get_world_2d().direct_space_state
		var tree_params := PhysicsShapeQueryParameters2D.new()
		tree_params.collision_mask = 8
		tree_params.collide_with_bodies = true
		tree_params.collide_with_areas = false
		var tree_shape := CircleShape2D.new()
		tree_shape.radius = 5.0
		tree_params.shape = tree_shape
		tree_params.transform = Transform2D(0, position)
		var tree_hits = space.intersect_shape(tree_params, 1)
		if tree_hits.size() > 0 and tree_hits[0].collider.is_in_group("tree"):
			queue_free()
			return

func _on_body_entered(body: Node) -> void:
	if _hit:
		return
	print("[Bullet] hit body: ", body.name, " groups=", body.get_groups(), " class=", body.get_class())
	if body.has_method("take_damage"):
		_hit = true
		body.take_damage(damage)
		queue_free()
	else:
		print("[Bullet] body has no take_damage: ", body)

func _draw() -> void:
	draw_circle(Vector2.ZERO, 5.0, Color(1.0, 0.2, 0.2, 1.0))
	draw_circle(Vector2.ZERO, 2.5, Color(1.0, 0.6, 0.6, 1.0))
