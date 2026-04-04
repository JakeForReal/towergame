extends Node2D

## Start screen — displays controls and waits for any key press to begin.

signal started()

var _started := false
var _blink_timer := 0.0
var _prompt_visible := true

@onready var _prompt_label: Label = $CanvasLayer/VBox/PromptLabel

func _ready() -> void:
	_blink_timer = 0.0
	_prompt_visible = true

func _process(delta: float) -> void:
	_blink_timer += delta
	if _blink_timer >= 0.6:
		_blink_timer = 0.0
		_prompt_visible = not _prompt_visible
		_prompt_label.visible = _prompt_visible

func _unhandled_input(event: InputEvent) -> void:
	if _started:
		return
	if event is InputEventKey and event.pressed:
		_started = true
		started.emit()
		queue_free()
