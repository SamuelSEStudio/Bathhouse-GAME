extends State
class_name AttackFrontKick

@export var combo_ref: ComboInput
@export var idle_state: State
@export var total_time: float = 1.20
var _t: float = 0.0


func enter(payload: Variant = null) -> void:
	_t = 0.0 
	super()

func process_physics(delta: float) -> State:
	player.velocity.x = 0.0
	player.velocity.z = 0.0
	# Keep gravity so we don’t “float”
	player.velocity += player.get_gravity() * delta
	player.move_and_slide()
	
	_t += delta
	if combo_ref and Input.is_action_just_pressed("Kick"):
		combo_ref.push_kick()  # make sure 'A' is in the buffer now
	if _t >= total_time:
		return idle_state
	return null
