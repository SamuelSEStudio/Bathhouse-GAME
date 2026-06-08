extends Node
class_name EnemyRoleCoordinator

enum EnemyRole {
	UNASSIGNED,
	ACTIVE_ATTACKER,
	PRESSURE,
	HOLD_OFF,
	RECOVERING,
}

var _registered_enemies: Array[Node] = []
var _enemy_roles: Dictionary = {}
var _recovering_timers: Dictionary = {}

var _is_running: bool = false
var _debug_enabled: bool = false

var _use_roles: bool = true
var _pressure_role_count: int = 1
var _hold_off_role_count: int = 1
var _recovering_duration: float = 1.0
var _pressure_spacing: Vector2 = Vector2(1.6, 2.7)
var _hold_off_spacing: Vector2 = Vector2(3.0, 4.5)

var _focus_target: Node3D


func _physics_process(delta: float) -> void:
	if not _is_running:
		return

	_update_recovering_timers(delta)


func configure_from_profile(
	profile: EncounterCombatProfile,
	focus_target: Node3D,
	debug_enabled: bool
) -> void:
	_focus_target = focus_target
	_debug_enabled = debug_enabled

	if profile == null:
		return

	_use_roles = profile.use_roles
	_pressure_role_count = maxi(profile.pressure_role_count, 0)
	_hold_off_role_count = maxi(profile.hold_off_role_count, 0)
	_recovering_duration = maxf(profile.recovering_duration, 0.0)
	_pressure_spacing = Vector2(profile.pressure_min_range, profile.pressure_max_range)
	_hold_off_spacing = Vector2(profile.hold_off_min_range, profile.hold_off_max_range)


func start_coordinating() -> void:
	_is_running = true
	rebalance_roles()

	_debug("Started coordinating")


func stop_coordinating() -> void:
	_is_running = false
	clear_roles()

	_debug("Stopped coordinating")


func register_enemy(enemy: Node) -> void:
	if enemy == null:
		return

	if _registered_enemies.has(enemy):
		return

	_registered_enemies.append(enemy)
	_enemy_roles[enemy] = EnemyRole.UNASSIGNED

	_debug("Registered enemy: %s" % enemy.name)


func register_enemy_combatants(enemy_combatants: Array[Combatant]) -> void:
	for combatant: Combatant in enemy_combatants:
		if not is_instance_valid(combatant):
			continue

		var enemy_body: Node = combatant.body
		if enemy_body == null:
			continue

		register_enemy(enemy_body)

	rebalance_roles()


func unregister_enemy(enemy: Node) -> void:
	if enemy == null:
		return

	_registered_enemies.erase(enemy)
	_enemy_roles.erase(enemy)
	_recovering_timers.erase(enemy)

	_debug("Unregistered enemy: %s" % enemy.name)

	rebalance_roles()


func clear_roles() -> void:
	_enemy_roles.clear()
	_recovering_timers.clear()

	for enemy: Node in _registered_enemies:
		if is_instance_valid(enemy):
			_enemy_roles[enemy] = EnemyRole.UNASSIGNED


func set_role(enemy: Node, role: EnemyRole) -> void:
	if enemy == null:
		return

	if not _registered_enemies.has(enemy):
		register_enemy(enemy)

	var previous_role: EnemyRole = get_role(enemy)
	_enemy_roles[enemy] = role

	if role != EnemyRole.RECOVERING:
		_recovering_timers.erase(enemy)

	if previous_role != role:
		_debug("Role set: %s -> %s" % [enemy.name, _role_to_string(role)])


func get_role(enemy: Node) -> EnemyRole:
	if enemy == null:
		return EnemyRole.UNASSIGNED

	if not _enemy_roles.has(enemy):
		return EnemyRole.UNASSIGNED

	return _enemy_roles[enemy] as EnemyRole


func get_role_spacing(role: EnemyRole) -> Vector2:
	match role:
		EnemyRole.PRESSURE:
			return _pressure_spacing

		EnemyRole.HOLD_OFF:
			return _hold_off_spacing

		EnemyRole.RECOVERING:
			return _hold_off_spacing

	return Vector2.ZERO


func mark_active_attacker(enemy: Node) -> void:
	set_role(enemy, EnemyRole.ACTIVE_ATTACKER)
	rebalance_roles()


func mark_recovering(enemy: Node, duration: float = -1.0) -> void:
	if enemy == null:
		return

	var recovery_time: float = duration
	if recovery_time <= 0.0:
		recovery_time = _recovering_duration

	set_role(enemy, EnemyRole.RECOVERING)
	_recovering_timers[enemy] = recovery_time

	rebalance_roles()


