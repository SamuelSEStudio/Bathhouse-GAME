extends State
class_name EnemyPracticeForwardState

@export var idle_state: State
@export var backwards_state: State
@export var fall_state: State

@export var speed: float = 4.0
@export var lock_visuals_y: bool = true
@export var depth_axis: Vector3 = Vector3.FORWARD # lane direction in world space

var _locked_y: float = 0.0


func enter(payload: Variant = null) -> void:
	# Play the forward-walk animation defined by animation_name on this State
	super(payload)

	if lock_visuals_y:
		_locked_y = player.visuals.global_rotation.y


func process_physics(delta: float) -> State:
	# Ensure visuals keep their facing if we lock Y
	if lock_visuals_y:
		player.visuals.global_rotation.y = _locked_y

	# Cast the generic player reference to our ThugMid type
	var thug: ThugMid = player as ThugMid
	if thug == null:
		# Failsafe: if this isn't a ThugMid for some reason, just go idle
		return idle_state

	# Read AI intent: positive = forward, zero/negative = stop or switch
	var dir_scalar: float = thug.desired_lane_dir

	# No longer wants to move forward
	if dir_scalar <= 0.0:
		# If AI is actively asking to move back, and we have a backwards_state, go there
		if dir_scalar < -0.01 and backwards_state != null:
			return backwards_state
		# Otherwise, stop and go idle
		player.velocity.x = 0.0
		player.velocity.z = 0.0
		return idle_state

	# --- Move forward along the lane ---

	# Use lane/depth axis, ignore Y
	var dir: Vector3 = depth_axis.normalized()
	var horiz: Vector3 = Vector3(dir.x, 0.0, dir.z)

	player.velocity.x = horiz.x * speed
	player.velocity.z = horiz.z * speed

	# Apply gravity & slide
	player.velocity += player.get_gravity() * delta
	player.move_and_slide()

	# If we walk off a ledge, transition to fall
	if not player.is_on_floor():
		return fall_state

	return null
