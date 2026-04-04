extends Node
class_name VelocityComponent
## Reusable 2D movement component. Attach to CharacterBody2D.

signal velocity_changed(vel: Vector2)

@export var max_speed: float = 200.0
@export var acceleration: float = 1000.0
@export var friction: float = 800.0
@export var air_acceleration: float = 400.0
@export var air_friction: float = 200.0

var _velocity: Vector2 = Vector2.ZERO
var _direction: Vector2 = Vector2.ZERO
var _is_grounded: bool = false

func _physics_process(delta: float) -> void:
	# Apply friction
	var accel := acceleration if _is_grounded else air_acceleration
	var decel := friction if _is_grounded else air_friction
	
	if _direction != Vector2.ZERO:
		_velocity = _velocity.move_toward(_direction * max_speed, accel * delta)
	else:
		_velocity = _velocity.move_toward(Vector2.ZERO, decel * delta)
	
	velocity_changed.emit(_velocity)

func move(body: CharacterBody2D) -> void:
	body.velocity = _velocity
	body.move_and_slide()
	_is_grounded = body.is_on_floor()

func set_direction(dir: Vector2) -> void:
	_direction = dir.normalized()

func get_speed() -> float:
	return _velocity.length()

func get_velocity() -> Vector2:
	return _velocity

func stop() -> void:
	_velocity = Vector2.ZERO
	_direction = Vector2.ZERO

func apply_impulse(force: Vector2) -> void:
	_velocity += force

func is_moving() -> bool:
	return _velocity.length() > 1.0

func set_max_speed(s: float) -> void:
	max_speed = s
