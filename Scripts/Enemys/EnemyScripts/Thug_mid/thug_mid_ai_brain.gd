extends Node
class_name ThugMidAIBrain


# =============================================================================
# References
# =============================================================================

@export_group("References")
@export var character: ThugMid
@export var target: Node3D
@export var profile: ThugAIProfile
@export var depth_axis: Vector3 = Vector3.FORWARD


# =============================================================================
# AI Update
# =============================================================================

@export_group("AI Update")
@export var think_interval: float = 0.1


# =============================================================================
# Fallback Values
# =============================================================================
# These are used if no ThugAIProfile resource is assigned.
# If a profile exists, _apply_profile() copies the profile values into these.

@export_group("Fallback Values")
@export var too_close_range: float = 0.9
@export var true_light_attack_range: float = 1.2
@export var close_pressure_range: float = 1.6
@export var hover_range_min: float = 1.7
@export var hover_range_max: float = 2.7
@export var far_range: float = 4.2
@export var approaching_heavy_min_range: float = 1.8
@export var approaching_heavy_max_range: float = 4.2

@export var can_use_light_attack: bool = true
@export var can_use_heavy_attack: bool = true
@export var can_backstep: bool = true
@export var can_guard: bool = true
@export var can_dodge: bool = false
@export var can_use_pressure_strings: bool = true

@export_range(0.0, 1.0, 0.01) var retreat_chance_too_close: float = 0.15
@export_range(0.0, 1.0, 0.01) var backstep_chance_too_close: float = 0.25
@export_range(0.0, 1.0, 0.01) var hover_hold_chance: float = 0.45
@export_range(0.0, 1.0, 0.01) var hover_creep_chance: float = 0.55
@export_range(0.0, 1.0, 0.01) var close_creep_chance: float = 0.8
@export_range(0.0, 1.0, 0.01) var approaching_heavy_chance: float = 0.35
@export_range(0.0, 1.0, 0.01) var backstep_chance_after_light: float = 0.18
@export_range(0.0, 1.0, 0.01) var backstep_chance_after_heavy: float = 0.35
@export_range(0.0, 1.0, 0.01) var guard_chance_close: float = 0.10
@export_range(0.0, 1.0, 0.01) var dodge_chance_close: float = 0.0

@export var shared_action_cooldown: float = 0.55
@export var light_attack_cooldown: float = 0.9
@export var heavy_attack_cooldown: float = 2.2
@export var heavy_consider_interval: float = 0.45
@export var dodge_cooldown: float = 2.5

@export var backstep_cooldown: float = 1.6
@export var backstep_duration: float = 0.45
@export var post_light_backstep_delay: float = 0.55
@export var post_heavy_backstep_delay: float = 0.9

@export var guard_min_duration: float = 0.35
@export var guard_max_duration: float = 0.75


# =============================================================================
# Pressure Strings
# =============================================================================

@export_group("Pressure Strings")
@export_range(0.0, 1.0, 0.01) var pressure_string_chance_close: float = 0.22

@export_range(0.0, 10.0, 0.01) var double_light_weight: float = 0.75
@export_range(0.0, 10.0, 0.01) var light_heavy_weight: float = 0.25

@export var pressure_string_cooldown: float = 2.2
@export var pressure_string_step_delay: float = 0.55
@export var pressure_string_cancel_range: float = 2.2

@export_range(0.0, 1.0, 0.01) var backstep_chance_after_string: float = 0.25
@export var post_string_backstep_delay: float = 0.65

# =============================================================================
# Encounter Coordination
# =============================================================================

@export_group("Encounter Coordination")
@export var use_attack_permission: bool = true
@export var light_attack_lock_duration: float = 0.75
@export var heavy_attack_lock_duration: float = 1.05
@export var dodge_lock_duration: float = 0.8
@export var pressure_string_extra_lock_duration: float = 0.65


# =============================================================================
# Debug
# =============================================================================

@export_group("Debug")
@export var debug_ai: bool = false


# =============================================================================
# Runtime State
# =============================================================================

var _think_accum: float = 0.0

var _time_since_any_action: float = 999.0
var _time_since_light_attack: float = 999.0
var _time_since_heavy_attack: float = 999.0
var _time_since_heavy_consider: float = 999.0
var _time_since_dodge: float = 999.0
var _time_since_backstep: float = 999.0
var _time_since_pressure_string: float = 999.0

