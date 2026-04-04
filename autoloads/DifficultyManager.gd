extends Node

## Chronos Director — Difficulty Scaling System
## Tracks elapsed time and scales enemy difficulty dynamically.
## Difficulty Coefficient (C) = 1 + (Time * Map_Multiplier)

signal difficulty_changed(C: float)
signal milestone_reached(milestone: int)

var elapsed_time: float = 0.0
var difficulty_coefficient: float = 1.0
var current_credits: float = 0.0
var credits_per_second: float = 7.5
var map_multiplier: float = 0.05  # How fast difficulty scales

var _milestone_thresholds: Array[int] = [2, 5, 10, 15, 20, 30, 50]
var _reached_milestones: Array[int] = []

func _process(delta: float) -> void:
	elapsed_time += delta
	var new_C := 1.0 + (elapsed_time * map_multiplier)
	
	if new_C != difficulty_coefficient:
		difficulty_coefficient = new_C
		difficulty_changed.emit(difficulty_coefficient)
		_check_milestones()

	# Accumulate credits
	current_credits += credits_per_second * delta

func _check_milestones() -> void:
	for threshold in _milestone_thresholds:
		if difficulty_coefficient >= threshold and threshold not in _reached_milestones:
			_reached_milestones.append(threshold)
			milestone_reached.emit(threshold)

func spend_credits(amount: float) -> bool:
	if current_credits >= amount:
		current_credits -= amount
		return true
	return false

func get_credits() -> float:
	return current_credits

func get_difficulty() -> float:
	return difficulty_coefficient

func set_map_multiplier(m: float) -> void:
	map_multiplier = m

func reset() -> void:
	elapsed_time = 0.0
	difficulty_coefficient = 1.0
	current_credits = 0.0
	_reached_milestones.clear()
	difficulty_changed.emit(1.0)

## Enemy scaling helpers
func scale_hp(base_hp: float) -> float:
	return base_hp * difficulty_coefficient

func scale_damage(base_damage: float) -> float:
	return base_damage * difficulty_coefficient

## Get spawn weight for an enemy type based on difficulty
func get_spawn_weight(enemy_tier: int) -> float:
	# tier 0 = basic, tier 1 = medium, tier 2 = elite
	var base_weights: Array[float] = [1.0, 0.5, 0.0]
	var elite_unlock_at: Array[float] = [0.0, 2.0, 5.0, 10.0]
	
	if difficulty_coefficient >= elite_unlock_at[enemy_tier]:
		return base_weights[enemy_tier] * (1.0 + (difficulty_coefficient - elite_unlock_at[enemy_tier]) * 0.1)
	return 0.0
