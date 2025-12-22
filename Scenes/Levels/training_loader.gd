#extends Node
#class_name TrainingSession
#
#@export var continue_signal: StringName = &"training_continue"
#@export var stop_signal: StringName = &"training_stop"
#
#var _timer: Timer
#var _prompt_active: bool = false
#
#func _ready() -> void:
	#_timer = Timer.new()
	#_timer.one_shot = true
	#add_child(_timer)
	#_timer.timeout.connect(_on_timeout)
#
	#Dialogic.signal_event.connect(_on_dialogic_signal)
#
	#_restart()
#
#func _exit_tree() -> void:
	#if Dialogic.signal_event.is_connected(_on_dialogic_signal):
		#Dialogic.signal_event.disconnect(_on_dialogic_signal)
#
#func _restart() -> void:
	#_prompt_active = false
	#_timer.stop()
	#_timer.wait_time = TrainingFlow.prompt_every_sec
	#_timer.start()
#
#func _on_timeout() -> void:
	#if _prompt_active:
		#return
	#_prompt_active = true
	#Dialogic.start_timeline(String(TrainingFlow.keep_training_timeline))
#
#func _on_dialogic_signal(arg: Variant) -> void:
	#if !_prompt_active:
		#return
#
	#var key: StringName = StringName(str(arg))
#
	#if key == continue_signal:
		#_restart()
	#elif key == stop_signal:
		#_timer.stop()
		#_prompt_active = false
		#TrainingFlow.exit_training()
