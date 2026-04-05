extends Node2D
## Solid tree obstacle — blocks player, enemies, and bullets.
## Uses collision layer 8 for physical and bullet collision.

@export var tree_color: Color = Color(0.20, 0.28, 0.16)
@export var trunk_color: Color = Color(0.28, 0.18, 0.10)
@export var size_scale: float = 1.0  # Multiplier for random sizing

var _size: float = 1.0

func _ready() -> void:
	add_to_group("tree")
	_size = (0.8 + randf() * 0.8) * size_scale
	queue_redraw()

	# Scale collision shape to match visual canopy size.
	# Canopy circles are ~18px radius at scale 1.0 — collision now matches.
	var collision_shape := $CollisionShape2D as CollisionShape2D
	var new_shape := CircleShape2D.new()
	new_shape.radius = max(20.0, 18.0 * _size)
	collision_shape.shape = new_shape

func _draw() -> void:
	var s := _size
	# Trunk
	var trunk_rect := Rect2(-3.0 * s, -2.0 * s, 6.0 * s, 16.0 * s)
	draw_rect(trunk_rect, trunk_color)
	# Canopy — layered circles for depth
	draw_circle(Vector2(0.0, -10.0 * s), 18.0 * s, Color(tree_color.r * 0.6, tree_color.g * 0.6, tree_color.b * 0.6, 1.0))  # shadow layer
	draw_circle(Vector2(-3.0, -12.0 * s), 15.0 * s, tree_color)  # left
	draw_circle(Vector2(4.0, -11.0 * s), 14.0 * s, tree_color)  # right
	draw_circle(Vector2(0.0, -16.0 * s), 13.0 * s, Color(tree_color.r * 1.2, tree_color.g * 1.2, tree_color.b * 1.2, 1.0))  # highlight
