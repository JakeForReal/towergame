extends CharacterBody2D

signal damaged(amount: float)
signal buff_changed(buff_type: String, stacks: int)

@export var move_speed: float = 176.0
@export var attack_cooldown: float = 0.56
@export var attack_damage: float = 20.0
@export var max_health: float = 80.0
@export var character_texture: Texture2D = null

var _attack_timer: float = 0.0
var _aim: Vector2 = Vector2.RIGHT
var _hp: float = 80.0
var _is_dead: bool = false
var _active_buffs: Dictionary = {}
var _invulnerable: bool = false
var _invulnerability_timer: float = 0.0
var _invulnerability_duration: float = 0.5  # Seconds of invincibility after being hit
var _regen_rate: float = 0.0  # HP per second from aura
var _regen_active: bool = false
var _shield_damage_reduction: float = 0.1  # 10% per shield item
var _firerate_item_count: int = 0
var _shield_item_count: int = 0
var _fire_rate_aura_stacks: int = 0
var _regen_aura_active: bool = false
var _regen_tick_timer: float = 0.0
var _projectile_range: float = 200.0  # Pixels — can be upgraded via items

func _ready() -> void:
	_hp = max_health  # Initialize HP from exported max
	add_to_group("player")
	_update_health_bar()  # Init the health bar above the character
	
	# Try to load sprite at runtime (works even if not indexed)
	var tex_path := "res://resources/characters/player_ranger_bg_removed.png"
	var f := FileAccess.file_exists(tex_path)
	print("Sprite file exists: ", f)
	var tex = load(tex_path) if f else null
	if tex:
		var sprite := Sprite2D.new()
		sprite.name = "PlayerSprite"
		sprite.texture = tex
		sprite.scale = Vector2(35.0 / 1024.0, 35.0 / 1024.0)
		sprite.centered = true
		add_child(sprite)
	elif character_texture:
		var sprite := Sprite2D.new()
		sprite.name = "PlayerSprite"
		sprite.texture = character_texture
		sprite.scale = Vector2(35.0 / 1024.0, 35.0 / 1024.0)
		sprite.centered = true
		add_child(sprite)
	else:
		var visual := Polygon2D.new()
		visual.name = "Visual"
		visual.color = Color(0.2, 0.8, 1.0)
		var r: float = 12.6
		var pts := PackedVector2Array()
		for i in range(16):
			var a := TAU * i / 16.0
			pts.append(Vector2(cos(a) * r, sin(a) * r))
		visual.polygon = pts
		add_child(visual)

func _physics_process(delta: float) -> void:
	if _is_dead:
		return
	
	# Tick invulnerability
	if _invulnerable:
		_invulnerability_timer -= delta
		if _invulnerability_timer <= 0:
			_invulnerable = false
	
	# Tick health regen from aura
	if _regen_active and _regen_rate > 0:
		_hp = min(max_health, _hp + _regen_rate * delta)
		_update_health_bar()
		_regen_tick_timer -= delta
		if _regen_tick_timer <= 0:
			_regen_tick_timer = 1.0
			_spawn_heal_number(_regen_rate)
	
	# Movement: keyboard or left stick (uses input map deadzone)
	var move_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if move_input.length() > 0.0:
		velocity = move_input * move_speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	
	# Clamp player to map bounds
	var half := GameState.MAP_HALF_SIZE
	global_position.x = clamp(global_position.x, -half, half)
	global_position.y = clamp(global_position.y, -half, half)
	
	# Aiming: right stick (via input map) or mouse
	var aim_input := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	if aim_input.length() > 0.15:  # Right stick active — use gamepad aim
		_aim = aim_input.normalized()
	else:
		# Fall back to mouse
		_aim = (get_global_mouse_position() - global_position).normalized()
	
	_attack_timer -= delta
	if Input.is_action_pressed("attack") and _attack_timer <= 0:
		# Apply fire_rate buffs: aura (flat %) + item pickups (stacking)
		var cooldown := attack_cooldown
		var aura_val: float = _active_buffs.get("fire_rate_aura", 0.0) as float
		aura_val += _active_buffs.get("fire_rate", 0.0) as float  # BuffAuraComponent uses this key
		var item_val: int = _active_buffs.get("firerate_item", 0) as int
		# Aura: 0.25 per stack; items: 0.10 per stack, capped effect
		cooldown *= (1.0 - aura_val - 0.10 * mini(item_val, 3))
		_attack_timer = cooldown
		_shoot()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		print("[Player] mouse button: index=", event.button_index, " pressed=", event.pressed)
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_place_tower()

