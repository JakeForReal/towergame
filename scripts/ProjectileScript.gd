extends Area2D
class_name Projectile

var speed: float = 300.0
var damage: float = 20.0
var _dir: Vector2 = Vector2.RIGHT
var _lifetime: float = 3.0
var _max_distance: float = 200.0  # Default range in pixels
var _distance_traveled: float = 0.0

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func launch(dir: Vector2, dmg: float, range_pixels: float = 200.0) -> void:
	_dir = dir.normalized()
	speed = 300.0
	damage = dmg
	_max_distance = range_pixels
	_lifetime = 3.0
	_distance_traveled = 0.0
	print("[Projectile] launch: _dir=", _dir, " speed=", speed, " range=", range_pixels)

func _process(delta: float) -> void:
	var total_movement := _dir * speed * delta
	_distance_traveled += total_movement.length()
	if _distance_traveled >= _max_distance:
		queue_free()
		return

	# Move in small steps with collision checks — prevents tunneling through thin objects
	var space := get_world_2d().direct_space_state
	var steps := maxi(1, int(ceil(total_movement.length() / 2.0)))
	var step_vec := total_movement / float(steps)
	for s in range(steps):
		global_position += step_vec
		# Point check at bullet position (small radius to find trees)
		var params := PhysicsPointQueryParameters2D.new()
		params.position = global_position
		params.collision_mask = 8
		params.collide_with_bodies = true
		params.collide_with_areas = false
		var hit = space.intersect_point(params, 1)
		if hit.size() > 0 and hit[0].collider.is_in_group("tree"):
			queue_free()
			return

func _on_area_entered(area: Area2D) -> void:
	print(">>> area_entered: ", area.name, " groups: ", area.get_groups())
	if area.is_in_group("enemy_hurtbox"):
		var enemy = area.get_parent()
		if enemy:
			print("   -> enemy: ", enemy.name, " has take_damage: ", enemy.has_method("take_damage"))
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage)
				print("   -> DMG DEALT!")
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	# Trees are StaticBody2D — bullets are destroyed on contact
	print("[Projectile] hit solid body: ", body.name, " group tree: ", body.is_in_group("tree"))
	if body.is_in_group("tree"):
		queue_free()
