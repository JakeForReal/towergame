extends CanvasLayer

var _scrap_label: Label
var _wave_label: Label
var _game_over_panel: Panel
var _buff_label: Label
var _timer_label: Label
var _stats_label: Label
# buff_type -> count (int). Used for both stacking items and aura presence.
var _active_buffs: Dictionary = {}
var _can_place_tower: bool = true
var _game_time: float = 0.0

var _player_connected: bool = false
var _right_was_down: bool = false

func _ready() -> void:
	_scrap_label = get_node_or_null("ScrapPanel/Label")
	_wave_label = get_node_or_null("WaveLabel")
	_game_over_panel = get_node_or_null("GameOverPanel")
	_buff_label = get_node_or_null("BuffLabel")
	_timer_label = get_node_or_null("TimerLabel")
	_stats_label = get_node_or_null("StatsPanel/StatsLabel")

	print("[HUD] _buff_label = ", _buff_label)
	print("[HUD] _buff_label text = ", _buff_label.text if _buff_label else "NULL")
	print("[HUD] _buff_label parent = ", _buff_label.get_parent() if _buff_label else "NULL")

	# Don't try to connect here — _process will poll until player exists
	print("HUD ready")

func _process(_delta: float) -> void:
	if not _player_connected:
		var player = get_node_or_null("/root/Main/PlayerCharacter")
		if player:
			_player_connected = true
			player.buff_changed.connect(_on_buff_changed)
			print("[HUD] Connected to player buff_changed. Player: ", player.name)

	# Right-click is now handled in _unhandled_input
	# (debug tracking still runs)
	var right_down := Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	if right_down and not _right_was_down:
		print("[HUD] RIGHT CLICK PRESSED")
	if not right_down and _right_was_down:
		print("[HUD] RIGHT CLICK RELEASED")
	_right_was_down = right_down

	if not _game_over_panel or not _game_over_panel.visible:
		_game_time += _delta
	_update_display()

	if Input.is_action_just_pressed("restart"):
		restart_game()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		print("[HUD] _input got RIGHT CLICK, pressed=", event.pressed)
	# DEBUG: press K to simulate picking up a fire rate item
	if event is InputEventKey and event.pressed and event.keycode == KEY_K:
		print("[HUD] DEBUG: K pressed — manually adding fire_rate_item")
		_active_buffs["firerate_item"] = 1
		_update_buff_display()
	# DEBUG: press L to simulate picking up a shield item
	if event is InputEventKey and event.pressed and event.keycode == KEY_L:
		print("[HUD] DEBUG: L pressed — manually adding shield_item")
		_active_buffs["shield_item"] = 1
		_update_buff_display()
	# DEBUG: press J to clear all buffs
	if event is InputEventKey and event.pressed and event.keycode == KEY_J:
		print("[HUD] DEBUG: J pressed — clearing buffs")
		_active_buffs.clear()
		_update_buff_display()

	# Right-click to place tower
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		var bs = get_node_or_null("/root/BuildingSystem")
		if bs:
			var main = get_node_or_null("/root/Main")
			var pos: Vector2 = main.get_global_mouse_position() if main else Vector2.ZERO
			print("[HUD] right-click placing tower at ", pos)
			bs.place_tower_at(pos)

func _update_display() -> void:
	var gs = get_node_or_null("/root/GameState")
	if gs:
		if _scrap_label:
			_scrap_label.text = "SCRAP: %.0f" % gs.player_scrap
		if _wave_label:
			_wave_label.text = "MAP %d" % gs.current_map
		if _game_over_panel:
			var is_over: bool = gs.current_phase == GameState.GamePhase.GAME_OVER or gs.current_phase == GameState.GamePhase.VICTORY
			_game_over_panel.visible = is_over
			# Update label text for victory vs game over
			var game_over_label := _game_over_panel.get_node("GameOverLabel") as Label
			if game_over_label:
				if gs.current_phase == GameState.GamePhase.VICTORY:
					game_over_label.text = "VICTORY!"
				else:
					game_over_label.text = "GAME OVER"
	
	_update_stats_display()
	if _timer_label:
		var mins := int(_game_time / 60.0)
		var secs := int(fmod(_game_time, 60.0))
		_timer_label.text = "%02d:%02d" % [mins, secs]

