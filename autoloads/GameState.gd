extends Node

## Global game state manager
## Handles game phases, player data, currency, and run management

signal phase_changed(phase: GamePhase)
signal scrap_changed(amount: float)
signal game_over(victory: bool)
signal map_cleared(map_num: int)

enum GamePhase {
	MENU,
	BUILD_PHASE,
	WAVE_ACTIVE,
	PAUSED,
	GAME_OVER,
	VICTORY
}

const MAP_HALF_SIZE: float = 2250.0  # 50% larger than original 1500

var current_phase: GamePhase = GamePhase.MENU
var current_map: int = 1
var total_maps: int = 5
var player_scrap: float = 150.0
var base_health: float = 100.0
var base_max_health: float = 100.0
var base_upgrade_level: int = 1

var player: Node2D = null
var is_run_active: bool = false

func _ready() -> void:
	# Connect to difficulty manager
	var dm = get_node_or_null("/root/DifficultyManager")
	if dm:
		dm.difficulty_changed.connect(_on_difficulty_changed)

func start_run() -> void:
	is_run_active = true
	player_scrap = 150.0
	base_health = base_max_health
	current_map = 1
	DifficultyManager.reset()
	change_phase(GamePhase.BUILD_PHASE)

func change_phase(new_phase: GamePhase) -> void:
	current_phase = new_phase
	phase_changed.emit(new_phase)

func add_scrap(amount: float) -> void:
	player_scrap += amount
	scrap_changed.emit(player_scrap)

func spend_scrap(amount: float) -> bool:
	if player_scrap >= amount:
		player_scrap -= amount
		scrap_changed.emit(player_scrap)
		return true
	return false

func damage_base(amount: float) -> void:
	base_health = max(0.0, base_health - amount)
	if base_health <= 0:
		end_run(false)

func heal_base(amount: float) -> void:
	base_health = min(base_max_health, base_health + amount)

func upgrade_base() -> void:
	if player_scrap >= get_base_upgrade_cost():
		spend_scrap(get_base_upgrade_cost())
		base_upgrade_level += 1
		base_max_health += 25.0
		base_health = base_max_health

func get_base_upgrade_cost() -> float:
	return 50.0 * base_upgrade_level

func end_run(victory: bool) -> void:
	is_run_active = false
	change_phase(GamePhase.GAME_OVER)
	game_over.emit(victory)

func victory() -> void:
	is_run_active = false
	change_phase(GamePhase.VICTORY)
	game_over.emit(true)

func advance_map() -> void:
	if current_map < total_maps:
		current_map += 1
		map_cleared.emit(current_map - 1)
		change_phase(GamePhase.BUILD_PHASE)
		# Reset difficulty timer for new map
		DifficultyManager.reset()
		DifficultyManager.map_multiplier = 0.05 * current_map  # Harder each map
	else:
		change_phase(GamePhase.VICTORY)
		game_over.emit(true)

func pause_game() -> void:
	if current_phase == GamePhase.BUILD_PHASE or current_phase == GamePhase.WAVE_ACTIVE:
		change_phase(GamePhase.PAUSED)

func resume_game() -> void:
	if current_phase == GamePhase.PAUSED:
		change_phase(GamePhase.WAVE_ACTIVE)

func _on_difficulty_changed(C: float) -> void:
	# Could trigger events at certain C values
	pass
