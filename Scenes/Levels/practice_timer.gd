extends Node
class_name TrainingSession

@export_range(5.0, 1800.0, 1.0)
var prompt_every_sec: float = 60.0
@export_range(1, 20, 1)
var max_sessions: int = 3

@export var forced_exit_timeline: StringName = &"Training_TooLong"

var _sessions_completed: int = 0
var _forcing_exit: bool = false

@export var prompt_ui_scene: PackedScene

var _timer: Timer
var _prompt: TrainingPromptUI
var _prompt_active: bool = false


func _ready() -> void:
	_sessions_completed = 0
	_forcing_exit = false
	_timer = Timer.new()
	_timer.one_shot = true
	add_child(_timer)
	_timer.timeout.connect(_on_timeout)

	_restart_timer()

func _restart_timer() -> void:
	_prompt_active = false
	_timer.stop()
	_timer.wait_time = prompt_every_sec
	_timer.start()

func _on_timeout() -> void:
	if _prompt_active:
		return
	_prompt_active = true
	_show_prompt()

func _show_prompt() -> void:
	if prompt_ui_scene == null:
		push_warning("TrainingSession: prompt_ui_scene not set.")
		_prompt_active = false
		_restart_timer()
		return

	_prompt = prompt_ui_scene.instantiate() as TrainingPromptUI
	if _prompt == null:
		push_warning("TrainingSession: prompt_ui_scene is not TrainingPromptUI.")
		_prompt_active = false
		_restart_timer()
		return

	get_tree().current_scene.add_child(_prompt)

	# Optional: freeze gameplay while prompt is open
	_set_gameplay_frozen(true)

	_prompt.continued.connect(_on_prompt_continue)
	_prompt.stopped.connect(_on_prompt_stop)

func _on_prompt_continue() -> void:
	# We count "Yes" as completing a session block and starting the next one.
	_sessions_completed += 1

	# If they've already done 3 and try to do more -> force exit with Dialogic.
	if _sessions_completed > max_sessions:
		await _force_exit_with_dialogic()
		return

	_set_gameplay_frozen(false)
	_prompt_active = false
	_restart_timer()
	
func _on_prompt_stop() -> void:
	_set_gameplay_frozen(false)
	_prompt_active = false
	_timer.stop()
	TrainingFlow.exit_training()

func _force_exit_with_dialogic() -> void:
	if _forcing_exit:
		return
	_forcing_exit = true

	# Keep input locked while we talk + exit
	_set_gameplay_frozen(true)
	_prompt_active = false
	_timer.stop()

	if forced_exit_timeline != &"":
		Dialogic.start_timeline(String(forced_exit_timeline))
		await Dialogic.timeline_ended

	TrainingFlow.exit_training()
	
func _set_gameplay_frozen(frozen: bool) -> void:
	var p: Player = get_tree().get_first_node_in_group("player") as Player
	if p == null:
		return

	if frozen:
		p.lock_input()
	else:
		p.unlock_input()
