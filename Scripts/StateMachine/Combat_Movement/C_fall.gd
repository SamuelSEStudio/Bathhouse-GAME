extends State
@export
var move_state: State
@export
var idle_state: State

func process_physics(delta: float) -> State:
	# Apply gravity
	player.velocity += player.get_gravity() * delta

	# Apply horizontal movement input while falling
	var input_dir := Input.get_vector("Left", "Right", "Forward", "Backward")
	var direction := (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	player.velocity.x = direction.x * move_speed
	player.velocity.z = direction.z * move_speed

	# Move the player
	player.move_and_slide()

	# Check landing
	if player.is_on_floor():
		if direction != Vector3.ZERO:
			return move_state
		else:
			return idle_state

	return null
