extends Area2D
class_name HitboxComponent
## Damage hitbox — attach to attacks/projectiles to detect hits on hurt areas.

signal hit(hurtbox: HurtboxComponent, damage: float)

@export var base_damage: float = 10.0
@export var damage_coefficient: float = 1.0  # Multiplier from synergy/buffs
@export var knockback_force: float = 0.0
@export var knockback_direction: Vector2 = Vector2.ZERO  # If zero, uses hit direction
@export var pierce_count: int = 0  # 0 = no pierce, 1+ = pierce that many extra targets
@export var hit_cooldown: float = 0.0  # Minimum time between hits on the same target

var _hit_targets: Array[HurtboxComponent] = []
var _pierce_remaining: int = 0
var _cooldown_timers: Dictionary = {}

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	_pierce_remaining = pierce_count

func _on_area_entered(area: Area2D) -> void:
	if area is HurtboxComponent:
		var hurtbox: HurtboxComponent = area
		if not _can_hit(hurtbox):
			return
		
		var damage := base_damage * damage_coefficient
		hurtbox.receive_hit(damage, self)
		hit.emit(hurtbox, damage)
		_register_hit(hurtbox)
		
		if knockback_force > 0:
			var dir := knockback_direction
			if dir == Vector2.ZERO and has_node(".."):
				dir = (hurtbox.global_position - get_parent().global_position).normalized()
			hurtbox.apply_knockback(dir * knockback_force)

func _can_hit(hurtbox: HurtboxComponent) -> bool:
	if hurtbox in _hit_targets:
		return false
	if hurtbox.get_owner_node().is_in_group("invincible"):
		return false
	# Check cooldown
	var owner_id := hurtbox.get_owner_node().get_instance_id()
	if _cooldown_timers.has(owner_id):
		if _cooldown_timers[owner_id] > 0:
			return false
	return true

func _register_hit(hurtbox: HurtboxComponent) -> void:
	_hit_targets.append(hurtbox)
	if pierce_count > 0:
		_pierce_remaining -= 1
		if _pierce_remaining < 0:
			queue_free()  # Remove hitbox after pierce exhausted
	if hit_cooldown > 0:
		var owner_id := hurtbox.get_owner_node().get_instance_id()
		_cooldown_timers[owner_id] = hit_cooldown
		await get_tree().create_timer(hit_cooldown, false).timeout
		_cooldown_timers.erase(owner_id)
		if hurtbox in _hit_targets:
			_hit_targets.erase(hurtbox)

func reset_hits() -> void:
	_hit_targets.clear()
	_pierce_remaining = pierce_count

func set_damage_coefficient(c: float) -> void:
	damage_coefficient = c
