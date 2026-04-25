extends CharacterBody2D
class_name EnemyBase
## Base class for all enemies with melee combat.

@export var enemy_name: String = "Grunt"
@export var enemy_tier: int = 0  # 0=basic, 1=medium, 2=elite
@export var base_hp: float = 20.0
@export var move_speed: float = 104.0  # 30% faster than original 80
@export var attack_damage: float = 5.0
@export var attack_range: float = 50.0  # Distance at which enemy attacks
@export var attack_cooldown: float = 1.0
@export var scrap_drop: float = 5.0

var _health_component: HealthComponent = null
var _velocity_component: VelocityComponent = null
var _attack_timer: float = 0.0
var _target: Node2D = null
var _scaling_coefficient: float = 1.0
var _is_attacking: bool = false

func _ready() -> void:
	_setup_components()
	add_to_group("enemy")
	print("Enemy ready: collision_layer=", collision_layer, " name=", name)
	if has_node("CollisionShape2D"):
		$CollisionShape2D.debug_color = Color(0, 0, 0, 0)

func _setup_components() -> void:
	collision_layer = 2 | 8  # Enemy layer + trees (layer 8) so move_and_slide() collides with trees
	collision_mask = 8       # Enemies detect trees
	print("Enemy setup: collision_layer=", collision_layer, " collision_mask=", collision_mask)
	
	_health_component = HealthComponent.new()
	_health_component.name = "HealthComponent"
	_health_component.max_health = base_hp
	_health_component.current_health = base_hp
	_health_component.died.connect(_on_death)
	_health_component.health_changed.connect(_on_health_changed)
	add_child(_health_component)
	
	_velocity_component = VelocityComponent.new()
	_velocity_component.name = "VelocityComponent"
	_velocity_component.max_speed = move_speed
	add_child(_velocity_component)
	
	# Hurtbox for taking damage
	var hurtbox := HurtboxComponent.new()
	hurtbox.name = "Hurtbox"
	hurtbox.health_component_path = NodePath("../HealthComponent")
	hurtbox.collision_layer = 2
	hurtbox.collision_mask = 4  # Detects player projectiles
	add_child(hurtbox)
	hurtbox.add_to_group("enemy_hurtbox")
	# Hide debug collision shapes
	if hurtbox.has_node("CollisionShape2D"):
		hurtbox.get_node("CollisionShape2D").debug_color = Color(0, 0, 0, 0)

func _physics_process(delta: float) -> void:
	if _attack_timer > 0:
		_attack_timer -= delta
	
	_find_target()
	
	if is_instance_valid(_target):
		var dist := global_position.distance_to(_target.global_position)
		var dir := (_target.global_position - global_position).normalized()
		
		if dist <= attack_range:
			# In range — deal damage on cooldown, keep moving through
			_attack_timer -= delta
			if _attack_timer <= 0:
				_attack_timer = attack_cooldown
				_do_damage()
			# Slow down but keep moving slightly past player
			var push_dir := (_target.global_position - global_position).normalized()
			_velocity_component.set_direction(push_dir)
			_velocity_component.move(self)
		else:
			# Move toward target
			_is_attacking = false
			_velocity_component.set_direction(dir)
			_velocity_component.move(self)

func _do_damage() -> void:
	if not is_instance_valid(_target):
		return
	var dmg := attack_damage * _scaling_coefficient
	print("[Enemy ", name, "] dealing ", dmg, " to ", _target.name)
	if _target.has_method("take_damage"):
		_target.take_damage(dmg)
	elif _target.has_method("apply_damage"):
		_target.apply_damage(dmg)

func _find_target() -> void:
	# Always prefer player if alive, otherwise target base
	var player := get_node_or_null("/root/Main/PlayerCharacter")
	if player and player is Node2D:
		_target = player
		return
	_target = get_node_or_null("/root/Main/Base")

func _perform_attack() -> void:
	_attack_timer = attack_cooldown
	_is_attacking = true
	
	if not is_instance_valid(_target):
		return
	
	var dmg := attack_damage * _scaling_coefficient
	print("[Enemy ", name, "] ATTACKING ", _target.name, " for ", dmg)
	
	# Damage the target
	if _target.has_method("take_damage"):
		_target.take_damage(dmg)
	elif _target.has_method("apply_damage"):
		_target.apply_damage(dmg)

func take_damage(amount: float) -> void:
	if _health_component:
		_health_component.take_damage(amount)
	else:
		# Fallback if no health component
		_take_damage_direct(amount)

func _take_damage_direct(amount: float) -> void:
	pass  # Handled by health component

func take_scaled_damage(damage: float, coefficient: float) -> void:
	if _health_component:
		_health_component.take_damage(damage * coefficient)

func apply_scaling(coefficient: float) -> void:
	_scaling_coefficient = coefficient
	if _health_component:
		_health_component.set_max_health(base_hp * coefficient)

func _on_health_changed(current: float, max_hp: float) -> void:
	var bar := get_node_or_null("HealthBar") as ProgressBar
	if bar:
		bar.max_value = max_hp
		bar.value = current

func _on_death() -> void:
	if scrap_drop > 0:
		var gs := get_node_or_null("/root/GameState")
		if gs:
			gs.add_scrap(scrap_drop * _scaling_coefficient)
	queue_free()

func get_scrap_value() -> float:
	return scrap_drop * _scaling_coefficient

func _draw() -> void:
	# Circular enemy — half the size of the player (player uses radius 18)
	draw_circle(Vector2.ZERO, 9.0, Color(0.85, 0.2, 0.2, 1.0))
