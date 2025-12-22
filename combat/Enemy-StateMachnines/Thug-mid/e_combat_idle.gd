extends State
class_name EnemyPracticeIdleState

@export var forward_state: State
@export var back_state: State
@export var fall_state: State
@export var attack_light_state: State  
@export var attack_heavy_state: State
@export var guard_state: State
@export var dodge_state: State

var _locked_rotation_y: float = 0.0


func enter(payload: Variant = null) -> void:
	# Play idle animation via base State
	super(payload)
	_locked_rotation_y = player.visuals.global_rotation.y
	player.velocity.x = 0.0
	player.velocity.z = 0.0


func process_physics(delta: float) -> State:
	# Keep visuals facing locked direction
	player.visuals.global_rotation.y = _locked_rotation_y

	# Basic gravity & floor check (same as your other states)
	player.velocity += player.get_gravity() * delta
	player.move_and_slide()

	if not player.is_on_floor():
		return fall_state

	# --- AI intent → which move state? ---
	var thug: ThugMid = player as ThugMid
	if thug == null:
		return null
	
		# --- 1) Guard has highest priority ---
	if thug.wants_guard and guard_state != null:
		return guard_state
		
	if thug.pending_attack_role == &"dodge" and dodge_state != null:
		thug.clear_attack_request()
		return dodge_state
		
	# --- 2) Heavy attack first (rarer, higher priority) ---
	if thug.pending_attack_role == &"heavy_poke" and attack_heavy_state != null:
		thug.clear_attack_request()
		return attack_heavy_state

	# --- 3) ---Light Attack----
	if thug.pending_attack_role == &"fast_poke" and attack_light_state != null:
		thug.clear_attack_request()
		return attack_light_state
#---movement if no attack required---
	var dir_scalar: float = thug.desired_lane_dir

	if dir_scalar > 0.01 and forward_state != null:
		return forward_state

	if dir_scalar < -0.01 and back_state != null:
		return back_state

	return null
