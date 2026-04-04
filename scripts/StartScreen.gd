extends Node2D

## Start screen — displays controls and waits for any key press to begin.

signal started()

var _started := false

func _ready() -> void:
	_display_controls()

func _display_controls() -> void:
	var controls_label = $CanvasLayer/ControlsLabel
	var text := "
	TOWERGAME
	========================================

	WASD / Arrow Keys     Move / Aim
	Left Click            Attack
	Right Click           Ability
	B                     Build Mode
	ESC                    Pause

	========================================
	"
	controls_label.text = text

func _unhandled_input(event: InputEvent) -> void:
	if _started:
		return
	if event is InputEventKey and event.pressed:
		_started = true
		started.emit()
		queue_free()
