extends EnemyBase
## Boss enemy — larger, stronger, hits harder.

signal boss_killed

func _ready() -> void:
	# Set values BEFORE calling super so components init correctly
	enemy_name = "BOSS"
	enemy_tier = 2
	base_hp = 480.0  # Triple original 160
	move_speed = 60.0
	attack_damage = 10.0
	attack_range = 60.0
	attack_cooldown = 1.2
	scrap_drop = 25.0
	super._ready()
	scale = Vector2(2.0, 2.0)
	# Make boss non-physical — player walks through, no pushback
	collision_layer = 0
	collision_mask = 0

func _draw() -> void:
	# Large red circle
	draw_circle(Vector2.ZERO, 24.0, Color(0.7, 0.1, 0.1, 1.0))
	# Inner highlight
	draw_circle(Vector2.ZERO, 14.0, Color(0.9, 0.2, 0.2, 1.0))

func _physics_process(delta: float) -> void:
	_find_target()  # Find/update target each frame
	
	# Always chase target — never fully stop
	if is_instance_valid(_target):
		var dist := global_position.distance_to(_target.global_position)
		var dir := (_target.global_position - global_position).normalized()
		_attack_timer -= delta
		
		if dist <= attack_range and _attack_timer <= 0:
			_attack_timer = attack_cooldown
			_do_damage()
		
		# Always keep moving toward player
		_velocity_component.set_direction(dir)
		_velocity_component.move(self)

func _do_damage() -> void:
	if not is_instance_valid(_target):
		return
	var dmg := attack_damage * _scaling_coefficient
	if _target.has_method("take_damage"):
		_target.take_damage(dmg)
	elif _target.has_method("apply_damage"):
		_target.apply_damage(dmg)
	# Push player away on attack hit too
	if _target is CharacterBody2D:
		var push_dir := (_target.global_position - global_position).normalized()
		if push_dir.length() < 0.1:
			push_dir = Vector2.RIGHT
		_target.velocity += push_dir * 200.0

func _on_death() -> void:
	boss_killed.emit()
	super._on_death()