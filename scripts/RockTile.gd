extends Node2D
## Small decorative rock/debris placed randomly across the map.

@export var rock_color: Color = Color(0.35, 0.32, 0.28)
@export var size_variation: float = 1.0  # Multiplier for random size

var _rock_points: PackedVector2Array = PackedVector2Array()
var _initialized: bool = false

func _ready() -> void:
	_init_rock()
	queue_redraw()

func _init_rock() -> void:
	# Generate a random irregular polygon for a rocky shape
	var seed_val := randi()
	var base_size := (5.0 + randf() * 5.0) * size_variation  # 5-10 base, then scaled
	var num_points := 5 + (randi() % 4)  # 5-8 points
	var points := PackedVector2Array()
	for i in range(num_points):
		var angle := TAU * i / num_points + (randf() - 0.5) * 1.0  # wider angle jitter
		var radius := base_size * (0.5 + randf() * 0.5)  # 50-100% of base_size per point
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	_rock_points = points
	_initialized = true

func _draw() -> void:
	if not _initialized:
		return
	# Draw the main rock shape
	draw_colored_polygon(_rock_points, rock_color)
	# Draw a darker edge for depth
	draw_colored_polygon(_rock_points, Color(rock_color.r * 0.7, rock_color.g * 0.7, rock_color.b * 0.7, 1.0))
	# Highlight on top
	var highlight := PackedVector2Array()
	for p in _rock_points:
		highlight.append(p * 0.6)
	draw_colored_polygon(highlight, Color(rock_color.r * 1.3, rock_color.g * 1.3, rock_color.b * 1.3, 0.5))
