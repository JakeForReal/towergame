extends EnemyBase
## Ranged enemy — stops at standoff range and shoots bullets.

@export var bullet_scene: PackedScene = preload("res://scenes/EnemyShooterBullet.tscn")
@export var standoff_range: float = 200.0  # Stop ~200px from player
@export var bullet_damage: float = 15.0

func _ready() -> void:
	enemy_name = "Shooter"
	enemy_tier = 1
	base_hp = 15.0
	move_speed = 70.0
	attack_damage = 0.0  # No melee damage
	attack_range = standoff_range
	attack_cooldown = 1.5
	scrap_drop = 8.0
	super._ready()

func _draw() -> void:
	# Shooter = blue to distinguish from red melee enemies
	draw_circle(Vector2.ZERO, 9.0, Color(0.2, 0.4, 0.9, 1.0))
	# Inner highlight
	draw_circle(Vector2.ZERO, 4.5, Color(0.3, 0.5, 1.0, 1.0))

func _physics_process(delta: float) -> void:
	_find_target()
	
	if not is_instance_valid(_target):
		return
	
	var dist := global_position.distance_to(_target.global_position)
	var dir := (_target.global_position - global_position).normalized()
	
	if dist > standoff_range:
		# Move toward target until in standoff range
		_velocity_component.set_direction(dir)
		_velocity_component.move(self)
		_attack_timer -= delta
	else:
		# In range — stop and shoot
		_velocity_component.stop()
		_attack_timer -= delta
		if _attack_timer <= 0:
			_attack_timer = attack_cooldown
			_shoot_bullet(dir)

func _shoot_bullet(dir: Vector2) -> void:
	if not bullet_scene:
		return
	var bullet: Node2D = bullet_scene.instantiate()
	bullet.global_position = global_position
	bullet.setup(dir)
	# Add to world
	var world := get_tree().current_scene if get_tree().current_scene else get_parent()
	world.add_child(bullet)

func _do_damage() -> void:
	# Override — shooter doesn't do melee damage
	pass
