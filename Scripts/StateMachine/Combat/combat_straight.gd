extends State
class_name AttackStraightState

@export var idle_state: State
@export var total_time: float = 0.38

var _t: float = 0.0

# Called when the node enters the scene tree for the first time.
func enter(payload: Variant = null) -> void:
	_t = 0.0
	super()


func process_physics(delta: float) -> State:
	player.velocity.x = 0.0
	player.velocity.z = 0.0
	player.velocity += player.get_gravity() * delta
	player.move_and_slide()

	_t += delta
	if _t >= total_time:
		return idle_state
	return null
