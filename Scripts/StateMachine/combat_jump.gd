extends State

@export
var fall_state: State
@export
var idle_state: State
@export
var move_state: State
@export var speed: float = 4.0
@export
var jump_velocity: float = 15.0
@export var lock_visuals_y: bool = true
@export var depth_axis: Vector3 = Vector3.FORWARD #world forward
var _locked_y: float = 0.0

func enter(payload: Variant = null) -> void:
	super()
	player.velocity.y = jump_velocity

func process_physics(delta: float) -> State:
	player.velocity += player.get_gravity() * delta
	
	#parent.velocity.y = jump_velocity
	
	if player.velocity.y <= 0:
		return fall_state
	
	if lock_visuals_y:
		player.visuals.global_rotation.y = _locked_y
	#Forward only no diagonal movemnt zero X -> push strictly along depth 
	var dir: Vector3 = depth_axis.normalized()
	var horiz: Vector3 = Vector3(dir.x,0.0,dir.z)

	player.velocity.x = horiz.x * speed
	player.velocity.z = horiz.z * speed

	player.velocity+= player.get_gravity() * delta
	player.move_and_slide()
	
	# If landed, transition to Idle or Move
	#if parent.is_on_floor():
		#if direction != Vector3.ZERO:
			#return move_state
		#return idle_state
	
	return null
