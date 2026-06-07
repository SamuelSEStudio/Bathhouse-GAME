extends Node
class_name EnemyRoleCoordinator

enum EnemyRole {
	UNASSIGNED,
	ACTIVE_ATTACKER,
	PRESSURE,
	HOLD_OFF,
	RECOVERING,
}

@export var profile: EncounterCombatProfile
@export var debug_roles: bool = false

var _registered_enemies: Array[Node] = []
var _enemy_roles: Dictionary = {}
var _recovering_timers: Dictionary = {}
var _is_running: bool = false


func _ready() -> void:
	add_to_group("enemy_role_coordinators")


func _physics_process(delta: float) -> void:
	if not _is_running:
		return

	_update_recovering_timers(delta)


func configure(new_profile: EncounterCombatProfile) -> void:
	profile = new_profile

	if profile != null:
		debug_roles = profile.debug_encounter_combat


func start_coordinating() -> void:
	_is_running = true


func stop_coordinating() -> void:
	_is_running = false
	clear_roles()


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


func unregister_enemy(enemy: Node) -> void:
	if enemy == null:
		return

	_registered_enemies.erase(enemy)
	_enemy_roles.erase(enemy)
	_recovering_timers.erase(enemy)

	_debug("Unregistered enemy: %s" % enemy.name)


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

	_enemy_roles[enemy] = role

	if role != EnemyRole.RECOVERING:
		_recovering_timers.erase(enemy)

	_debug("Role set: %s -> %s" % [enemy.name, _role_to_string(role)])


func get_role(enemy: Node) -> EnemyRole:
	if enemy == null:
		return EnemyRole.UNASSIGNED

	if not _enemy_roles.has(enemy):
		return EnemyRole.UNASSIGNED

	return _enemy_roles[enemy] as EnemyRole


func mark_active_attacker(enemy: Node) -> void:
	set_role(enemy, EnemyRole.ACTIVE_ATTACKER)


func mark_recovering(enemy: Node, duration: float = -1.0) -> void:
	if enemy == null:
		return

	var recovery_duration: float = duration

	if recovery_duration <= 0.0:
		recovery_duration = 1.0
		if profile != null:
			recovery_duration = profile.recovering_duration

	set_role(enemy, EnemyRole.RECOVERING)
	_recovering_timers[enemy] = recovery_duration


func is_recovering(enemy: Node) -> bool:
	if enemy == null:
		return false

	return get_role(enemy) == EnemyRole.RECOVERING


func can_become_attacker(enemy: Node) -> bool:
	if enemy == null:
		return false

	if is_recovering(enemy):
		return false

	return true


func _update_recovering_timers(delta: float) -> void:
	var finished_enemies: Array[Node] = []

	for enemy: Node in _recovering_timers.keys():
		if not is_instance_valid(enemy):
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
	if not debug_roles:
		return

	print("EnemyRoleCoordinator: ", message)