func on_buff_changed(buff_type: String, value: Variant) -> void:
	_on_buff_changed(buff_type, value)

func _on_buff_changed(buff_type: String, stacks: int) -> void:
	print("[HUD] _on_buff_changed: bt=", buff_type, " stacks=", stacks)
	if stacks > 0:
		_active_buffs[buff_type] = stacks
	else:
		_active_buffs.erase(buff_type)
	_update_buff_display()

func _update_buff_display() -> void:
	print("[HUD] _update_buff_display: _active_buffs=", _active_buffs)
	if not _buff_label:
		print("[HUD] _buff_label is null!")
		return
	if _active_buffs.is_empty():
		# Don't hide — keep label visible so TEST BUFF LINE shows
		_buff_label.text = "(no buffs)"
		return
	_buff_label.visible = true
	var lines: Array[String] = []

	# Item: fire rate (stacking)
	if "firerate_item" in _active_buffs:
		var count_i: int = _active_buffs["firerate_item"]
		lines.append("🟠 +10%% FIRE RATE x%d" % count_i)

	# Aura: fire rate (from tower range)
	if "fire_rate_aura" in _active_buffs:
		lines.append("⚡ TOWER FIRE RATE AURA")

	# Item: shield (stacking)
	if "shield_item" in _active_buffs:
		var count_s: int = _active_buffs["shield_item"]
		lines.append("🔵 SHIELD 10%% x%d" % count_s)

	# Aura: fire rate (binary — on or off, from tower range aura)
	if "fire_rate_aura" in _active_buffs:
		lines.append("⚡ TOWER FIRE RATE AURA")
	# Aura: fire rate from BuffAuraComponent (map buff zones)
	if "fire_rate" in _active_buffs:
		lines.append("⚡ BUFF ZONE FIRE RATE")

	# Regen (binary — on or off)
	if "regen" in _active_buffs:
		lines.append("❤ +5 HP/S REGEN")

	_buff_label.text = "\n".join(lines)
	print("[HUD] Set buff label to: ", _buff_label.text)

func restart_game() -> void:
	_game_time = 0.0
	get_tree().reload_current_scene()

func _update_stats_display() -> void:
	if not _stats_label:
		return
	var player_node = get_node_or_null("/root/Main/PlayerCharacter")
	if not player_node:
		_stats_label.text = "STATS\n------\nHP:       ---\nFIRE RT:  ---\nSHIELD:   ---\nDMG:      ---\nRANGE:    ---"
		return

	var cb: CharacterBody2D = player_node as CharacterBody2D

	var hp_val: float = cb.current_hp
	var max_hp_val: float = cb.max_health
	var cooldown_val: float = cb.attack_cooldown
	var dmg_val: float = cb.attack_damage
	var range_val: float = cb.projectile_range
	var shield_count: int = cb._shield_item_count

	var shield_pct: float = float(shield_count) * 10.0

	var buff_reduction: float = 0.0
	var buffs: Dictionary = cb._active_buffs
	if buffs.has("fire_rate_aura"):
		buff_reduction += float(buffs.get("fire_rate_aura"))
	buff_reduction += buffs.get("fire_rate", 0.0) as float  # BuffAuraComponent
	if buffs.has("firerate_item"):
		buff_reduction += 0.10 * mini(int(buffs.get("firerate_item")), 3)

	var effective_cooldown: float = cooldown_val * (1.0 - buff_reduction)
	var fire_rate_val: float = 1.0 / effective_cooldown if effective_cooldown > 0.0 else 0.0

	var line_hp: String = "HP:       %.0f / %.0f" % [hp_val, max_hp_val]
	var line_fr: String = "FIRE RT:  %.1f /s" % fire_rate_val
	var line_sh: String = "SHIELD:   %.0f%%" % shield_pct
	var line_dm: String = "DMG:      %.0f" % dmg_val
	var line_rng: String = "RANGE:    %.0f" % range_val

	var new_text: String = "STATS\n------\n" + line_hp + "\n" + line_fr + "\n" + line_sh + "\n" + line_dm + "\n" + line_rng
	if _stats_label.text != new_text:
		_stats_label.text = new_text
		print("[HUD] stats updated: shield=", shield_count, " fire_rate=", fire_rate_val)
