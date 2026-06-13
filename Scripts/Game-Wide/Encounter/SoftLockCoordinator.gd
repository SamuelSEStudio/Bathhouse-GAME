extends Node
class_name SoftLockCoordinator

signal preferred_target_changed(new_target: Node3D)

var _is_running: bool = false
var _debug_enabled: bool = false
var _focus_target: Node3D
var _role_coordinator: EnemyRoleCoordinator
var _registered_enemies: Array[Node3D] = []
var _preferred_target: Node3D
var _rescore_timer: float = 0.0
var _target_hold_timer: float = 0.0

var _use_soft_lock: bool = true
var _rescore_interval: float = 0.12
var _minimum_hold_duration: float = 0.50
var _switch_margin: float = 0.75
var _current_target_bias: float = 1.25
var _lead_attacker_bias: float = 0.75
var _opportunity_attacker_bias: float = 2.0


func _physics_process(delta: float) -> void:
	if not _is_running or not _use_soft_lock:
		return

	_rescore_timer = maxf(_rescore_timer - delta, 0.0)
	_target_hold_timer = maxf(_target_hold_timer - delta, 0.0)

	if _rescore_timer <= 0.0:
		_rescore_timer = _rescore_interval
		_refresh_preferred_target()


func configure_from_profile(
	profile: EncounterCombatProfile,
	focus_target: Node3D,
	role_coordinator: EnemyRoleCoordinator,
	debug_enabled: bool
) -> void:
	_focus_target = focus_target
	_role_coordinator = role_coordinator
	_debug_enabled = debug_enabled

	if profile == null:
		return

	_use_soft_lock = profile.use_soft_lock_coordinator
	_rescore_interval = maxf(profile.soft_lock_rescore_interval, 0.02)
	_minimum_hold_duration = maxf(profile.soft_lock_minimum_hold_duration, 0.0)
	_switch_margin = maxf(profile.soft_lock_switch_margin, 0.0)
	_current_target_bias = maxf(profile.soft_lock_current_target_bias, 0.0)
	_lead_attacker_bias = maxf(profile.soft_lock_lead_attacker_bias, 0.0)
	_opportunity_attacker_bias = maxf(profile.soft_lock_opportunity_attacker_bias, 0.0)


func start_coordinating() -> void:
	_is_running = true
	_rescore_timer = 0.0
	_target_hold_timer = 0.0
	_refresh_preferred_target(true)
	_debug("Started soft-lock coordinator")


func stop_coordinating() -> void:
	_is_running = false
	_set_preferred_target(null)
	_debug("Stopped soft-lock coordinator")


func register_enemy_combatants(enemy_combatants: Array[Combatant]) -> void:
	_registered_enemies.clear()

	for combatant: Combatant in enemy_combatants:
		if not is_instance_valid(combatant):
			continue

		var enemy_body: Node3D = combatant.body as Node3D
		if enemy_body != null:
			_registered_enemies.append(enemy_body)


func get_preferred_target() -> Node3D:
	return _preferred_target


func _refresh_preferred_target(force_switch: bool = false) -> void:
	var best_target: Node3D = _choose_best_target()

	if best_target == _preferred_target:
		return

	if not _is_valid_target(_preferred_target):
		_set_preferred_target(best_target)
		return

	if force_switch or _target_hold_timer <= 0.0:
		var current_score: float = _score_target(_preferred_target)
		var best_score: float = _score_target(best_target)

		if best_target != null and best_score + _switch_margin < current_score:
			_set_preferred_target(best_target)


func _choose_best_target() -> Node3D:
	var best_target: Node3D = null
	var best_score: float = INF

	for enemy: Node3D in _registered_enemies:
		if not _is_valid_target(enemy):
			continue

		var score: float = _score_target(enemy)
		if best_target == null or score < best_score:
			best_target = enemy
			best_score = score

	return best_target


func _score_target(enemy: Node3D) -> float:
	if enemy == null or _focus_target == null:
		return INF

	var score: float = enemy.global_position.distance_to(_focus_target.global_position)

	if enemy == _preferred_target:
		score -= _current_target_bias

	if _role_coordinator != null:
		match _role_coordinator.get_role(enemy):
			EnemyRoleCoordinator.EnemyRole.ACTIVE_ATTACKER:
				score -= _lead_attacker_bias
			EnemyRoleCoordinator.EnemyRole.OPPORTUNITY_ATTACKER:
				score -= _opportunity_attacker_bias

	return score


func _is_valid_target(enemy: Node3D) -> bool:
	if not is_instance_valid(enemy):
		return false

	var thug: ThugMid = enemy as ThugMid
	if thug != null and is_instance_valid(thug.combatant):
		return not thug.combatant.is_ko

	return true


func _set_preferred_target(new_target: Node3D) -> void:
	if _preferred_target == new_target:
		return

	_preferred_target = new_target
	_target_hold_timer = _minimum_hold_duration
	preferred_target_changed.emit(_preferred_target)

	if _preferred_target != null:
		_debug("Preferred target: %s" % _preferred_target.name)

func _debug(message: String) -> void:
	if _debug_enabled:
		print("SoftLockCoordinator: ", message)