var _guard_timer: float = 0.0

var _backstep_timer: float = 0.0
var _backstep_dir: float = 0.0

var _pending_post_attack_backstep: bool = false
var _pending_post_attack_backstep_timer: float = 0.0
var _pending_post_attack_backstep_dir: float = 0.0

var _pressure_string_active: bool = false
var _pressure_string_roles: Array[StringName] = []
var _pressure_string_index: int = 0
var _pressure_string_timer: float = 0.0
var _pressure_string_backstep_dir: float = 0.0

var _last_debug_state: StringName = &""


# =============================================================================
# Lifecycle
# =============================================================================

func _ready() -> void:
	if character == null:
		character = owner as ThugMid

	_apply_profile()
	_think(0.0)


func _physics_process(delta: float) -> void:
	if character == null:
		return

	match character.control_mode:
		ThugMid.ControlMode.PLAYER:
			return

		ThugMid.ControlMode.DUMMY_IDLE:
			_think_dummy_idle()
			return

		ThugMid.ControlMode.DUMMY_BLOCK_ALL:
			_think_dummy_block_all()
			return

		ThugMid.ControlMode.DUMMY_BLOCK_SECOND_HIT:
			# Placeholder for a future testing profile.
			# For now, treat it like dummy block.
			_think_dummy_block_all()
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


# =============================================================================
# Profile
# =============================================================================

func _apply_profile() -> void:
	if profile == null:
		return

	too_close_range = profile.too_close_range
	true_light_attack_range = profile.true_light_attack_range
	close_pressure_range = profile.close_pressure_range
	hover_range_min = profile.hover_range_min
	hover_range_max = profile.hover_range_max
	far_range = profile.far_range
	approaching_heavy_min_range = profile.approaching_heavy_min_range
	approaching_heavy_max_range = profile.approaching_heavy_max_range

	can_use_light_attack = profile.can_use_light_attack
	can_use_heavy_attack = profile.can_use_heavy_attack
	can_backstep = profile.can_backstep
	can_guard = profile.can_guard
	can_dodge = profile.can_dodge
	can_use_pressure_strings = profile.can_use_pressure_strings

	retreat_chance_too_close = profile.retreat_chance_too_close
	backstep_chance_too_close = profile.backstep_chance_too_close
	hover_hold_chance = profile.hover_hold_chance
	hover_creep_chance = profile.hover_creep_chance
	close_creep_chance = profile.close_creep_chance
	approaching_heavy_chance = profile.approaching_heavy_chance
	backstep_chance_after_light = profile.backstep_chance_after_light
	backstep_chance_after_heavy = profile.backstep_chance_after_heavy
	guard_chance_close = profile.guard_chance_close
	dodge_chance_close = profile.dodge_chance_close

	shared_action_cooldown = profile.shared_action_cooldown
	light_attack_cooldown = profile.light_attack_cooldown
	heavy_attack_cooldown = profile.heavy_attack_cooldown
	heavy_consider_interval = profile.heavy_consider_interval
	dodge_cooldown = profile.dodge_cooldown

	backstep_cooldown = profile.backstep_cooldown
	backstep_duration = profile.backstep_duration
	post_light_backstep_delay = profile.post_light_backstep_delay
	post_heavy_backstep_delay = profile.post_heavy_backstep_delay

	guard_min_duration = profile.guard_min_duration
	guard_max_duration = profile.guard_max_duration

	pressure_string_chance_close = profile.pressure_string_chance_close
	double_light_weight = profile.double_light_weight
	light_heavy_weight = profile.light_heavy_weight
	pressure_string_cooldown = profile.pressure_string_cooldown
	pressure_string_step_delay = profile.pressure_string_step_delay
	pressure_string_cancel_range = profile.pressure_string_cancel_range
	backstep_chance_after_string = profile.backstep_chance_after_string
	post_string_backstep_delay = profile.post_string_backstep_delay


# =============================================================================
# Main Thinking
# =============================================================================

