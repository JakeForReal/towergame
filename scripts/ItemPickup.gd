extends Area2D
## Base item pickup — disappears when player walks over it.

@export var item_type: String = "generic"  # Override in subclasses
@export var item_color: Color = Color(1.0, 1.0, 0.0)  # Override color

var _size: float = 14.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 8  # Detect player on layer 8
	body_entered.connect(_on_collected)
	queue_redraw()

func _draw() -> void:
	var half := _size / 2.0
	# Square block with fill
	draw_rect(Rect2(-half, -half, _size, _size), item_color)
	# Darker border
	draw_rect(Rect2(-half, -half, _size, _size), Color(item_color.r * 0.5, item_color.g * 0.5, item_color.b * 0.5, 1.0), false, 2.0)

func _on_collected(body: Node) -> void:
	print("[ItemPickup] _on_collected: body=", body.name, " item_type=", item_type)
	if body.has_method("apply_item"):
		var applied := body.apply_item(item_type) as bool
		print("[ItemPickup] apply_item returned: ", applied)
		if applied:
			queue_free()
	else:
		print("[ItemPickup] body has no apply_item method: ", body)
