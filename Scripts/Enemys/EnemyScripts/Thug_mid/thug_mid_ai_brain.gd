extends Node
class_name ThugMidAIBrain

@export var character: ThugMid
@export var target: Node3D                 # usually the player root
@export var depth_axis: Vector3 = Vector3.FORWARD

@export var think_interval: float = 0.1    # seconds between AI decisions
@export var close_range: float = 1.5       # stop when this close along the lane
@export var mid_range: float = 4.0         # optional, for later behaviours

# Behaviour tuning
@export var retreat_chance_close: float = 0.3        # chance to move back when very close
@export var min_time_between_actions: float = 1.0    # cooldown between attacks

@export var guard_chance_close: float = 0.4              # 0–1
@export var guard_min_duration: float = 0.4
@export var guard_max_duration: float = 1.0
var _guard_timer: float = 0.0

@export var jab_weight: float = 0.6
@export var heavy_weight: float = 0.4
@export var dodge_weight: float = 0.2

var _think_accum: float = 0.0
var _time_since_action: float = 0.0


func _ready() -> void:
	if character == null:
		character = owner as ThugMid

	# If target not set in inspector, you can add your own fallback here later
	# e.g. find player by group: get_tree().get_first_node_in_group("Player")

	# Start by thinking immediately once
	_think(0.0)


func _physics_process(delta: float) -> void:
	if character == null:
		return
		
	match character.control_mode:
		ThugMid.ControlMode.PLAYER:
			# AI off – player / someone else drives this character
			return

		ThugMid.ControlMode.DUMMY_IDLE:
			_think_dummy_idle(delta)
			return

		ThugMid.ControlMode.DUMMY_BLOCK_ALL:
			_think_dummy_block_all(delta)
			return
			
		# You can later split AI_PROFILE_1/2/3 if you want different behaviours
		ThugMid.ControlMode.AI_PROFILE_1, \
		ThugMid.ControlMode.AI_PROFILE_2, \
		ThugMid.ControlMode.AI_PROFILE_3:
			pass  # Fall through to normal AI below
			
	if target == null:
		return
		
	_think_accum += delta
	_time_since_action += delta
	_guard_timer -= delta
	if _guard_timer < 0.0:
		_guard_timer = 0.0
		
	if _think_accum < think_interval:
		return

	_think_accum = 0.0
	_think(delta)


func _think(_delta: float) -> void:
	if character == null:
		return

	# Decide which target we use: explicit export or character.combat_target
	var target_node: Node3D = target
	if target_node == null:
		target_node = character.combat_target
	if target_node == null:
		# No target – stand still
		character.set_desired_lane_dir(0.0)
		character.set_guarding(false)
		return

	# --- Compute dynamic lane axis from thug -> target ---

	var to_target: Vector3 = target_node.global_transform.origin - character.global_transform.origin
	var lane_dir: Vector3 = Vector3(to_target.x, 0.0, to_target.z)

	if lane_dir.length_squared() < 0.0001:
		# Fallback to previous lane_axis or depth_axis if we're on top of each other
		lane_dir = character.lane_axis
		if lane_dir.length_squared() < 0.0001:
			lane_dir = depth_axis
	else:
		lane_dir = lane_dir.normalized()

	# Store for states to use
	character.lane_axis = lane_dir

	# Positive if target is "forward" along lane_dir, negative if behind
	var depth_distance: float = to_target.dot(lane_dir)
	var abs_depth: float = absf(depth_distance)

	# --- Decide desired_lane_dir based on distance band ---

	if abs_depth > mid_range:
		# FAR: approach along lane toward the target
		var dir_scalar_far: float = 1.0
		if depth_distance < 0.0:
			dir_scalar_far = -1.0
		character.set_desired_lane_dir(dir_scalar_far)

	elif abs_depth < close_range:
		# CLOSE: sometimes retreat, sometimes hold ground
		var dir_scalar_close: float = 0.0

		if randf() < retreat_chance_close:
			# Move away from target along lane
			if depth_distance >= 0.0:
				dir_scalar_close = -1.0
			else:
				dir_scalar_close = 1.0

		character.set_desired_lane_dir(dir_scalar_close)

	else:
		# MID: approach
		var dir_scalar_mid: float = 1.0
		if depth_distance < 0.0:
			dir_scalar_mid = -1.0
		character.set_desired_lane_dir(dir_scalar_mid)
	
	# --- Guard decision when close ---
	var in_close_band: bool = abs_depth <= close_range
	
	if in_close_band:
		if not character.wants_guard and _guard_timer <= 0.0:
			# Decide whether to start guarding
			if randf() < guard_chance_close:
				character.set_guarding(true)
				_guard_timer = randf_range(guard_min_duration, guard_max_duration)
		else:
			# Already guarding; count down and release when timer is done
			if _guard_timer <= 0.0:
				character.set_guarding(false)
	else:
		# Out of close range: drop guard
		character.set_guarding(false)
		_guard_timer = 0.0

	# --- Attack decision when in CLOSE band ---

	if in_close_band and _time_since_action >= min_time_between_actions:
		var total_weight: float = jab_weight + heavy_weight + dodge_weight
		if total_weight > 0.0:
			var roll: float = randf() * total_weight

			if roll < jab_weight:
				character.request_attack(&"fast_poke")
			elif roll < jab_weight + heavy_weight:
				character.request_attack(&"heavy_poke")
			else:
				character.request_attack(&"dodge")

			_time_since_action = 0.0
			
func _think_dummy_idle(_delta: float) -> void:
	if character == null:
		return

	character.set_desired_lane_dir(0.0)
	character.set_guarding(false)
	character.clear_attack_request()


func _think_dummy_block_all(_delta: float) -> void:
	if character == null:
		return

	character.set_desired_lane_dir(0.0)
	character.set_guarding(true)
	character.clear_attack_request()
