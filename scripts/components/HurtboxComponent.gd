extends Area2D
class_name HurtboxComponent
## Damage receiver — attach to characters/towers/enemies.

signal received_hit(damage: float, hitbox: HitboxComponent)

@export var health_component_path: NodePath
@export var disable_on_death: bool = true

var _health: HealthComponent = null

func _ready() -> void:
	# Add collision shape if none exists
	if not has_node("CollisionShape2D"):
		var shape := CircleShape2D.new()
		shape.radius = 14.0
		var col := CollisionShape2D.new()
		col.name = "CollisionShape2D"
		col.shape = shape
		add_child(col)
	
	collision_layer = 2   # Enemy hurtbox layer
	collision_mask = 4    # Detects player projectiles
	monitoring = true     # Detect area entrances
	monitorable = true
	
	if health_component_path:
		_health = get_node(health_component_path)
	elif get_parent():
		_health = get_parent().get_node_or_null("HealthComponent")
	if _health:
		_health.died.connect(_on_death)

func receive_hit(damage: float, from_hitbox: HitboxComponent) -> void:
	if _health:
		_health.take_damage(damage)
	received_hit.emit(damage, from_hitbox)

func get_owner_node() -> Node:
	return get_parent()

func _on_death() -> void:
	if disable_on_death:
		set_deferred("monitoring", false)
		set_deferred("monitorable", false)

func apply_knockback(direction: Vector2) -> void:
	var parent := get_parent()
	if parent is CharacterBody2D:
		parent.velocity += direction
	elif parent.has_method("apply_knockback"):
		parent.apply_knockback(direction)
