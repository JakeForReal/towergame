extends Node2D
class_name TowerBase
## Base class for all towers.

enum TowerState {
	IDLE,
	TARGETING,
	ATTACKING,
	COOLING_DOWN
}

@export var tower_name: String = "Basic Turret"
@export var tower_type: String = "ballistic"
@export var tier: int = 1  # 1, 2, or 3
@export var cost: float = 25.0
@export var upgrade_cost: float = 50.0

@export var max_health: float = 50.0
@export var damage: float = 10.0
@export var fire_rate: float = 2.0  # Attacks per second
@export var range: float = 150.0  # Pixels
@export var synergy_range: float = 80.0
@export var projectile_range: float = 200.0  # Pixels

var _health_component: HealthComponent = null
var _synergy_component: SynergyComponent = null
var _current_state: TowerState = TowerState.IDLE
var _target: Node2D = null
var _attack_cooldown: float = 0.0
var _synergy_bonus: float = 1.0  # Multiplier from synergy stacks

var _placed: bool = false
var _aura_range: float = 150.0
var _in_aura_range: bool = false

@export var auto_place: bool = false  # Set true for base/auto turrets
var _build_cost_paid: bool = false

func _ready() -> void:
	add_to_group("tree")
	_setup_components()
	_set_tier(tier)
	if auto_place:
		place()

func _setup_components() -> void:
	_health_component = HealthComponent.new()
	_health_component.name = "HealthComponent"
	_health_component.max_health = max_health
	_health_component.current_health = max_health
	_health_component.died.connect(_on_death)
	add_child(_health_component)
	
	# Synergy zone
	_synergy_component = SynergyComponent.new()
	_synergy_component.name = "SynergyComponent"
	_synergy_component.synergy_range = synergy_range
	_synergy_component.synergy_stacks_changed.connect(_on_synergy_stacks_changed)
	add_child(_synergy_component)
	
	# Collision for range detection
	var range_area := Area2D.new()
	range_area.name = "RangeArea"
	range_area.collision_layer = 0
	range_area.collision_mask = 2  # Detects enemy hurtboxes
	var shape := CircleShape2D.new()
	shape.radius = range
	var col_shape := CollisionShape2D.new()
	col_shape.name = "CollisionShape2D"
	col_shape.shape = shape
	range_area.add_child(col_shape)
	add_child(range_area)
	range_area.area_entered.connect(_on_enemy_entered)
	range_area.area_exited.connect(_on_enemy_exited)

var _idle_scan_timer: float = 0.0

func _process(delta: float) -> void:
	if not _placed:
		return
	_check_aura()
	
	if _attack_cooldown > 0:
		_attack_cooldown -= delta
	
	match _current_state:
		TowerState.IDLE:
			_idle_scan_timer += delta
			if _idle_scan_timer >= 3.0:
				_idle_scan_timer = 0.0
				print("[Tower] IDLE — scanning for enemies in range=", range, " at pos=", global_position)
			_find_target()
		TowerState.TARGETING:
			if not is_instance_valid(_target):
				_set_state(TowerState.IDLE)
			else:
				_look_at_target()
				if _attack_cooldown <= 0:
					_set_state(TowerState.ATTACKING)
		TowerState.ATTACKING:
			perform_attack()
			_set_state(TowerState.COOLING_DOWN)
		TowerState.COOLING_DOWN:
			if _attack_cooldown <= 0:
				_set_state(TowerState.IDLE)

func _check_aura() -> void:
	var player = get_node_or_null("/root/Main/PlayerCharacter")
	if not player:
		return
	var dist := global_position.distance_to(player.global_position)
	var in_range := dist <= _aura_range
	if in_range != _in_aura_range:
		_in_aura_range = in_range
		player.apply_buff("fire_rate_aura", in_range)
		player.apply_regen_buff("regen", in_range)
	queue_redraw()

func _find_target() -> void:
	var range_area := get_node_or_null("RangeArea") as Area2D
	if not range_area:
		return
	
	# Primary: check overlapping areas (HurtboxComponent)
	var enemies := range_area.get_overlapping_areas()
	for enemy_area in enemies:
		if enemy_area is HurtboxComponent:
			var owner = enemy_area.get_owner_node()
			if owner and owner.is_in_group("enemy"):
				_target = owner
				_set_state(TowerState.TARGETING)
				return
	
	# Fallback: also check overlapping bodies — catches CharacterBody2D enemies
	# that might not have a HurtboxComponent overlapping yet
	var bodies := range_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemy") and is_instance_valid(body):
			_target = body
			_set_state(TowerState.TARGETING)
			return