func _update_timers(delta: float) -> void:
	_think_accum += delta

	_time_since_any_action += delta
	_time_since_light_attack += delta
	_time_since_heavy_attack += delta
	_time_since_heavy_consider += delta
	_time_since_dodge += delta
	_time_since_backstep += delta
	_time_since_pressure_string += delta

	_guard_timer = maxf(_guard_timer - delta, 0.0)
	_backstep_timer = maxf(_backstep_timer - delta, 0.0)
	_pressure_string_timer = maxf(_pressure_string_timer - delta, 0.0)

	if _pending_post_attack_backstep:
		_pending_post_attack_backstep_timer -= delta


func _think(_delta: float) -> void:
	var target_node: Node3D = _get_target()
	if target_node == null:
		_stop_all_intent()
		return

	var to_target: Vector3 = target_node.global_position - character.global_position
	var lane_dir: Vector3 = _calculate_lane_dir(to_target)
	character.lane_axis = lane_dir

	var depth_distance: float = to_target.dot(lane_dir)
	var abs_depth: float = absf(depth_distance)
	var dir_toward_target: float = _get_dir_toward_target(depth_distance)
	var dir_away_from_target: float = -dir_toward_target

	if _try_continue_backstep():
		return

	if _try_continue_pressure_string(abs_depth):
		return

	if _try_start_pending_post_attack_backstep():
		return

	if _try_continue_guard():
		return

	if _try_start_guard(abs_depth):
		return

	if abs_depth <= too_close_range:
		_handle_too_close(abs_depth, dir_away_from_target, dir_toward_target)
		return

	if abs_depth <= close_pressure_range:
		_handle_close_pressure(abs_depth, dir_toward_target, dir_away_from_target)
		return

	if _is_in_approaching_heavy_range(abs_depth):
		if _try_approaching_heavy(abs_depth, dir_away_from_target):
			return

	if abs_depth <= hover_range_max:
		_handle_hover(dir_toward_target)
		return

	_handle_far(dir_toward_target)


# =============================================================================
# Target / Lane Helpers
# =============================================================================

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


# =============================================================================
# Distance Behaviour
# =============================================================================

func _handle_too_close(abs_depth: float, dir_away_from_target: float, dir_toward_target: float) -> void:
	character.set_guarding(false)

	if _try_close_dodge():
		return

	if _try_start_backstep(dir_away_from_target, backstep_chance_too_close, &"TOO_CLOSE_BACKSTEP"):
		return

	if _try_light_attack(abs_depth, dir_away_from_target):
		return

	if randf() < retreat_chance_too_close:
		character.set_desired_lane_dir(dir_away_from_target)
		_debug_state(&"TOO_CLOSE_RETREAT")
		return

	character.set_desired_lane_dir(dir_toward_target)
	_debug_state(&"TOO_CLOSE_PRESSURE")


func _handle_close_pressure(abs_depth: float, dir_toward_target: float, dir_away_from_target: float) -> void:
	character.set_guarding(false)

	if _try_start_pressure_string(abs_depth, dir_away_from_target):
		return

	if _try_light_attack(abs_depth, dir_away_from_target):
		return

	if abs_depth > true_light_attack_range:
		character.set_desired_lane_dir(dir_toward_target)
		_debug_state(&"CLOSE_CREEP_TO_JAB_RANGE")
		return

	if randf() < close_creep_chance:
		character.set_desired_lane_dir(dir_toward_target)
		_debug_state(&"CLOSE_PRESSURE_CREEP")
		return

	character.set_desired_lane_dir(0.0)
	_debug_state(&"CLOSE_PRESSURE_HOLD")


func _handle_hover(dir_toward_target: float) -> void:
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


func _handle_far(dir_toward_target: float) -> void:
	character.set_guarding(false)
	character.set_desired_lane_dir(dir_toward_target)
	_debug_state(&"FAR_APPROACH")


# =============================================================================
# Single Attacks
# =============================================================================

func _try_light_attack(abs_depth: float, dir_away_from_target: float) -> bool:
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

	if not _request_permitted_attack(&"fast_poke", light_attack_lock_duration):
		return false

	_time_since_any_action = 0.0
	_time_since_light_attack = 0.0

	_maybe_queue_post_attack_backstep(
		dir_away_from_target,
		backstep_chance_after_light,
		post_light_backstep_delay
	)

	_debug_event(&"LIGHT_ATTACK")
	return true


func _is_in_approaching_heavy_range(abs_depth: float) -> bool:
	return abs_depth >= approaching_heavy_min_range and abs_depth <= approaching_heavy_max_range


