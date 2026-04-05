extends Node2D
## Scatters decorative rock tiles and solid trees randomly across the map at game start.

@export var rock_scene: PackedScene = preload("res://scenes/RockTile.tscn")
@export var rock_count: int = 300
@export var tree_scene: PackedScene = preload("res://scenes/TreeTile.tscn")
@export var tree_count: int = 80
@export var map_radius: float = 2250.0  # Covers the full map (MAP_HALF_SIZE)
@export var min_dist_from_center: float = 100.0  # Keep only the base area clear

func _ready() -> void:
	_spawn_rocks()
	_spawn_trees()

func _spawn_rocks() -> void:
	for i in range(rock_count):
		var rock: Node2D = rock_scene.instantiate()
		rock.size_variation = 0.4 + randf() * 1.8  # 0.4x to 2.2x — much bigger spread
		rock.rock_color = _random_rock_color()
		
		# Pick a random position in a circle
		var angle := randf() * TAU
		var dist := min_dist_from_center + randf() * (map_radius - min_dist_from_center)
		rock.global_position = Vector2.from_angle(angle) * dist
		rock.rotation = randf() * TAU
		
		add_child(rock)

func _spawn_trees() -> void:
	for i in range(tree_count):
		var tree: Node2D = tree_scene.instantiate()
		tree.size_scale = 0.7 + randf() * 0.8
		tree.tree_color = _random_tree_color()
		
		# Pick a random position in a circle, avoiding center
		var angle := randf() * TAU
		var dist := min_dist_from_center + randf() * (map_radius - min_dist_from_center)
		tree.global_position = Vector2.from_angle(angle) * dist
		tree.rotation = randf() * TAU
		
		add_child(tree)

func _random_rock_color() -> Color:
	var colors := [
		Color(0.35, 0.32, 0.28),  # Dark gray-brown
		Color(0.40, 0.36, 0.30),  # Warm gray
		Color(0.30, 0.28, 0.25),  # Darker gray
		Color(0.45, 0.40, 0.35),  # Light brown-gray
		Color(0.33, 0.30, 0.27),  # Cool gray
		Color(0.25, 0.22, 0.20),  # Very dark
		Color(0.50, 0.44, 0.38),  # Medium warm brown
		Color(0.28, 0.25, 0.23),  # Near-black gray
		Color(0.42, 0.38, 0.33),  # Brown-gray
		Color(0.36, 0.33, 0.29),  # Medium gray-brown
	]
	return colors[randi() % colors.size()]

func _random_tree_color() -> Color:
	var colors := [
		Color(0.18, 0.30, 0.15),  # Dark green
		Color(0.22, 0.35, 0.18),  # Medium dark green
		Color(0.15, 0.26, 0.12),  # Very dark green
		Color(0.25, 0.38, 0.20),  # Lighter green
		Color(0.20, 0.32, 0.16),  # Mid green
	]
	return colors[randi() % colors.size()]
