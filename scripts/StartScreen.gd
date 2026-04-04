extends Node2D

## Start screen — displays controls and waits for any key press to begin.

signal started()

var _started := false
var _blink_timer := 0.0

@onready var _prompt_label: Label = $CanvasLayer/VBox/PromptLabel

func _process(delta: float) -> void:
	if _started:
		return
	_blink_timer += delta * 2.5
	var alpha := (sin(_blink_timer) + 1.0) * 0.5
	_prompt_label.modulate.a = alpha

func _unhandled_input(event: InputEvent) -> void:
	if _started:
		return
	if event is InputEventKey and event.pressed:
		_started = true
		started.emit()
		queue_free()