func _look_at_target() -> void:
	if is_instance_valid(_target):
		rotation = global_position.angle_to_point(_target.global_position) + PI/2

func perform_attack() -> void:
	if not is_instance_valid(_target):
		return
	
	var projectile_scene: PackedScene = preload("res://scenes/Projectile.tscn")
	var proj: Projectile = projectile_scene.instantiate()
	proj.global_position = global_position
	var dir := (_target.global_position - global_position).normalized()
	proj.launch(dir, get_effective_damage(), projectile_range)
	# Add to world root
	get_tree().current_scene.add_child(proj)
	
	_attack_cooldown = 1.0 / fire_rate
	
	print("[Tower] FIRE! target=", _target.name, " pos=", _target.global_position, " dmg=", get_effective_damage())
	
	# Muzzle flash — brief white circle at gun tip
	var flash := Node2D.new()
	flash.name = "MuzzleFlash"
	var circle := ColorRect.new()
	circle.color = Color(1.0, 0.9, 0.3, 1.0)
	circle.offset_left = -5.0
	circle.offset_top = -5.0
	circle.offset_right = 5.0
	circle.offset_bottom = 5.0
	flash.add_child(circle)
	flash.global_position = global_position + dir * 20.0
	flash.rotation = dir.angle()
	get_tree().current_scene.add_child(flash)
	var tween := create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.1)
	tween.tween_callback(flash.queue_free)
	print("[Tower] Muzzle flash spawned at ", flash.global_position)

func _on_enemy_entered(area: Area2D) -> void:
	print("[Tower] _on_enemy_entered: area=", area.name, " is HurtboxComponent=", area is HurtboxComponent)
	if area is HurtboxComponent:
		var owner = area.get_owner_node()
		print("[Tower]   -> owner=", owner.name if owner else "null", " is_in_group(enemy)=", owner.is_in_group("enemy") if owner else false)
		if owner and owner.is_in_group("enemy"):
			_target = owner
			_set_state(TowerState.TARGETING)
			print("[Tower] TARGET ACQUIRED: ", owner.name)

func _on_enemy_exited(area: Area2D) -> void:
	var area_owner = area.get_owner_node()
	# Only clear target if it's the exact one that left
	if area_owner == _target:
		print("[Tower] Target ", _target.name, " left range")
		_target = null
		_set_state(TowerState.IDLE)

func _set_state(new_state: TowerState) -> void:
	_current_state = new_state

func _on_synergy_stacks_changed(stacks: int) -> void:
	_synergy_bonus = 1.0 + (stacks * 0.10)
	_apply_synergy_bonus()

func _apply_synergy_bonus() -> void:
	# Override in subclass to apply stat bonuses
	pass

func get_effective_damage() -> float:
	return damage * _synergy_bonus

func apply_synergy_bonus(stacks: int) -> void:
	_synergy_bonus = 1.0 + (stacks * 0.10)

func place() -> void:
	_placed = true
	_in_aura_range = false  # Force re-check
	print("[Tower] place() called at ", global_position)
	_check_aura()  # Check immediately so buffs apply right away

func upgrade() -> bool:
	if tier >= 3:
		return false
	tier += 1
	_set_tier(tier)
	return true

func _set_tier(t: int) -> void:
	tier = t
	match tier:
		1:
			max_health = 50.0
			damage = 10.0
			fire_rate = 1.0
			range = 150.0
		2:
			max_health = 75.0
			damage = 17.0
			fire_rate = 1.3
			range = 180.0
		3:
			max_health = 100.0
			damage = 25.0
			fire_rate = 1.6
			range = 220.0
	
	if _health_component:
		_health_component.set_max_health(max_health)

func _on_death() -> void:
	queue_free()

func _draw() -> void:
	# Circular tower body
	draw_circle(Vector2.ZERO, 16.0, Color(0.3, 0.5, 0.7, 1.0))
	# Circular turret on top
	draw_circle(Vector2(0, -10), 6.0, Color(0.2, 0.35, 0.55, 1.0))
	# Aura outline
	if _in_aura_range:
		draw_arc(Vector2.ZERO, _aura_range, 0.0, TAU, 48, Color(0.3, 0.9, 0.5, 0.7), 2.0)
	else:
		draw_arc(Vector2.ZERO, _aura_range, 0.0, TAU, 48, Color(0.3, 0.9, 0.5, 0.4), 2.0)

func get_placement_valid() -> bool:
	return _placed
