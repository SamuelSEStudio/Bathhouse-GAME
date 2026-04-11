extends State

@export var jump_state: State
@export var idle_state: State
@export var walk_speed: float = 3.0
@export var run_speed: float = 5.0
  # default, can switch to "running" dynamically
@onready var default_cam: Camera3D = $"../../../Camera_mount/Default_cam"

func process_input(event: InputEvent) -> State:
	# Jump input
	if Input.is_action_just_pressed("ui_accept") and player.is_on_floor():
		return jump_state
	return null

func process_physics(delta: float) -> State:
	# Determine speed
	var running := Input.is_action_pressed("Run")
	var speed := move_speed
	if running:
		speed = run_speed
		if player.animation_player.current_animation != "running":
			player.animation_player.current_animation = "running"
	else:
		if player.animation_player.current_animation != "walking":
			player.animation_player.current_animation = "walking"

	# Get input direction
	var input_dir := Input.get_vector("Left", "Right", "Forward", "Backward")
	#get camera forward and right vectors 
	var cam_forward = default_cam.global_transform.basis.z
	cam_forward.y = 0
	cam_forward = cam_forward.normalized()
	
	var cam_right = default_cam.global_transform.basis.x
	cam_right.y = 0
	cam_right = cam_right.normalized()
	#previous code
	#var direction := (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var direction:= (cam_right*input_dir.x + cam_forward*input_dir.y).normalized()

	# Horizontal movement
	player.velocity.x = direction.x * speed
	player.velocity.z = direction.z * speed

	# Move the player
	player.move_and_slide()

	# Rotate visuals to face movement
	if direction != Vector3.ZERO:
		# Rotate visuals to face movement
		player.visuals.look_at(player.position + direction)

	# Transition to idle if no input
	if direction == Vector3.ZERO:
		return idle_state

	# Apply gravity while moving
	player.velocity += player.get_gravity() * delta

	return null
