extends Node
class_name ThugMidAIBrain

# =============================================================================
# References v0.1.1
# =============================================================================

@export var character: ThugMid
@export var target: Node3D
@export var depth_axis: Vector3 = Vector3.FORWARD


# =============================================================================
# AI update timing
# =============================================================================

@export var think_interval: float = 0.1


# =============================================================================
# Distance bands
# =============================================================================
# too_close_range:
# Enemy may try to step away.
#
# true_light_attack_range:
# Enemy only jabs when it is actually close enough.
#
# close_pressure_range:
# Enemy treats this as threatening close range, but may still need to creep in.
#
# hover_range_min / hover_range_max:
# Enemy tries to hang around this band instead of blindly walking forward.
#
# approaching_heavy_min_range / approaching_heavy_max_range:
# Enemy may occasionally use heavy_poke as a committed mid-range threat.

@export var too_close_range: float = 0.9
@export var true_light_attack_range: float = 1.2
@export var close_pressure_range: float = 1.6
@export var hover_range_min: float = 1.7
@export var hover_range_max: float = 2.7
@export var far_range: float = 4.2

@export var approaching_heavy_min_range: float = 1.8
@export var approaching_heavy_max_range: float = 4.2


# =============================================================================
# Behaviour toggles
# =============================================================================

@export var can_use_light_attack: bool = true
@export var can_use_heavy_attack: bool = true
@export var can_guard: bool = false
@export var can_dodge: bool = false


# =============================================================================
# Chance tuning
# =============================================================================

@export_range(0.0, 1.0, 0.01) var retreat_chance_too_close: float = 0.25
@export_range(0.0, 1.0, 0.01) var hover_hold_chance: float = 0.45
@export_range(0.0, 1.0, 0.01) var hover_creep_chance: float = 0.55
@export_range(0.0, 1.0, 0.01) var close_creep_chance: float = 0.8
@export_range(0.0, 1.0, 0.01) var approaching_heavy_chance: float = 0.35

# These are off by default for AI v0.1.
# They are here so this profile can be tuned later without rewriting the script.
@export_range(0.0, 1.0, 0.01) var guard_chance_close: float = 0.0
@export_range(0.0, 1.0, 0.01) var dodge_chance_close: float = 0.0


# =============================================================================
# Cooldowns / action pacing
# =============================================================================

@export var shared_action_cooldown: float = 0.55
@export var light_attack_cooldown: float = 0.9
@export var heavy_attack_cooldown: float = 2.2
@export var heavy_consider_interval: float = 0.45
@export var dodge_cooldown: float = 2.5

@export var guard_min_duration: float = 0.4
@export var guard_max_duration: float = 1.0


# =============================================================================
# Debug
# =============================================================================

@export var debug_ai: bool = false


# =============================================================================
# Runtime state
# =============================================================================

var _think_accum: float = 0.0
var _time_since_any_action: float = 999.0
var _time_since_light_attack: float = 999.0
var _time_since_heavy_attack: float = 999.0
var _time_since_heavy_consider: float = 999.0
var _time_since_dodge: float = 999.0
var _guard_timer: float = 0.0
var _last_debug_state: StringName = &""


func _ready() -> void:
	if character == null:
		character = owner as ThugMid

	_think(0.0)


func _physics_process(delta: float) -> void:
	if character == null:
		return

	match character.control_mode:
		ThugMid.ControlMode.PLAYER:
			return

		ThugMid.ControlMode.DUMMY_IDLE:
			_think_dummy_idle(delta)
			return

		ThugMid.ControlMode.DUMMY_BLOCK_ALL:
			_think_dummy_block_all(delta)
			return

		_:
			pass

	if target == null and character.combat_target == null:
		_stop_all_intent()
		return

	_update_timers(delta)

	if _think_accum < think_interval:
		return

	_think_accum = 0.0
	_think(delta)


func _update_timers(delta: float) -> void:
	_think_accum += delta
	_time_since_any_action += delta
	_time_since_light_attack += delta
	_time_since_heavy_attack += delta
	_time_since_heavy_consider += delta
	_time_since_dodge += delta

	_guard_timer -= delta
	if _guard_timer < 0.0:
		_guard_timer = 0.0