func _try_approaching_heavy(abs_depth: float, dir_away_from_target: float) -> bool:
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

	if not _request_permitted_attack(&"heavy_poke", heavy_attack_lock_duration):
		return false

	_time_since_any_action = 0.0
	_time_since_heavy_attack = 0.0

	_maybe_queue_post_attack_backstep(
		dir_away_from_target,
		backstep_chance_after_heavy,
		post_heavy_backstep_delay
	)

	_debug_event(&"APPROACHING_HEAVY")
	return true

func _request_permitted_attack(role: StringName, lock_duration: float = -1.0) -> bool:
	if character == null:
		return false

	if use_attack_permission:
		if not character.request_attack_permission(role, lock_duration):
			_debug_event(&"ATTACK_PERMISSION_DENIED")
			return false

	character.request_attack(role)
	return true


func _request_pressure_string_permission(roles: Array[StringName]) -> bool:
	if character == null:
		return false

	if not use_attack_permission:
		return true

	var lock_duration: float = _get_pressure_string_lock_duration(roles)

	if not character.request_attack_permission(&"pressure_string", lock_duration):
		_debug_event(&"PRESSURE_STRING_PERMISSION_DENIED")
		return false

	return true


func _get_pressure_string_lock_duration(roles: Array[StringName]) -> float:
	var step_count: int = maxi(roles.size(), 1)
	return pressure_string_step_delay * float(step_count) + pressure_string_extra_lock_duration


func _get_attack_lock_duration(role: StringName) -> float:
	match role:
		&"fast_poke":
			return light_attack_lock_duration

		&"heavy_poke":
			return heavy_attack_lock_duration

		&"dodge":
			return dodge_lock_duration

	return -1.0
# =============================================================================
# Pressure Strings
# =============================================================================

func _try_start_pressure_string(abs_depth: float, dir_away_from_target: float) -> bool:
	if not can_use_pressure_strings:
		return false

	if _pressure_string_active:
		return false

	if abs_depth > true_light_attack_range:
		return false

	if _time_since_pressure_string < pressure_string_cooldown:
		return false

	if _time_since_any_action < shared_action_cooldown:
		return false

	if randf() > pressure_string_chance_close:
		return false

	var roles: Array[StringName] = _choose_pressure_string_roles()
	if roles.is_empty():
		return false

	_start_pressure_string(roles, dir_away_from_target)
	return true


func _choose_pressure_string_roles() -> Array[StringName]:
	var roles: Array[StringName] = []

	var safe_double_light_weight: float = maxf(double_light_weight, 0.0)
	var safe_light_heavy_weight: float = maxf(light_heavy_weight, 0.0)
	var total_weight: float = safe_double_light_weight + safe_light_heavy_weight

	if total_weight <= 0.0:
		return roles

	var roll: float = randf() * total_weight

	if roll <= safe_double_light_weight:
		roles.append(&"fast_poke")
		roles.append(&"fast_poke")
		return roles

	roles.append(&"fast_poke")
	roles.append(&"heavy_poke")
	return roles


func _start_pressure_string(roles: Array[StringName], dir_away_from_target: float) -> void:
	if not _request_pressure_string_permission(roles):
		_clear_pressure_string()
		return

	_pressure_string_active = true
	_pressure_string_roles = roles.duplicate()
	_pressure_string_index = 0
	_pressure_string_timer = 0.0
	_pressure_string_backstep_dir = dir_away_from_target

	_debug_event(&"PRESSURE_STRING_START")
	_request_next_pressure_string_step()

func _try_continue_pressure_string(abs_depth: float) -> bool:
	if not _pressure_string_active:
		return false

	if abs_depth > pressure_string_cancel_range:
		_clear_pressure_string()
		_debug_event(&"PRESSURE_STRING_CANCEL_OUT_OF_RANGE")
		return false

	character.set_guarding(false)
	character.set_desired_lane_dir(0.0)

	if _pressure_string_timer > 0.0:
		_debug_state(&"PRESSURE_STRING_WAIT")
		return true

	if _pressure_string_index >= _pressure_string_roles.size():
		_finish_pressure_string()
		return true

	_request_next_pressure_string_step()
	return true


