extends Area2D
## Bullet fired by shooter enemies.

@export var speed: float = 200.0
@export var damage: float = 15.0
@export var lifetime: float = 4.0

var _direction: Vector2 = Vector2.RIGHT
var _lifetime_timer: float = 0.0
var _hit: bool = false
var _owner_shooter: Node = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	set_physics_process(true)

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
	position += _direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if _hit:
		return
	_hit = true
	if body == _owner_shooter:
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 5.0, Color(1.0, 0.2, 0.2, 1.0))
	draw_circle(Vector2.ZERO, 2.5, Color(1.0, 0.6, 0.6, 1.0))
