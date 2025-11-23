extends State
class_name PracticeBackwardState

@export var idle_state: State
@export var forward_state: State
@export var sidestep_state: State
@export var fall_state: State
@export var guard_state: State
@export var dodge_state: State

@export var jab_state: State
@export var neutral_kick_state: State

@export var combo_ref: ComboInput
@export var speed: float = 4.0
@export var lock_visuals_y: bool = true
@export var depth_axis: Vector3 = Vector3.FORWARD

var _locked_y: float = 0.0

func enter(payload: Variant = null) -> void:
	super()
	_locked_y = player.visuals.global_rotation.y

func process_input(event: InputEvent) -> State:
	var left: bool = Input.is_action_pressed("Left")
	var right: bool = Input.is_action_pressed("Right")
	var fwd: bool = Input.is_action_pressed("Forward")
	var back: bool = Input.is_action_pressed("Backward")
	
	if Input.is_action_just_pressed("Punch"):
		if combo_ref:
			combo_ref.push_punch()
			var s := combo_ref.resolve_attack(&"P")
			if s != null:
				return s
		return jab_state
	if Input.is_action_just_pressed("Kick"):
		if combo_ref:
			combo_ref.push_kick()
			var s := combo_ref.resolve_attack(&"K")
			if s != null:
				return s
		return neutral_kick_state 

	if (fwd or back): return sidestep_state
	if right and !left:   return forward_state
	if !left:  return idle_state
	return null

func process_physics(delta: float) -> State:
	if lock_visuals_y:
		player.visuals.global_rotation.y = _locked_y

	# Backward only (no diagonal)
	var dir: Vector3 = (-depth_axis).normalized()
	var horiz: Vector3 = Vector3(dir.x, 0.0, dir.z)

	player.velocity.x = horiz.x * speed
	player.velocity.z = horiz.z * speed

	player.velocity += player.get_gravity() * delta
	player.move_and_slide()

	if !player.is_on_floor():
		return fall_state
	return null
	
func process_frame(delta: float) -> State:
	var p: Player = player as Player
	if p != null and p.defence != null:
		var d: DefenceInterpreter = p.defence
		
		if d.just_requested_dodge:
			d.just_requested_dodge = false
			return dodge_state

		if d.wants_guard:
			return guard_state

	return null
