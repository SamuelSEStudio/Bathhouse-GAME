extends Node
class_name DefenceInterpreter

## How long a press counts as a "tap" (dodge) instead of a hold (guard)
@export var tap_window: float = 0.20

## Internal button tracking
var _button_down: bool = false
var _time_held: float = 0.0

## Public outputs (what states read)
var just_requested_dodge: bool = false
var wants_guard: bool = false

func update_defence(delta: float) -> void:
	# Reset the one-frame flag each update
	#print("Defence: pressed=", Input.is_action_pressed("Guard"), 
	   #" time=", _time_held, 
	   #" dodge=", just_requested_dodge, 
	   #" guard=", wants_guard)
	just_requested_dodge = false

	var pressed: bool = Input.is_action_pressed("Guard")
	var just_pressed: bool = Input.is_action_just_pressed("Guard")
	var just_released: bool = Input.is_action_just_released("Guard")

	if just_pressed:
		_button_down = true
		_time_held = 0.0
		# when starting a new press, we don't yet know if it's a tap or hold
		wants_guard = false

	if _button_down:
		_time_held += delta

		# If we cross the tap window while still held, this becomes a "hold" → guard
		if _time_held >= tap_window and pressed:
			wants_guard = true

	if just_released and _button_down:
		# If we released before tap_window and never became a hold, this is a dodge tap
		if _time_held < tap_window and not wants_guard:
			just_requested_dodge = true

		_button_down = false
		_time_held = 0.0
		wants_guard = false
