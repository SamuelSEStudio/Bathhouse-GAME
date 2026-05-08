extends Control
class_name TrainingPromptUI

signal continued
signal stopped

@onready var yes_button: Button = $PanelContainer/VBoxContainer/HBoxContainer/YesButton
@onready var no_button: Button = $PanelContainer/VBoxContainer/HBoxContainer/NoButton


func _ready() -> void:
	yes_button.pressed.connect(_on_yes)
	no_button.pressed.connect(_on_no)

	# Keyboard/controller friendly
	yes_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		_on_no()

func _on_yes() -> void:
	continued.emit()
	queue_free()

func _on_no() -> void:
	stopped.emit()
	queue_free()
