extends State

@export
var fall_state: State
@export
var idle_state: State
@export
var move_state: State

@export
var jump_velocity: float = 4.5

func enter(payload: Variant = null) -> void:
	super()
	player.velocity.y = jump_velocity

func process_physics(delta: float) -> State:
	player.velocity += player.get_gravity() * delta
	
	#parent.velocity.y = jump_velocity
	
	if player.velocity.y <= 0:
		return fall_state
	
	var input_dir := Input.get_vector("Left","Right","Forward","Backward")
	var direction :=(player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Apply horizontal movement
	player.velocity.x = direction.x * move_speed
	player.velocity.z = direction.z * move_speed
	
	# Move character
	player.move_and_slide()
	
	# If landed, transition to Idle or Move
	#if parent.is_on_floor():
		#if direction != Vector3.ZERO:
			#return move_state
		#return idle_state
	
	return null
