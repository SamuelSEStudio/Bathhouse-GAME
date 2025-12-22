extends State
class_name EnemyPracticeBackState

@export var idle_state: State
@export var forward_state: State
@export var fall_state: State

@export var speed: float = 4.0
@export var lock_visuals_y: bool = true
@export var depth_axis: Vector3 = Vector3.FORWARD # lane direction in world space

var _locked_y: float = 0.0


func enter(payload: Variant = null) -> void:
	super(payload)

	if lock_visuals_y:
		_locked_y = player.visuals.global_rotation.y


func process_physics(delta: float) -> State:
	if lock_visuals_y:
		player.visuals.global_rotation.y = _locked_y

	var thug: ThugMid = player as ThugMid
	if thug == null:
		return idle_state

	var dir_scalar: float = thug.desired_lane_dir

	# No longer wants to move back
	if dir_scalar >= 0.0:
		# If AI is now pushing forward and we have a forward_state, switch
		if dir_scalar > 0.01 and forward_state != null:
			return forward_state
		# Otherwise stop and idle
		player.velocity.x = 0.0
		player.velocity.z = 0.0
		return idle_state

	# --- Move backwards along the lane ---

	# dir_scalar is negative, so this naturally flips direction
	var dir: Vector3 = -depth_axis.normalized()
	var horiz: Vector3 = Vector3(dir.x, 0.0, dir.z)

	player.velocity.x = horiz.x * speed
	player.velocity.z = horiz.z * speed

	player.velocity += player.get_gravity() * delta
	player.move_and_slide()

	if not player.is_on_floor():
		return fall_state

	return null
