extends Node
class_name Hitstop

var _restorer: SceneTreeTimer

func apply(seconds: float = 0.06, slow_scale: float = 0.05) -> void:
	if _restorer != null and _restorer.time_left > 0.0:
		return # avoid stacking; tweak if you want additive
	# global slow
	Engine.time_scale = slow_scale
	_restorer = get_tree().create_timer(seconds, false)
	_restorer.timeout.connect(_restore)

func _restore() -> void:
	Engine.time_scale = 1.0
