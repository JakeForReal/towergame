extends Node2D
## Spawns collectible items randomly around the map.

@export var firerate_scene: PackedScene = preload("res://scenes/ItemFireRate.tscn")
@export var shield_scene: PackedScene = preload("res://scenes/ItemShield.tscn")
@export var item_count: int = 12
@export var map_radius: float = 1500.0
@export var min_dist_from_center: float = 300.0

func _ready() -> void:
	_spawn_items()

func _spawn_items() -> void:
	for i in range(item_count):
		_spawn_random_item()

func _spawn_random_item() -> void:
	var scene: PackedScene
	var item_type: String
	var roll := randi() % 2
	if roll == 0 and firerate_scene:
		scene = firerate_scene
		item_type = "firerate"
	elif shield_scene:
		scene = shield_scene
		item_type = "shield"
	else:
		return
	
	var item: Node2D = scene.instantiate()
	var pos := _random_map_position()
	item.global_position = pos
	add_child(item)

func _random_map_position() -> Vector2:
	var angle := randf() * TAU
	var dist := min_dist_from_center + randf() * (map_radius - min_dist_from_center)
	return Vector2.from_angle(angle) * dist
