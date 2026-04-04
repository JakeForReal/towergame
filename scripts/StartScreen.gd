## Start screen — displays controls and waits for any key press to begin.

signal started()

@onready var _controls_label: Label = $CanvasLayer/ControlsLabel
@onready var _prompt_label: Label = $CanvasLayer/PromptLabel

var _started := false

func _ready() -> void:
	_display_controls()
	_prompt_label.add_theme_font_size_override("font_size", 24)

func _display_controls() -> void:
	var text := "
	TOWERGAME
	========================================

	WASD / Arrow Keys     Move / Aim
	Left Click            Attack
	Right Click           Ability
	B                    Build Mode
	ESC                   Pause

	========================================
	"
	_controls_label.text = text

func _unhandled_input(event: InputEvent) -> void:
	if _started:
		return
	if event is InputEventKey and event.pressed:
		_started = true
		started.emit()
		queue_free()
