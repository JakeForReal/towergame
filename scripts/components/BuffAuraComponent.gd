extends Area2D
## Buff aura — checks proximity each frame instead of relying on area signals.
## When player enters the zone, apply a stat buff.

signal player_buffed(buff_type: String, active: bool)
signal player_regen(buff_type: String, active: bool)

@export var aura_range: float = 150.0
@export var buff_type: String = "fire_rate"
@export var buff_value: float = 0.25
@export var regen_value: float = 5.0  # HP per second while in aura

var _was_active: bool = false
var _visual: Line2D = null

func _ready() -> void:
	monitoring = true
	monitorable = true
	
	# Create circular collision shape
	var shape := CircleShape2D.new()
	shape.radius = aura_range
	var col := CollisionShape2D.new()
	col.name = "CollisionShape2D"
	col.shape = shape
	col.debug_color = Color(0, 0, 0, 0)
	add_child(col)
	
	# Create circular outline visual
	_visual = Line2D.new()
	_visual.name = "AuraVisual"
	_visual.default_color = Color(0.3, 0.9, 0.5, 0.4)
	_visual.width = 2.0
	_visual.closed = true
	_visual.points = _make_circle_points(aura_range, 48)
	add_child(_visual)
	
	print("BuffAura ready at global pos: ", global_position, " range: ", aura_range)

func _make_circle_points(radius: float, points: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(points):
		var angle := TAU * i / points
		pts.append(Vector2(cos(angle), sin(angle)) * radius)
	return pts

func _process(_delta: float) -> void:
	var player = get_node_or_null("/root/Main/PlayerCharacter")
	if not player:
		return
	
	var dist := global_position.distance_to(player.global_position)
	var is_active := dist <= aura_range
	
	if is_active != _was_active:
		_was_active = is_active
		player_buffed.emit(buff_type, is_active)
		player_regen.emit("regen", is_active)
		if _visual:
			_visual.default_color = Color(0.3, 0.9, 0.5, 0.7 if is_active else 0.4)
