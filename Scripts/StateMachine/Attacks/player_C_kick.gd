extends State
class_name AttackKickState

@export var idle_state: State
@export var straight_state: State
@export var cancel_open_at: float = 0.12
@export var cancel_close_at: float = 0.32
@export var total_time: float = 0.32
@export var combo_ref: ComboInput

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
	
	if combo_ref and _t >= cancel_open_at and _t <= cancel_close_at:
		if combo_ref.match([&"F", &"F", &"P"], combo_ref.tap_grace * 2.0):
			combo_ref.clear_recent(combo_ref.tap_grace * 2.0)
			return straight_state
	
	if _t >= total_time:
		return idle_state
	return null
