extends Node2D
## Spawns collectible items randomly around the map.

@export var firerate_scene: PackedScene = preload("res://scenes/ItemFireRate.tscn")
@export var shield_scene: PackedScene = preload("res://scenes/ItemShield.tscn")
@export var item_count: int = 12
@export var map_radius: float = 1500.0
@export var min_dist_from_center: float = 300.0
@export var min_dist_from_obstacle: float = 50.0  # Minimum distance from trees/rocks

func _ready() -> void:
	_spawn_items()

func _spawn_items() -> void:
	for i in range(item_count):
		_spawn_random_item()

func _spawn_random_item() -> void:
	var scene: PackedScene
	var roll := randi() % 2
	if roll == 0 and firerate_scene:
		scene = firerate_scene
	elif shield_scene:
		scene = shield_scene
	else:
		return
	
	var item: Node2D = scene.instantiate()
	var pos := _random_map_position()
	item.global_position = pos
	add_child(item)

func _random_map_position() -> Vector2:
	for attempt in range(100):  # Rejection sampling to avoid obstacles
		var angle := randf() * TAU
		var dist := min_dist_from_center + randf() * (map_radius - min_dist_from_center)
		var pos := Vector2.from_angle(angle) * dist
		
		if _is_position_clear(pos):
			return pos
	
	# Fallback: return best-effort position
	return Vector2.from_angle(randf() * TAU) * (min_dist_from_center + map_radius) * 0.5

func _is_position_clear(pos: Vector2) -> bool:
	# Check against all tree/bush positions
	for tree in get_tree().get_nodes_in_group("tree"):
		if tree.global_position.distance_to(pos) < min_dist_from_obstacle:
			return false
	# Check against all rock positions
	for rock in get_tree().get_nodes_in_group("rock"):
		if rock.global_position.distance_to(pos) < min_dist_from_obstacle * 0.7:
			return false
	return true
