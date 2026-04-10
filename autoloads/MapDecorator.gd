extends Node2D
## Scatters decorative rock tiles and solid trees randomly across the map at game start.

@export var rock_scene: PackedScene = preload("res://scenes/RockTile.tscn")
@export var rock_count: int = 300
@export var tree_scene: PackedScene = preload("res://scenes/TreeTile.tscn")
@export var tree_count: int = 150
@export var map_radius: float = 2250.0  # Covers the full map (MAP_HALF_SIZE)
@export var min_dist_from_center: float = 100.0  # Keep only the base area clear
@export var edge_bush_count: int = 100  # Extra bushes in the outer band

func _ready() -> void:
	_spawn_rocks()
	_spawn_trees()
	_spawn_edge_bushes()
	queue_redraw()  # Draw boundary line

func _spawn_rocks() -> void:
	for i in range(rock_count):
		var rock: Node2D = rock_scene.instantiate()
		rock.size_variation = 0.4 + randf() * 1.8
		rock.rock_color = _random_rock_color()
		
		# Square distribution: random x/y within bounds, skip inner clear zone
		var x := 0.0
		var y := 0.0
		var in_clear_zone := true
		while in_clear_zone:
			x = -map_radius + randf() * 2.0 * map_radius
			y = -map_radius + randf() * 2.0 * map_radius
			var dist_from_center := Vector2(x, y).length()
			in_clear_zone = dist_from_center < min_dist_from_center
		rock.global_position = Vector2(x, y)
		rock.rotation = randf() * TAU
		rock.add_to_group("rock")
		add_child(rock)

func _spawn_trees() -> void:
	for i in range(tree_count):
		var tree: Node2D = tree_scene.instantiate()
		tree.size_scale = 0.7 + randf() * 0.8
		tree.tree_color = _random_tree_color()
		
		# Square distribution: random x/y within bounds, skip inner clear zone
		var x := 0.0
		var y := 0.0
		var in_clear_zone := true
		while in_clear_zone:
			x = -map_radius + randf() * 2.0 * map_radius
			y = -map_radius + randf() * 2.0 * map_radius
			var dist_from_center := Vector2(x, y).length()
			in_clear_zone = dist_from_center < min_dist_from_center
		tree.global_position = Vector2(x, y)
		tree.add_to_group("tree")
		add_child(tree)

func _spawn_edge_bushes() -> void:
	# Dense bushes along the outer edge of the square map
	var edge_margin := 50.0  # Start bushes 50 units inside the edge
	var x_min := -map_radius + edge_margin
	var x_max := map_radius - edge_margin
	var y_min := -map_radius + edge_margin
	var y_max := map_radius - edge_margin
	
	for i in range(edge_bush_count):
		var tree: Node2D = tree_scene.instantiate()
		tree.size_scale = 0.7 + randf() * 0.8
		tree.tree_color = _random_tree_color()
		
		# Pick a random position along the square perimeter
		var x := x_min + randf() * (x_max - x_min)
		var y := y_min + randf() * (y_max - y_min)
		
		# Clamp to a random edge (top, bottom, left, or right)
		var edge := randi() % 4
		match edge:
			0: y = y_min  # top edge
			1: y = y_max  # bottom edge
			2: x = x_min  # left edge
			3: x = x_max  # right edge
		
		tree.global_position = Vector2(x, y)
		tree.add_to_group("tree")
		add_child(tree)

func _draw() -> void:
	# Draw a yellow boundary rectangle around the map edge
	var half := map_radius
	var top_left := Vector2(-half, -half)
	var top_right := Vector2(half, -half)
	var bottom_right := Vector2(half, half)
	var bottom_left := Vector2(-half, half)
	
	var rect := PackedVector2Array([top_left, top_right, bottom_right, bottom_left, top_left])
	draw_polyline(rect, Color(1.0, 0.9, 0.0, 0.8), 4.0)

func _random_rock_color() -> Color:
	var colors := [
		Color(0.35, 0.32, 0.28),
		Color(0.40, 0.36, 0.30),
		Color(0.30, 0.28, 0.25),
		Color(0.45, 0.40, 0.35),
		Color(0.33, 0.30, 0.27),
		Color(0.25, 0.22, 0.20),
		Color(0.50, 0.44, 0.38),
		Color(0.28, 0.25, 0.23),
		Color(0.42, 0.38, 0.33),
		Color(0.36, 0.33, 0.29),
	]
	return colors[randi() % colors.size()]

func _random_tree_color() -> Color:
	var colors := [
		Color(0.18, 0.30, 0.15),
		Color(0.22, 0.35, 0.18),
		Color(0.15, 0.26, 0.12),
		Color(0.25, 0.38, 0.20),
		Color(0.20, 0.32, 0.16),
	]
	return colors[randi() % colors.size()]
