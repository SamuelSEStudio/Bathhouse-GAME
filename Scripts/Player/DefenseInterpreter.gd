extends Node
class_name DefenceInterpreter

var just_requested_dodge: bool = false
var just_pressed_guard: bool = false
var wants_guard: bool = false

var guard_press_time: float = -1.0
var last_dodge_time: float = -1.0


func update_defence(_delta: float) -> void:
	just_requested_dodge = false
	just_pressed_guard = false

	if Input.is_action_just_pressed("Guard"):
		just_pressed_guard = true
		guard_press_time = Time.get_ticks_msec() * 0.001

	if Input.is_action_just_pressed("Dodge"):
		just_requested_dodge = true
		last_dodge_time = Time.get_ticks_msec() * 0.001

	wants_guard = Input.is_action_pressed("Guard")
