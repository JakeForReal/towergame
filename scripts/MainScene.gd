extends Node2D

## Main scene controller — shows start screen, then spawns player and starts the game.

@export var player_scene: PackedScene = preload("res://scenes/PlayerCharacter.tscn")

var _player: Node2D = null

func _ready() -> void:
	_show_start_screen()

func _show_start_screen() -> void:
	var start_screen = preload("res://scenes/StartScreen.tscn").instantiate()
	start_screen.started.connect(_on_start_screen_finished)
	add_child(start_screen)

func _on_start_screen_finished() -> void:
	_spawn_player()
	_start_game()

func _unhandled_input(event: InputEvent) -> void:
	print("[MainScene] unhandled input: ", event)
	if event is InputEventMouseButton:
		print("[MainScene] mouse button: idx=", event.button_index, " pressed=", event.pressed)
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var bs := get_node_or_null("/root/BuildingSystem")
			if bs:
				var pos: Vector2 = get_global_mouse_position()
				print("[MainScene] right-click at ", pos)
				bs.place_tower_at(pos)

func _spawn_player() -> void:
	var spawn_pos: Vector2 = Vector2(250, 0)  # Outside the 150px aura radius
	if has_node("PlayerSpawner"):
		spawn_pos = $PlayerSpawner.global_position
	_player = player_scene.instantiate()
	_player.global_position = spawn_pos
	add_child(_player)
	GameState.player = _player

func _start_game() -> void:
	GameState.start_run()
	
	# Connect buff aura signals → player
	var buff_aura = get_node_or_null("Base/BuffAura")
	if buff_aura and _player:
		buff_aura.player_buffed.connect(_player.apply_buff)
		buff_aura.player_regen.connect(_player.apply_regen_buff)
	# (HUD connects to player.buff_changed in its own _ready)
	
	await get_tree().create_timer(2.0, false).timeout
	var es = get_node_or_null("EnemySpawner")
	if es and es.has_method("start_spawning"):
		es.start_spawning()
	GameState.change_phase(GameState.GamePhase.WAVE_ACTIVE)
