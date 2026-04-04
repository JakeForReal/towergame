extends Node
## Building System — Handles tower ghost placement, cost validation, and tower instantiation.
## Works as an Autoload singleton.

signal tower_placed(tower: TowerBase)
signal tower_upgraded(tower: TowerBase, new_tier: int)
signal build_attempted(success: bool, message: String)
signal scrap_changed(new_amount: float)

var _scrap: float = 150.0
var _selected_tower_scene: PackedScene = null
var _ghost_instance: Node2D = null
var _placement_valid: bool = false
var _current_tower_cost: float = 0.0
var _build_radius: float = 300.0  # Max distance from player to place towers
var _is_building_mode: bool = false
var _placed_towers: Array[Node] = []  # Track all placed towers for reset on death

# Tower definitions — maps tower type to scene path and cost
var _tower_registry: Dictionary = {}
var _tower_scene: PackedScene = preload("res://scenes/TowerBallistic.tscn")
var _tower_cost: float = 150.0

func _ready() -> void:
	_register_towers()

func _process(_delta: float) -> void:
	if _is_building_mode and is_instance_valid(_ghost_instance):
		_update_ghost_position()

func _register_towers() -> void:
	# This will be populated as tower scenes are created
	# Format: tower_type -> {"scene": PackedScene, "cost": float}
	pass

func enter_build_mode(tower_scene: PackedScene, cost: float) -> void:
	_is_building_mode = true
	_selected_tower_scene = tower_scene
	_current_tower_cost = cost
	
	_ghost_instance = tower_scene.instantiate()
	_ghost_instance.set_process(false)
	_ghost_instance.modulate.a = 0.5
	add_child(_ghost_instance)

func exit_build_mode() -> void:
	_is_building_mode = false
	if is_instance_valid(_ghost_instance):
		_ghost_instance.queue_free()
		_ghost_instance = null

func _update_ghost_position() -> void:
	var player := _get_player()
	if not player:
		return

	# Get world-space mouse position
	var main = get_node_or_null("/root/Main")
	var mouse_pos: Vector2 = main.get_global_mouse_position() if main else Vector2.ZERO
	var player_pos := player.global_position
	var dist: float = player_pos.distance_to(mouse_pos)

	_placement_valid = dist <= _build_radius

	if _ghost_instance:
		_ghost_instance.global_position = mouse_pos
		# Color the ghost based on validity
		_ghost_instance.modulate.a = 0.5 if _placement_valid else 0.2

func place_tower_at(pos: Vector2) -> bool:
	print("[BuildingSystem] place_tower_at called: pos=", pos)
	var gs = get_node_or_null("/root/GameState")
	if not gs:
		print("[BuildingSystem] No GameState found")
		return false

	# Check build radius
	var player = get_node_or_null("/root/Main/PlayerCharacter")
	if not player:
		print("[BuildingSystem] No player found")
		return false
	var dist: float = player.global_position.distance_to(pos)
	print("[BuildingSystem] dist=", dist, " build_radius=", _build_radius)
	if dist > _build_radius:
		print("[BuildingSystem] Too far from player")
		build_attempted.emit(false, "Too far from player")
		return false

	if gs.player_scrap < _tower_cost:
		build_attempted.emit(false, "Not enough scrap")
		return false

	gs.player_scrap -= _tower_cost
	gs.scrap_changed.emit(gs.player_scrap)

	var tower: TowerBase = _tower_scene.instantiate()
	tower.global_position = pos
	get_parent().add_child(tower)
	tower.place()
	_placed_towers.append(tower)
	print("[BuildingSystem] Tower placed! scrap left=", gs.player_scrap)
	tower_placed.emit(tower)
	build_attempted.emit(true, "Tower placed!")
	return true

func try_place_tower() -> bool:
	if not _is_building_mode:
		return false
	
	if not _placement_valid:
		build_attempted.emit(false, "Too far from player to place tower")
		return false
	
	if _scrap < _current_tower_cost:
		build_attempted.emit(false, "Not enough scrap")
		return false
	
	# Spend scrap
	_scrap -= _current_tower_cost
	scrap_changed.emit(_scrap)
	
	# Instantiate and place tower
	var tower: TowerBase = _selected_tower_scene.instantiate()
	tower.global_position = _ghost_instance.global_position
	tower.place()
	
	# Reparent to world
	get_parent().add_child(tower)
	_placed_towers.append(tower)
	
	# Exit build mode
	exit_build_mode()
	
	tower_placed.emit(tower)
	build_attempted.emit(true, "Tower placed!")
	return true

func _get_player() -> Node2D:
	return get_node_or_null("/root/Main/PlayerCharacter")

func add_scrap(amount: float) -> void:
	_scrap += amount
	scrap_changed.emit(_scrap)

func spend_scrap(amount: float) -> bool:
	if _scrap >= amount:
		_scrap -= amount
		scrap_changed.emit(_scrap)
		return true
	return false

func get_scrap() -> float:
	return _scrap

func is_in_build_mode() -> bool:
	return _is_building_mode

func register_tower(tower_type: String, scene: PackedScene, cost: float) -> void:
	_tower_registry[tower_type] = {"scene": scene, "cost": cost}

func get_tower_info(tower_type: String) -> Dictionary:
	return _tower_registry.get(tower_type, {})

func clear_all_towers() -> void:
	"""Remove all placed towers. Called when player dies to reset."""
	print("[BuildingSystem] Clearing all towers (count=", _placed_towers.size(), ")")
	for tower in _placed_towers:
		if is_instance_valid(tower):
			tower.queue_free()
	_placed_towers.clear()
	_scrap = 150.0
