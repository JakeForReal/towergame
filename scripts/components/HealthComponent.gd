extends Node
class_name HealthComponent
## Reusable health component. Attach to any Node2D to give it HP.

signal health_changed(current: float, max: float)
signal died()
signal damaged(amount: float)

@export var max_health: float = 100.0
@export var current_health: float = 100.0
@export var invincibility_time: float = 0.0  # Seconds of invincibility after taking damage

var _invincible: bool = false
var _invincibility_timer: float = 0.0

func _process(delta: float) -> void:
	if _invincible:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0:
			_invincible = false

func take_damage(amount: float) -> bool:
	if _invincible or current_health <= 0:
		return false
	
	current_health = max(0.0, current_health - amount)
	health_changed.emit(current_health, max_health)
	damaged.emit(amount)
	
	if current_health <= 0:
		died.emit()
		return true
	return false

func heal(amount: float) -> void:
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)

func is_alive() -> bool:
	return current_health > 0

func get_health_ratio() -> float:
	if max_health <= 0:
		return 0.0
	return current_health / max_health

func set_max_health(new_max: float) -> void:
	var ratio := get_health_ratio()
	max_health = new_max
	current_health = new_max * ratio
	health_changed.emit(current_health, max_health)

func _start_invincibility() -> void:
	if invincibility_time > 0:
		_invincible = true
		_invincibility_timer = invincibility_time

func kill() -> void:
	take_damage(current_health)
