extends Node
class_name EnemyAttackCoordinator

signal attack_permission_granted(enemy: Node, role: StringName)
signal attack_permission_denied(enemy: Node, role: StringName)
signal attack_permission_released(enemy: Node)

var max_committed_attackers: int = 1
var default_attack_lock_duration: float = 1.2
var first_attack_delay: float = 0.75
var minimum_gap_between_attack_turns: float = 0.65
var maximum_gap_between_attack_turns: float = 1.1

var _role_coordinator: EnemyRoleCoordinator
var _debug_enabled: bool = false

var _registered_enemies: Array[Node] = []
var _active_attackers: Dictionary = {}
var _is_running: bool = false
var _attack_gap_timer: float = 0.0


func _physics_process(delta: float) -> void:
	if not _is_running:
		return

	_update_attack_gap(delta)
	_update_active_attackers(delta)


func configure_from_profile(
	profile: EncounterCombatProfile,
	new_role_coordinator: EnemyRoleCoordinator,
	debug_enabled: bool
) -> void:
	_role_coordinator = new_role_coordinator
	_debug_enabled = debug_enabled

	if profile == null:
		return

	max_committed_attackers = maxi(profile.max_committed_attackers, 1)
	default_attack_lock_duration = profile.default_attack_lock_duration
	first_attack_delay = profile.first_attack_delay
	minimum_gap_between_attack_turns = profile.minimum_gap_between_attack_turns
	maximum_gap_between_attack_turns = profile.maximum_gap_between_attack_turns


func start_coordinating() -> void:
	_is_running = true
	_active_attackers.clear()
	_attack_gap_timer = first_attack_delay

	_debug("Started coordinating")


func stop_coordinating() -> void:
	_is_running = false
	clear_all_permissions()

	_debug("Stopped coordinating")


func register_enemy(enemy: Node) -> void:
	if enemy == null:
		return

	if _registered_enemies.has(enemy):
		return

	_registered_enemies.append(enemy)

	_debug("Registered enemy: %s" % enemy.name)


func register_enemy_combatants(enemy_combatants: Array[Combatant]) -> void:
	for combatant: Combatant in enemy_combatants:
		if not is_instance_valid(combatant):
			continue

		var enemy_body: Node = combatant.body
		if enemy_body == null:
			continue

		register_enemy(enemy_body)

		if not combatant.died.is_connected(_on_enemy_died.bind(enemy_body)):
			combatant.died.connect(_on_enemy_died.bind(enemy_body))


func unregister_enemy(enemy: Node) -> void:
	if enemy == null:
		return

	release_attack_permission(enemy, false)
	_registered_enemies.erase(enemy)

	if _role_coordinator != null:
		_role_coordinator.unregister_enemy(enemy)

	_debug("Unregistered enemy: %s" % enemy.name)


func try_request_attack(enemy: Node, role: StringName, lock_duration: float = -1.0) -> bool:
	if enemy == null:
		return false

	if not _is_running:
		_debug("Denied because coordinator is not running: %s" % enemy.name)
		attack_permission_denied.emit(enemy, role)
		return false

	if not _registered_enemies.has(enemy):
		register_enemy(enemy)

	if _active_attackers.has(enemy):
		return true

	if _role_coordinator != null:
		if not _role_coordinator.can_become_attacker(enemy):
			_debug("Denied because role cannot attack: %s role: %s" % [enemy.name, role])
			attack_permission_denied.emit(enemy, role)
			return false

	if _attack_gap_timer > 0.0:
		_debug("Denied because attack gap is active: %s role: %s" % [enemy.name, role])
		attack_permission_denied.emit(enemy, role)
		return false

	if _active_attackers.size() >= max_committed_attackers:
		_debug("Denied because attacker cap reached: %s role: %s" % [enemy.name, role])
		attack_permission_denied.emit(enemy, role)
		return false

	var duration: float = default_attack_lock_duration
	if lock_duration > 0.0:
		duration = lock_duration

	_active_attackers[enemy] = duration

	if _role_coordinator != null:
		_role_coordinator.mark_active_attacker(enemy)

	_debug("Granted: %s role: %s duration: %.2f" % [enemy.name, role, duration])
	attack_permission_granted.emit(enemy, role)
	return true


func release_attack_permission(enemy: Node, mark_recovering: bool = true) -> void:
	if enemy == null:
		return

	if not _active_attackers.has(enemy):
		return

	_active_attackers.erase(enemy)

	if _role_coordinator != null:
		if mark_recovering:
			_role_coordinator.mark_recovering(enemy)
		else:
			_role_coordinator.set_role(enemy, EnemyRoleCoordinator.EnemyRole.UNASSIGNED)
			_role_coordinator.rebalance_roles()

	_start_attack_gap()

	_debug("Released: %s" % enemy.name)
	attack_permission_released.emit(enemy)


func clear_all_permissions() -> void:
	var enemies_to_release: Array[Node] = []

	for key: Variant in _active_attackers.keys():
		var enemy: Node = key as Node
		if enemy != null:
			enemies_to_release.append(enemy)

	_active_attackers.clear()
	_attack_gap_timer = 0.0

	for enemy: Node in enemies_to_release:
		if _role_coordinator != null and is_instance_valid(enemy):
			_role_coordinator.set_role(enemy, EnemyRoleCoordinator.EnemyRole.UNASSIGNED)

		attack_permission_released.emit(enemy)

	if _role_coordinator != null:
		_role_coordinator.rebalance_roles()


func has_attack_permission(enemy: Node) -> bool:
	if enemy == null:
		return false

	return _active_attackers.has(enemy)


func _update_attack_gap(delta: float) -> void:
	if _attack_gap_timer <= 0.0:
		return

	_attack_gap_timer = maxf(_attack_gap_timer - delta, 0.0)


func _update_active_attackers(delta: float) -> void:
	var enemies_to_release: Array[Node] = []

	for key: Variant in _active_attackers.keys():
		var enemy: Node = key as Node

		if enemy == null or not is_instance_valid(enemy):
			if enemy != null:
				enemies_to_release.append(enemy)
			continue

		var time_left: float = float(_active_attackers[enemy]) - delta

		if time_left <= 0.0:
			enemies_to_release.append(enemy)
		else:
			_active_attackers[enemy] = time_left

	for enemy: Node in enemies_to_release:
		release_attack_permission(enemy)


func _start_attack_gap() -> void:
	var min_gap: float = maxf(minimum_gap_between_attack_turns, 0.0)
	var max_gap: float = maxf(maximum_gap_between_attack_turns, min_gap)

	if max_gap <= 0.0:
		_attack_gap_timer = 0.0
		return

	_attack_gap_timer = randf_range(min_gap, max_gap)


func _on_enemy_died(enemy: Node) -> void:
	unregister_enemy(enemy)


func _debug(message: String) -> void:
	if not _debug_enabled:
		return

	print("EnemyAttackCoordinator: ", message)
