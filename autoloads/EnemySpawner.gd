extends Node
## EnemySpawner — Uses the Chronos Director's credits to spawn enemies.
## Weighted spawn table with scaling.

signal enemy_spawned(enemy: Node2D)
signal wave_intensity_changed(intensity: float)

@export var enabled: bool = false

# Enemy scenes (to be set in editor or programmatically)
@export var grunt_scene: PackedScene
@export var swarmer_scene: PackedScene
@export var tank_scene: PackedScene
@export var boss_scene: PackedScene
@export var shooter_scene: PackedScene

# Spawn rate
var spawn_interval: float = 0.7
var _spawn_timer: float = 0.0
var _active_enemies: Array[Node2D] = []
var _max_enemies_on_screen: int = 90
var _elapsed_time: float = 0.0
var _spawn_ramp: float = 0.1  # Interval reduction per minute
var _boss_spawn_timer: float = 60.0  # First boss at 60s
var _boss_spawn_interval: float = 60.0  # Boss every 60s after
var _shooter_timer: float = 0.0
var _shooter_interval: float = 1.4  # Twice as slow as grunts

func _ready() -> void:
	DifficultyManager.reset()

func _process(delta: float) -> void:
	if not enabled:
		return
	
	_elapsed_time += delta
	var minutes := int(_elapsed_time / 60.0)
	
	# Boss spawning on timer
	_boss_spawn_timer -= delta
	if _boss_spawn_timer <= 0 and boss_scene:
		_spawn_boss()
		_boss_spawn_timer = _boss_spawn_interval
	
	# Shooter spawning — independent timer at half the grunt rate
	_shooter_timer -= delta
	if _shooter_timer <= 0 and shooter_scene and _active_enemies.size() < _max_enemies_on_screen:
		_spawn_shooter()
		var shooter_interval_ramped: float = maxf(0.3, _shooter_interval + (minutes * 0.05))
		_shooter_timer = shooter_interval_ramped / DifficultyManager.get_difficulty()
	
	# Linear ramp: reduce interval by _spawn_ramp every 60 seconds
	var ramped_interval: float = maxf(0.15, spawn_interval - (minutes * _spawn_ramp))
	var effective_interval: float = ramped_interval / DifficultyManager.get_difficulty()
	
	_spawn_timer -= delta
	if _spawn_timer <= 0 and _active_enemies.size() < _max_enemies_on_screen:
		_try_spawn()
		_spawn_timer = effective_interval

func _try_spawn() -> void:
	# Spend credits to spawn from weighted table
	var credits := DifficultyManager.get_credits()
	
	# Build weighted list based on difficulty
	var candidates: Array[Dictionary] = []
	
	# Basic grunt (always available)
	candidates.append({"scene": grunt_scene, "weight": 1.0, "cost": 10.0, "tier": 0})
	
	# Swarmers (unlock early)
	if DifficultyManager.get_spawn_weight(0) > 0:
		candidates.append({"scene": swarmer_scene, "weight": 0.8, "cost": 5.0, "tier": 0})
	
	# Tanks (unlock at higher difficulty)
	if DifficultyManager.get_spawn_weight(1) > 0:
		candidates.append({"scene": tank_scene, "weight": 0.3, "cost": 25.0, "tier": 1})
	
	# Select weighted random
	var total_weight := 0.0
	for c in candidates:
		total_weight += c["weight"] * DifficultyManager.get_spawn_weight(c["tier"])
	
	var roll := randf() * total_weight
	var selected: Dictionary = candidates[0]
	var cum_weight := 0.0
	for c in candidates:
		cum_weight += c["weight"] * DifficultyManager.get_spawn_weight(c["tier"])
		if roll <= cum_weight:
			selected = c
			break
	
	if credits >= selected["cost"]:
		DifficultyManager.spend_credits(selected["cost"])
		_spawn_enemy(selected["scene"])

func _spawn_enemy(scene: PackedScene) -> void:
	if not scene:
		return
	
	var enemy: Node2D = scene.instantiate()
	
	# Spawn at random map edge
	var spawn_pos := _get_spawn_position()
	enemy.global_position = spawn_pos
	
	# Apply difficulty scaling
	if enemy.has_method("apply_scaling"):
		enemy.apply_scaling(DifficultyManager.get_difficulty())
	
	enemy.tree_exited.connect(_on_enemy_removed.bind(enemy))
	_active_enemies.append(enemy)
	
	get_parent().add_child(enemy)
	enemy_spawned.emit(enemy)

func _get_spawn_position() -> Vector2:
	var base_pos := Vector2.ZERO
	var angle := randf() * TAU
	var distance := 800.0 + randf() * 200.0
	return base_pos + Vector2.from_angle(angle) * distance

func _on_enemy_removed(enemy: Node2D) -> void:
	_active_enemies.erase(enemy)

func get_active_count() -> int:
	return _active_enemies.size()

func _spawn_boss() -> void:
	if not boss_scene:
		return
	var enemy = boss_scene.instantiate()
	# Spawn at least 2000px away (4+ screen lengths)
	var angle := randf() * TAU
	var distance := 2000.0 + randf() * 500.0
	enemy.global_position = Vector2.from_angle(angle) * distance
	if enemy.has_method("apply_scaling"):
		enemy.apply_scaling(DifficultyManager.get_difficulty() * 1.5)
	enemy.tree_exited.connect(_on_enemy_removed.bind(enemy))
	_active_enemies.append(enemy)
	get_parent().add_child(enemy)
	# Connect boss kill to victory
	if enemy.has_signal("boss_killed"):
		enemy.boss_killed.connect(_on_boss_killed)
	print("[Spawner] Boss spawned at ", enemy.global_position)
	enemy_spawned.emit(enemy)

func _on_boss_killed() -> void:
	print("[Spawner] Boss killed! Triggering victory.")
	GameState.victory()

func _spawn_shooter() -> void:
	if not shooter_scene:
		return
	var enemy: Node2D = shooter_scene.instantiate()
	var spawn_pos := _get_spawn_position()
	enemy.global_position = spawn_pos
	if enemy.has_method("apply_scaling"):
		enemy.apply_scaling(DifficultyManager.get_difficulty())
	enemy.tree_exited.connect(_on_enemy_removed.bind(enemy))
	_active_enemies.append(enemy)
	get_parent().add_child(enemy)
	enemy_spawned.emit(enemy)

func start_spawning() -> void:
	_elapsed_time = 0.0
	_boss_spawn_timer = _boss_spawn_interval
	_shooter_timer = _shooter_interval  # Start timer instead of spawning immediately
	enabled = true

func stop_spawning() -> void:
	enabled = false
