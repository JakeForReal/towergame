extends Area2D
class_name SynergyComponent
## Tower Synergy System
## When another tower enters this zone, both gain stacking 10% stat bonuses.
## When player enters zone, player gets class-specific buffs.

signal synergy_stacks_changed(total_stacks: int)
signal player_buffed(buff_type: String, stacks: int)

@export var synergy_range: float = 80.0

var _tower_stacks: int = 0
var _player_buff_type: String = ""
var _player_buff_stacks: int = 0

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	
	# Create collision shape if not already set up by a scene
	if not has_node("CollisionShape2D"):
		var shape := CircleShape2D.new()
		shape.radius = synergy_range
		var col := CollisionShape2D.new()
		col.name = "CollisionShape2D"
		col.shape = shape
		add_child(col)
	# Update collision shape to match synergy_range
	_update_shape_radius()

func _update_shape_radius() -> void:
	if has_node("CollisionShape2D") and $CollisionShape2D.shape is CircleShape2D:
		$CollisionShape2D.shape.radius = synergy_range

func _on_area_entered(area: Area2D) -> void:
	if area == self:
		return
	
	if area is SynergyComponent:
		# Another tower is in our synergy zone
		_tower_stacks += 1
		synergy_stacks_changed.emit(_tower_stacks)
		_apply_tower_bonus()
		area._tower_stacks += 1
		area.synergy_stacks_changed.emit(area._tower_stacks)
		area._apply_tower_bonus()
	
	elif area.is_in_group("player_hurtbox"):
		_apply_player_buff()

func _on_area_exited(area: Area2D) -> void:
	if area is SynergyComponent:
		_tower_stacks = max(0, _tower_stacks - 1)
		synergy_stacks_changed.emit(_tower_stacks)
		_apply_tower_bonus()
		area._tower_stacks = max(0, area._tower_stacks - 1)
		area.synergy_stacks_changed.emit(area._tower_stacks)
		area._apply_tower_bonus()
	
	elif area.is_in_group("player_hurtbox"):
		_remove_player_buff()

func _apply_tower_bonus() -> void:
	# Called on the tower owning this synergy component
	var parent := get_parent()
	if parent and parent.has_method("apply_synergy_bonus"):
		parent.apply_synergy_bonus(_tower_stacks)

func _apply_player_buff() -> void:
	var parent := get_parent()
	if parent and parent.has_method("get_player_buff_type"):
		_player_buff_type = parent.get_player_buff_type()
		_player_buff_stacks = _tower_stacks
		player_buffed.emit(_player_buff_type, _player_buff_stacks)

func _remove_player_buff() -> void:
	_player_buff_type = ""
	_player_buff_stacks = 0
	player_buffed.emit("", 0)

func get_synergy_stacks() -> int:
	return _tower_stacks

func get_bonus_multiplier() -> float:
	return 1.0 + (_tower_stacks * 0.10)