func _place_tower() -> void:
	print("[Player] _place_tower called")
	var bs := get_node_or_null("/root/BuildingSystem")
	if bs:
		print("[Player] calling place_tower_at at ", get_global_mouse_position())
		bs.place_tower_at(get_global_mouse_position())
	else:
		print("[Player] BuildingSystem not found")

func _shoot() -> void:
	var scene: PackedScene = preload("res://scenes/Projectile.tscn")
	var proj = scene.instantiate()
	proj.global_position = global_position + _aim * 20.0
	proj.launch(_aim, attack_damage, _projectile_range)
	get_tree().current_scene.add_child(proj)
	print("[Player] _shoot: proj at ", proj.global_position)

func take_damage(amount: float) -> void:
	if _is_dead or _invulnerable:
		return
	var final_damage := amount * (1.0 - _shield_damage_reduction)
	_hp -= final_damage
	_invulnerable = true
	_invulnerability_timer = _invulnerability_duration
	damaged.emit(final_damage)
	_update_health_bar()
	_spawn_damage_number(final_damage)
	print("Player took ", final_damage, " damage! HP: ", _hp, " (reduction: ", _shield_damage_reduction, ")")
	if _hp <= 0:
		_is_dead = true
		# Clear all placed turrets before reloading
		var bs = get_node_or_null("/root/BuildingSystem")
		if bs and bs.has_method("clear_all_towers"):
			bs.clear_all_towers()
		get_tree().reload_current_scene()

func apply_damage(amount: float) -> void:
	take_damage(amount)

func apply_buff(buff_type: String, active: bool) -> void:
	if active:
		_active_buffs[buff_type] = 0.25  # 25% cooldown reduction
	else:
		_active_buffs.erase(buff_type)
	buff_changed.emit(buff_type, 1 if active else 0)

func apply_fire_rate_aura(stacks: int) -> void:
	_fire_rate_aura_stacks = stacks
	buff_changed.emit("fire_rate_aura", stacks)

func apply_regen_buff(_buff_type: String, active: bool) -> void:
	_regen_active = active
	if active:
		_regen_rate = 5.0  # HP per second from aura
	else:
		_regen_rate = 0.0
		_regen_tick_timer = 0.0
	buff_changed.emit("regen", 1 if active else 0)

func apply_item(item_type: String) -> bool:
	print("[Player] apply_item called: ", item_type)
	match item_type:
		"firerate":
			_firerate_item_count += 1
			_active_buffs["firerate_item"] = _firerate_item_count
			print("[Player] emitting firerate_item stacks=", _firerate_item_count)
			buff_changed.emit("firerate_item", _firerate_item_count)
			return true
		"shield":
			_shield_item_count += 1
			_active_buffs["shield_item"] = _shield_item_count
			_shield_damage_reduction = 0.10 * mini(float(_shield_item_count), 10.0)
			print("[Player] emitting shield_item stacks=", _shield_item_count)
			buff_changed.emit("shield_item", _shield_item_count)
			return true
	print("[Player] apply_item: no match for ", item_type)
	return false

func get_health_component() -> Node:
	return null

var current_hp: float:
	get: return _hp

var projectile_range: float:
	get: return _projectile_range

func _update_health_bar() -> void:
	var bar := get_node_or_null("HealthBar") as ProgressBar
	if bar:
		bar.max_value = max_health
		bar.value = _hp
		if _hp / max_health <= 0.30:
			bar.modulate = Color(1.0, 0.2, 0.2, 1.0)
		else:
			bar.modulate = Color(0.2, 1.0, 0.3, 1.0)

func _spawn_damage_number(amount: float) -> void:
	var label := Label.new()
	label.name = "DamageNumber"
	label.text = "-%.0f" % amount
	label.global_position = global_position + Vector2(randf_range(-20.0, 20.0), -30.0)
	label.modulate = Color(1.0, 0.2, 0.2, 1.0)
	label.add_theme_font_size_override("font_size", 16)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	get_tree().current_scene.add_child(label)

	var tween := create_tween()
	tween.tween_property(label, "position:y", label.global_position.y - 40.0, 1.0)
	tween.tween_property(label, "modulate:a", 0.0, 1.0)
	await tween.finished
	label.queue_free()

func _spawn_heal_number(amount: float) -> void:
	var label := Label.new()
	label.name = "HealNumber"
	label.text = "+%.0f" % amount
	label.global_position = global_position + Vector2(randf_range(-20.0, 20.0), -30.0)
	label.modulate = Color(0.2, 1.0, 0.3, 1.0)
	label.add_theme_font_size_override("font_size", 16)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	get_tree().current_scene.add_child(label)

	var tween := create_tween()
	tween.tween_property(label, "position:y", label.global_position.y - 40.0, 1.0)
	tween.tween_property(label, "modulate:a", 0.0, 1.0)
	await tween.finished
	label.queue_free()