func _request_next_pressure_string_step() -> void:
	if _pressure_string_index >= _pressure_string_roles.size():
		return

	var role: StringName = _pressure_string_roles[_pressure_string_index]
	_pressure_string_index += 1

	character.set_guarding(false)
	character.set_desired_lane_dir(0.0)
	character.request_attack(role)

	_time_since_any_action = 0.0

	if role == &"fast_poke":
		_time_since_light_attack = 0.0
	elif role == &"heavy_poke":
		_time_since_heavy_attack = 0.0

	_pressure_string_timer = pressure_string_step_delay

	if debug_ai:
		print("ThugMidAI event: PRESSURE_STRING_STEP ", role)


func _finish_pressure_string() -> void:
	_pressure_string_active = false
	_time_since_pressure_string = 0.0

	_maybe_queue_post_attack_backstep(
		_pressure_string_backstep_dir,
		backstep_chance_after_string,
		post_string_backstep_delay
	)

	_debug_event(&"PRESSURE_STRING_FINISHED")


func _clear_pressure_string() -> void:
	_pressure_string_active = false
	_pressure_string_roles.clear()
	_pressure_string_index = 0
	_pressure_string_timer = 0.0
	_pressure_string_backstep_dir = 0.0


# =============================================================================
# Backstep
# =============================================================================

func _maybe_queue_post_attack_backstep(dir_away_from_target: float, chance: float, delay: float) -> void:
	if not can_backstep:
		return

	if chance <= 0.0:
		return

	if _time_since_backstep < backstep_cooldown:
		return

	if randf() > chance:
		return

	_pending_post_attack_backstep = true
	_pending_post_attack_backstep_timer = delay
	_pending_post_attack_backstep_dir = dir_away_from_target


func _try_start_pending_post_attack_backstep() -> bool:
	if not _pending_post_attack_backstep:
		return false

	if _pending_post_attack_backstep_timer > 0.0:
		return false

	_pending_post_attack_backstep = false
	return _start_backstep(_pending_post_attack_backstep_dir, &"POST_ATTACK_BACKSTEP")


func _try_start_backstep(dir_away_from_target: float, chance: float, debug_label: StringName) -> bool:
	if not can_backstep:
		return false

	if chance <= 0.0:
		return false

	if _time_since_backstep < backstep_cooldown:
		return false

	if randf() > chance:
		return false

	return _start_backstep(dir_away_from_target, debug_label)


func _start_backstep(dir_away_from_target: float, debug_label: StringName) -> bool:
	_backstep_timer = backstep_duration
	_backstep_dir = dir_away_from_target
	_time_since_backstep = 0.0

	character.set_guarding(false)
	character.set_desired_lane_dir(_backstep_dir)

	_debug_event(debug_label)
	return true


func _try_continue_backstep() -> bool:
	if _backstep_timer <= 0.0:
		return false

	character.set_guarding(false)
	character.set_desired_lane_dir(_backstep_dir)

	_debug_state(&"BACKSTEP")
	return true


# =============================================================================
# Guard / Dodge
# =============================================================================

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

	if not _request_permitted_attack(&"dodge", dodge_lock_duration):
		return false

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

	if _time_since_any_action < shared_action_cooldown:
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


# =============================================================================
# Dummy / Clearing
# =============================================================================

func _stop_all_intent() -> void:
	character.set_desired_lane_dir(0.0)
	character.set_guarding(false)
	character.clear_attack_request()
	_clear_temporary_intent()

	_debug_state(&"NO_TARGET")


func _think_dummy_idle() -> void:
	if character == null:
		return

	character.set_desired_lane_dir(0.0)
	character.set_guarding(false)
	character.clear_attack_request()
	_clear_temporary_intent()

	_debug_state(&"DUMMY_IDLE")


func _think_dummy_block_all() -> void:
	if character == null:
		return

	character.set_desired_lane_dir(0.0)
	character.set_guarding(true)
	character.clear_attack_request()
	_clear_temporary_intent()

	_debug_state(&"DUMMY_BLOCK_ALL")


func _clear_temporary_intent() -> void:
	_pending_post_attack_backstep = false
	_pending_post_attack_backstep_timer = 0.0
	_pending_post_attack_backstep_dir = 0.0

	_backstep_timer = 0.0
	_backstep_dir = 0.0

	_guard_timer = 0.0

	_clear_pressure_string()


# =============================================================================
# Debug
# =============================================================================

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