func _think(_delta: float) -> void:
	if character == null:
		return

	var target_node: Node3D = _get_target()
	if target_node == null:
		_stop_all_intent()
		return

	var to_target: Vector3 = target_node.global_transform.origin - character.global_transform.origin
	var lane_dir: Vector3 = _calculate_lane_dir(to_target)
	character.lane_axis = lane_dir

	var depth_distance: float = to_target.dot(lane_dir)
	var abs_depth: float = absf(depth_distance)

	var dir_toward_target: float = _get_dir_toward_target(depth_distance)
	var dir_away_from_target: float = -dir_toward_target

	if _try_continue_guard():
		return

	if _try_start_guard(abs_depth):
		return

	if abs_depth <= too_close_range:
		_handle_too_close(abs_depth, dir_away_from_target, dir_toward_target)
		return

	if abs_depth <= close_pressure_range:
		_handle_close_pressure(abs_depth, dir_toward_target)
		return

	if _is_in_approaching_heavy_range(abs_depth):
		if _try_approaching_heavy(abs_depth):
			return

	if abs_depth <= hover_range_max:
		_handle_hover(abs_depth, dir_toward_target)
		return

	_handle_far(abs_depth, dir_toward_target)


func _get_target() -> Node3D:
	if target != null:
		return target

	return character.combat_target


func _calculate_lane_dir(to_target: Vector3) -> Vector3:
	var lane_dir: Vector3 = Vector3(to_target.x, 0.0, to_target.z)

	if lane_dir.length_squared() >= 0.0001:
		return lane_dir.normalized()

	if character.lane_axis.length_squared() >= 0.0001:
		return character.lane_axis.normalized()

	if depth_axis.length_squared() >= 0.0001:
		return depth_axis.normalized()

	return Vector3.FORWARD


func _get_dir_toward_target(depth_distance: float) -> float:
	if depth_distance < 0.0:
		return -1.0

	return 1.0


func _handle_too_close(_abs_depth: float, dir_away_from_target: float, dir_toward_target: float) -> void:
	character.set_guarding(false)

	if _try_close_dodge():
		return

	if _try_light_attack(_abs_depth):
		return

	if randf() < retreat_chance_too_close:
		character.set_desired_lane_dir(dir_away_from_target)
		_debug_state(&"TOO_CLOSE_RETREAT")
		return

	character.set_desired_lane_dir(dir_toward_target)
	_debug_state(&"TOO_CLOSE_PRESSURE")


func _handle_close_pressure(abs_depth: float, dir_toward_target: float) -> void:
	character.set_guarding(false)

	if _try_light_attack(abs_depth):
		return

	# If close but not quite jab-close, keep pressure instead of freezing.
	if abs_depth > true_light_attack_range:
		character.set_desired_lane_dir(dir_toward_target)
		_debug_state(&"CLOSE_CREEP_TO_JAB_RANGE")
		return

	# If jab is on cooldown, mostly hold pressure, sometimes creep to avoid dead air.
	if randf() < close_creep_chance:
		character.set_desired_lane_dir(dir_toward_target)
		_debug_state(&"CLOSE_PRESSURE_CREEP")
		return

	character.set_desired_lane_dir(0.0)
	_debug_state(&"CLOSE_PRESSURE_HOLD")


func _handle_hover(_abs_depth: float, dir_toward_target: float) -> void:
	character.set_guarding(false)

	if randf() < hover_creep_chance:
		character.set_desired_lane_dir(dir_toward_target)
		_debug_state(&"HOVER_CREEP")
		return

	if randf() < hover_hold_chance:
		character.set_desired_lane_dir(0.0)
		_debug_state(&"HOVER_HOLD")
		return

	character.set_desired_lane_dir(dir_toward_target)
	_debug_state(&"HOVER_DEFAULT_PRESSURE")