func is_recovering(enemy: Node) -> bool:
	if enemy == null:
		return false

	return get_role(enemy) == EnemyRole.RECOVERING


func can_become_attacker(enemy: Node) -> bool:
	if enemy == null:
		return false

	var role: EnemyRole = get_role(enemy)

	if role == EnemyRole.RECOVERING:
		return false

	if role == EnemyRole.HOLD_OFF:
		return false

	return true


func rebalance_roles() -> void:
	if not _use_roles:
		_set_all_non_committed_to_unassigned()
		return
	var living_enemies: Array[Node] = []

	for enemy: Node in _registered_enemies:
		if is_instance_valid(enemy):
			living_enemies.append(enemy)

	# Group-combat roles are unnecessary once the fight returns to a 1v1.
	# Preserve an active attack or short recovery, but otherwise let the
	# surviving enemy return to its normal ThugAIProfile behaviour.
	if living_enemies.size() <= 1:
		for enemy: Node in living_enemies:
			var role: EnemyRole = get_role(enemy)

			if role == EnemyRole.ACTIVE_ATTACKER:
				continue

			if role == EnemyRole.RECOVERING:
				continue

			set_role(enemy, EnemyRole.UNASSIGNED)

		return

	var available_enemies: Array[Node] = _get_available_enemies_sorted()
	var pressure_assigned: int = 0
	var hold_off_assigned: int = 0

	for enemy: Node in available_enemies:
		if pressure_assigned < _pressure_role_count:
			set_role(enemy, EnemyRole.PRESSURE)
			pressure_assigned += 1
			continue

		if hold_off_assigned < _hold_off_role_count:
			set_role(enemy, EnemyRole.HOLD_OFF)
			hold_off_assigned += 1
			continue

		set_role(enemy, EnemyRole.HOLD_OFF)


func _set_all_non_committed_to_unassigned() -> void:
	for enemy: Node in _registered_enemies:
		if not is_instance_valid(enemy):
			continue

		var role: EnemyRole = get_role(enemy)
		if role == EnemyRole.ACTIVE_ATTACKER or role == EnemyRole.RECOVERING:
			continue

		set_role(enemy, EnemyRole.UNASSIGNED)


func _get_available_enemies_sorted() -> Array[Node]:
	var available_enemies: Array[Node] = []

	for enemy: Node in _registered_enemies:
		if not is_instance_valid(enemy):
			continue

		var role: EnemyRole = get_role(enemy)

		if role == EnemyRole.ACTIVE_ATTACKER:
			continue

		if role == EnemyRole.RECOVERING:
			continue

		available_enemies.append(enemy)

	if _focus_target != null:
		available_enemies.sort_custom(_sort_by_distance_to_focus)

	return available_enemies


func _sort_by_distance_to_focus(a: Node, b: Node) -> bool:
	if _focus_target == null:
		return false

	var a_node: Node3D = a as Node3D
	var b_node: Node3D = b as Node3D

	if a_node == null or b_node == null:
		return false

	var a_dist_sq: float = a_node.global_position.distance_squared_to(_focus_target.global_position)
	var b_dist_sq: float = b_node.global_position.distance_squared_to(_focus_target.global_position)

	return a_dist_sq < b_dist_sq


func _update_recovering_timers(delta: float) -> void:
	var finished_enemies: Array[Node] = []

	for key: Variant in _recovering_timers.keys():
		var enemy: Node = key as Node

		if enemy == null or not is_instance_valid(enemy):
			if enemy != null:
				finished_enemies.append(enemy)
			continue

		var time_left: float = float(_recovering_timers[enemy]) - delta

		if time_left <= 0.0:
			finished_enemies.append(enemy)
		else:
			_recovering_timers[enemy] = time_left

	for enemy: Node in finished_enemies:
		_recovering_timers.erase(enemy)

		if is_instance_valid(enemy):
			set_role(enemy, EnemyRole.UNASSIGNED)
	
	if not finished_enemies.is_empty():
		rebalance_roles()
	
	rebalance_roles()


func _role_to_string(role: EnemyRole) -> String:
	match role:
		EnemyRole.UNASSIGNED:
			return "UNASSIGNED"

		EnemyRole.ACTIVE_ATTACKER:
			return "ACTIVE_ATTACKER"

		EnemyRole.PRESSURE:
			return "PRESSURE"

		EnemyRole.HOLD_OFF:
			return "HOLD_OFF"

		EnemyRole.RECOVERING:
			return "RECOVERING"

	return "UNKNOWN"


func _debug(message: String) -> void:
	if not _debug_enabled:
		return

	print("EnemyRoleCoordinator: ", message)
