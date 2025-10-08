extends State
class_name IdleState

@export
var fall_state: State
@export
#will be deprecated
var jump_state: State
@export
var move_state: State
var locked_rotation_y: float

func enter() -> void:
	super()
	player.velocity.x = 0
	player.velocity.z = 0
	
	locked_rotation_y= player.visuals.global_rotation.y
	
func process_input(event: InputEvent) -> State:
	if Input.is_action_just_pressed("ui_accept") and player.is_on_floor():
		return jump_state
	if(
	Input.is_action_just_pressed("Left") or 
	Input.is_action_just_pressed("Right") or 
	Input.is_action_just_pressed("Forward") or 
	Input.is_action_just_pressed("Backward")
	):
		return move_state
	return null

func process_physics(delta: float) -> State:
	player.visuals.global_rotation.y = locked_rotation_y
	player.velocity += player.get_gravity() * delta
	player.move_and_slide()
	
	if !player.is_on_floor():
		return fall_state
	return null
	