func _handle_far(_abs_depth: float, dir_toward_target: float) -> void:
	character.set_guarding(false)
	character.set_desired_lane_dir(dir_toward_target)
	_debug_state(&"FAR_APPROACH")


func _try_light_attack(abs_depth: float) -> bool:
	if not can_use_light_attack:
		return false

	if abs_depth > true_light_attack_range:
		return false

	if _time_since_any_action < shared_action_cooldown:
		return false

	if _time_since_light_attack < light_attack_cooldown:
		return false

	character.set_guarding(false)
	character.set_desired_lane_dir(0.0)
	character.request_attack(&"fast_poke")

	_time_since_any_action = 0.0
	_time_since_light_attack = 0.0

	_debug_event(&"LIGHT_ATTACK")
	return true


func _is_in_approaching_heavy_range(abs_depth: float) -> bool:
	if abs_depth < approaching_heavy_min_range:
		return false

	if abs_depth > approaching_heavy_max_range:
		return false

	return true


func _try_approaching_heavy(abs_depth: float) -> bool:
	if not can_use_heavy_attack:
		return false

	if not _is_in_approaching_heavy_range(abs_depth):
		return false

	if _time_since_any_action < shared_action_cooldown:
		return false

	if _time_since_heavy_attack < heavy_attack_cooldown:
		return false

	if _time_since_heavy_consider < heavy_consider_interval:
		return false

	_time_since_heavy_consider = 0.0

	if randf() > approaching_heavy_chance:
		return false

	character.set_guarding(false)
	character.set_desired_lane_dir(0.0)
	character.request_attack(&"heavy_poke")

	_time_since_any_action = 0.0
	_time_since_heavy_attack = 0.0

	_debug_event(&"APPROACHING_HEAVY")
	return true


func _try_close_dodge() -> bool:
	if not can_dodge:
		return false

	if dodge_chance_close <= 0.0:
		return false

	if _time_since_any_action < shared_action_cooldown:
		return false

	if _time_since_dodge < dodge_cooldown:
		return false

	if randf() > dodge_chance_close:
		return false

	character.set_guarding(false)
	character.set_desired_lane_dir(0.0)
	character.request_attack(&"dodge")

	_time_since_any_action = 0.0
	_time_since_dodge = 0.0

	_debug_event(&"DODGE")
	return true


func _try_start_guard(abs_depth: float) -> bool:
	if not can_guard:
		return false

	if guard_chance_close <= 0.0:
		return false

	if abs_depth > close_pressure_range:
		return false

	if _guard_timer > 0.0:
		return false

	if randf() > guard_chance_close:
		return false

	character.set_desired_lane_dir(0.0)
	character.set_guarding(true)

	_guard_timer = randf_range(guard_min_duration, guard_max_duration)

	_debug_event(&"START_GUARD")
	return true


func _try_continue_guard() -> bool:
	if not can_guard:
		character.set_guarding(false)
		_guard_timer = 0.0
		return false

	if _guard_timer <= 0.0:
		character.set_guarding(false)
		return false

	character.set_desired_lane_dir(0.0)
	character.set_guarding(true)

	_debug_state(&"GUARDING")
	return true


func _stop_all_intent() -> void:
	character.set_desired_lane_dir(0.0)
	character.set_guarding(false)
	character.clear_attack_request()
	_debug_state(&"NO_TARGET")


func _think_dummy_idle(_delta: float) -> void:
	if character == null:
		return

	character.set_desired_lane_dir(0.0)
	character.set_guarding(false)
	character.clear_attack_request()
	_debug_state(&"DUMMY_IDLE")


func _think_dummy_block_all(_delta: float) -> void:
	if character == null:
		return

	character.set_desired_lane_dir(0.0)
	character.set_guarding(true)
	character.clear_attack_request()
	_debug_state(&"DUMMY_BLOCK_ALL")


func _debug_state(label: StringName) -> void:
	if not debug_ai:
		return

	if _last_debug_state == label:
		return

	_last_debug_state = label
	print("ThugMidAI state: ", label)


func _debug_event(label: StringName) -> void:
	if not debug_ai:
		return

	print("ThugMidAI event: ", label)
