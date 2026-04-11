extends State
class_name PracticeGuardState

@export var idle_state: State
@export var forward_state: State
@export var backward_state: State
@export var sidestep_stateI: State
@export var sidestep_stateO: State
@export var fall_state: State

@export var depth_axis: Vector3 = Vector3.FORWARD
@export var combo_ref: ComboInput

@export var guard_move_speed: float = 1.5
@export var release_recovery_time: float = 0.05

var _release_timer: float = 0.0
var _releasing: bool = false
var _locked_rotation_y: float = 0.0
var _combatant: Combatant = null

func enter(payload: Variant = null) -> void:
	super(payload)
	_release_timer = 0.0
	_releasing = false

	# Stop any existing horizontal motion when entering guard
	_locked_rotation_y = player.visuals.global_rotation.y
	player.velocity.x = 0.0
	player.velocity.z = 0.0
	
	if _combatant == null:
		_combatant = player.get_node_or_null("Combatant") as Combatant
	if _combatant != null:
		_combatant.is_blocking = true

	# Optional: lock visuals to current facing
	# (in practice you already lock facing in some states)
	# var visuals: Node3D = (player as Player).visuals
	# visuals.global_rotation.y = visuals.global_rotation.y

	# Later we can flip Combatant.is_blocking = true here once wired


func exit() -> void:
	super()
	_releasing = false
	_release_timer = 0.0
	
	if _combatant != null:
		_combatant.is_blocking = false
	# Later: set Combatant.is_blocking = false here


func process_input(event: InputEvent) -> State:
	return null


func process_frame(delta: float) -> State:
	
	var left: bool = Input.is_action_pressed("Left")
	var right: bool = Input.is_action_pressed("Right")
	var fwd: bool = Input.is_action_pressed("Forward")
	var back: bool = Input.is_action_pressed("Backward")
	
	var has_lr: bool = left or right
	var has_fb: bool = fwd or back
	
	var p: Player = player as Player
	if p == null or p.defence == null:
		return null
		
	var d: DefenceInterpreter = p.defence
	
	# If the player has released Guard (wants_guard == false),
	# start a small recovery then drop back to movement / idle.
	if not d.wants_guard and not _releasing:
		_releasing = true
		_release_timer = release_recovery_time

	if _releasing:
		_release_timer -= delta
		if _release_timer <= 0.0:
			# Decide where to go based on current directional input
			if has_fb and (fwd != back):
				return sidestep_stateI if fwd else sidestep_stateO
			if has_lr and (left != right):
				return forward_state if right else backward_state
			else:
				return idle_state

	return null


func process_physics(delta: float) -> State:
	# Keep facing locked while in guard
	player.visuals.global_rotation.y = _locked_rotation_y

	if not _releasing:
		# --- Combat-style forward/back while guarding ---

		var p: Player = player as Player
		var dir: Vector3 = Vector3.ZERO

		if p != null and combo_ref != null:
			# Use the same "forward/back" interpretation as the combat system
			if combo_ref._is_forward_held():
				dir = depth_axis.normalized()
			elif combo_ref._is_back_held():
				dir = -depth_axis.normalized()

		if dir != Vector3.ZERO:
			player.velocity.x = dir.x * guard_move_speed
			player.velocity.z = dir.z * guard_move_speed
		else:
			# No combat forward/back input while guarding → stand still
			player.velocity.x = 0.0
			player.velocity.z = 0.0
	else:
		# During release recovery, no movement
		player.velocity.x = 0.0
		player.velocity.z = 0.0

	# Gravity + floor
	player.velocity += player.get_gravity() * delta
	player.move_and_slide()

	if not player.is_on_floor():
		return fall_state

	return null
