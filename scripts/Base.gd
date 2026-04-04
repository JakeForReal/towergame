extends Node2D
## The Base — located at world origin, enemies pathfind toward this.

@export var max_health: float = 100.0

var _health_component: HealthComponent = null

func _ready() -> void:
	_health_component = HealthComponent.new()
	_health_component.name = "HealthComponent"
	_health_component.max_health = max_health
	_health_component.current_health = max_health
	add_child(_health_component)
	_health_component.health_changed.connect(_on_health_changed)

func _on_health_changed(current: float, max_hp: float) -> void:
	var bar := get_node_or_null("BaseHPBar") as ProgressBar
	if bar:
		bar.max_value = max_hp
		bar.value = current

func get_base_position() -> Vector2:
	return global_position

func take_damage(amount: float) -> void:
	if _health_component:
		_health_component.take_damage(amount)
	if _health_component and _health_component.current_health <= 0:
		GameState.end_run(false)
