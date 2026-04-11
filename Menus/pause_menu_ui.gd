extends Control
class_name PauseMenuUI

@export var pause_action: StringName = &"pause"

# Optional reset target: if set, Reset loads this scene.
@export var reset_scene: PackedScene

# Optional spawn-point reset: put a Marker3D at the start and add it to group "player_spawn"
@export var spawn_group: StringName = &"player_spawn"
@export var player_group: StringName = &"player"

@export var mouse_mode_in_game: Input.MouseMode = Input.MOUSE_MODE_CAPTURED
@export var mouse_mode_in_menu: Input.MouseMode = Input.MOUSE_MODE_VISIBLE

@onready var resume_button: Button = $PanelContainer/VBoxContainer/ResumeButton as Button
@onready var reset_button: Button = $PanelContainer/VBoxContainer/ResetButton as Button
@onready var exit_menu_button: Button = $PanelContainer/VBoxContainer/ExitMenuButton as Button
@onready var exit_game_button: Button = $PanelContainer/VBoxContainer/ExitGameButton as Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	resume_button.pressed.connect(_on_resume_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	exit_menu_button.pressed.connect(_on_exit_pressed)
	exit_game_button.pressed.connect(_on_exit_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(pause_action):
		get_viewport().set_input_as_handled()
		toggle_pause()


func toggle_pause() -> void:
	if get_tree().paused:
		resume_game()
	else:
		pause_game()


func pause_game() -> void:
	get_tree().paused = true
	visible = true
	Input.mouse_mode = mouse_mode_in_menu
	resume_button.grab_focus()


func resume_game() -> void:
	visible = false
	get_tree().paused = false
	Input.mouse_mode = mouse_mode_in_game


func _on_resume_pressed() -> void:
	resume_game()


func _on_reset_pressed() -> void:
	# Always unpause before resetting/changing scenes.
	resume_game()

	# Option A: If you set reset_scene in the inspector, load that (start-of-game scene).
	if reset_scene != null:
		get_tree().change_scene_to_packed(reset_scene)
		return

	## Option B: If you have a spawn marker in group "player_spawn", teleport player back.
	#var spawn: Node3D = get_tree().get_first_node_in_group(spawn_group) as Node3D
	#var player: Player = get_tree().get_first_node_in_group(player_group) as Player
	#if spawn != null and player != null:
		#player.global_transform = spawn.global_transform
		#player.velocity = Vector3.ZERO
		#return

	# Fallback: reload the current scene.
	get_tree().reload_current_scene()


func _on_exit_pressed() -> void:
	# For now, both "Exit to Menu" and "Exit Game" quit.
	get_tree().quit()
