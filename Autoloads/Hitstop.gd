extends Node
class_name Hitstop

var _restorer: SceneTreeTimer

func apply(seconds: float = 0.06, slow_scale: float = 0.05) -> void:
	# If a hitstop is already active, don't stack a new one
	if _restorer != null and _restorer.time_left > 0.0:
		return

	# Apply global slow
	Engine.time_scale = slow_scale

	# SceneTreeTimer uses *scaled* time, so we need to compensate.
	# We want 'seconds' of *real* time at 'slow_scale':
	#   scaled_time * (1 / slow_scale) = seconds
	#   → scaled_time = seconds * slow_scale
	var wait_time: float = seconds * slow_scale

	_restorer = get_tree().create_timer(wait_time, false)
	_restorer.timeout.connect(_restore)


func _restore() -> void:
	Engine.time_scale = 1.0
	_restorer = null
