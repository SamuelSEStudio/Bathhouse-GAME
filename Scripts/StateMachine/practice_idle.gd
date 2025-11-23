extends State
class_name PracticeIdleState

@export var forward_state: State
@export var backward_state: State
@export var sidestep_stateI: State
@export var sidestep_stateO: State
@export var dodge_state: State
@export var guard_state: State
@export var jump_state: State
@export var jab_state: State
@export var fall_state: State
@export var combo_ref: ComboInput
@export var straight_state: State
@export var neutral_kick_state: State

var _locked_rotation_y := 0.0

func enter(payload: Variant = null) -> void:
	super()
	_locked_rotation_y = player.visuals.global_rotation.y
	player.velocity.x = 0
	player.velocity.z = 0
	

func process_input(event: InputEvent) -> State:
	
	var left: bool = Input.is_action_pressed("Left")
	var right: bool = Input.is_action_pressed("Right")
	var fwd: bool = Input.is_action_pressed("Forward")
	var back: bool = Input.is_action_pressed("Backward")
	var punch: bool = Input.is_action_just_pressed("Punch")
	var kick: bool = Input.is_action_just_pressed("Kick")
	
	var has_lr: bool = left or right
	var has_fb: bool = fwd or back
	if punch:
		combo_ref.push_punch()
		return combo_ref.resolve_attack(&"P")
	if kick:
		combo_ref.push_kick()
		return combo_ref.resolve_attack(&"K")
	if Input.is_action_just_pressed("ui_accept") and player.is_on_floor():
		return jump_state
	#if Input.is_action_just_pressed("Guard"):
		#return dodge_state
	#if punch:
		#if combo_ref:
			#combo_ref.push_punch()  # ensure A is recorded now
			##var ok: bool = combo_ref.match([&"F",&"F",&"A"],combo_ref.tap_grace * 2.0)
			##if combo_ref.match([&"F",&"F",&"A"], combo_ref.tap_grace * 2.0):
			#var next: State = combo_ref.resolve_attack()
			#if next != null:
				#return next
			##print ("idle resolver: FFA match=", ok)
			##if ok:
				##combo_ref.clear_recent(combo_ref.tap_grace * 2.0)
				##return straight_state
		#return jab_state
	
		# No diagonals allowed: if both axes are down, prefer sidestep
	if has_fb and (fwd != back):
		return sidestep_stateI if fwd else sidestep_stateO
	if has_lr and (left != right):
		return forward_state if right else backward_state
	return null
	

func process_physics(delta: float) -> State:
	player.visuals.global_rotation.y = _locked_rotation_y
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
