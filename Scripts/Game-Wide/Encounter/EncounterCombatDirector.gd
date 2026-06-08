extends Node
class_name EncounterCombatDirector

@export_group("Configuration")
@export var combat_profile: EncounterCombatProfile
@export var debug_group_combat: bool = false

@export_group("Child Modules")
@export var attack_coordinator: EnemyAttackCoordinator
@export var role_coordinator: EnemyRoleCoordinator
@export var soft_lock_coordinator: SoftLockCoordinator
@export var encounter_camera_coordinator: EncounterCameraCoordinator

var _player_combatant: Combatant
var _enemy_combatants: Array[Combatant] = []
var _is_running: bool = false


func _ready() -> void:
	_auto_find_child_modules()


func start_directing(
	new_player_combatant: Combatant,
	new_enemy_combatants: Array[Combatant]
) -> void:
	_player_combatant = new_player_combatant

	_enemy_combatants.clear()
	for enemy_combatant: Combatant in new_enemy_combatants:
		if is_instance_valid(enemy_combatant):
			_enemy_combatants.append(enemy_combatant)

	_apply_profile_debug()
	_auto_find_child_modules()
	_configure_modules()
	_bind_enemy_bodies()

	_is_running = true

	if role_coordinator != null:
		role_coordinator.start_coordinating()

	if attack_coordinator != null:
		attack_coordinator.start_coordinating()

	if soft_lock_coordinator != null:
		soft_lock_coordinator.start_coordinating()

	if encounter_camera_coordinator != null:
		encounter_camera_coordinator.start_coordinating()

	_debug("Started directing encounter combat")


func stop_directing() -> void:
	_is_running = false

	if attack_coordinator != null:
		attack_coordinator.stop_coordinating()

	if role_coordinator != null:
		role_coordinator.stop_coordinating()

	if soft_lock_coordinator != null:
		soft_lock_coordinator.stop_coordinating()

	if encounter_camera_coordinator != null:
		encounter_camera_coordinator.stop_coordinating()

	_unbind_enemy_bodies()

	_debug("Stopped directing encounter combat")


func request_attack_permission(
	enemy: Node,
	role: StringName,
	lock_duration: float = -1.0
) -> bool:
	if not _is_running:
		return false

	if attack_coordinator == null:
		return true

	return attack_coordinator.try_request_attack(enemy, role, lock_duration)


func release_attack_permission(enemy: Node, mark_recovering: bool = true) -> void:
	if attack_coordinator == null:
		return

	attack_coordinator.release_attack_permission(enemy, mark_recovering)


func has_attack_permission(enemy: Node) -> bool:
	if attack_coordinator == null:
		return true

	return attack_coordinator.has_attack_permission(enemy)


func get_enemy_role(enemy: Node) -> EnemyRoleCoordinator.EnemyRole:
	if role_coordinator == null:
		return EnemyRoleCoordinator.EnemyRole.UNASSIGNED

	return role_coordinator.get_role(enemy)


func get_role_spacing(role: EnemyRoleCoordinator.EnemyRole) -> Vector2:
	if role_coordinator == null:
		return Vector2.ZERO

	return role_coordinator.get_role_spacing(role)


func _auto_find_child_modules() -> void:
	if attack_coordinator == null:
		attack_coordinator = get_node_or_null("EnemyAttackCoordinator") as EnemyAttackCoordinator

	if role_coordinator == null:
		role_coordinator = get_node_or_null("EnemyRoleCoordinator") as EnemyRoleCoordinator

	if soft_lock_coordinator == null:
		soft_lock_coordinator = get_node_or_null("SoftLockCoordinator") as SoftLockCoordinator

	if encounter_camera_coordinator == null:
		encounter_camera_coordinator = get_node_or_null("EncounterCameraCoordinator") as EncounterCameraCoordinator


func _apply_profile_debug() -> void:
	if combat_profile == null:
		return

	debug_group_combat = combat_profile.debug_encounter_combat


func _configure_modules() -> void:
	var player_body: Node3D = _get_body_from_combatant(_player_combatant)

	if role_coordinator != null:
		role_coordinator.configure_from_profile(
			combat_profile,
			player_body,
			debug_group_combat
		)
		role_coordinator.register_enemy_combatants(_enemy_combatants)

	if attack_coordinator != null:
		attack_coordinator.configure_from_profile(
			combat_profile,
			role_coordinator,
			debug_group_combat
		)
		attack_coordinator.register_enemy_combatants(_enemy_combatants)

	if soft_lock_coordinator != null:
		soft_lock_coordinator.configure_from_profile(
			combat_profile,
			player_body,
			debug_group_combat
		)
		soft_lock_coordinator.register_enemy_combatants(_enemy_combatants)

	if encounter_camera_coordinator != null:
		encounter_camera_coordinator.configure_from_profile(
			combat_profile,
			player_body,
			debug_group_combat
		)
		encounter_camera_coordinator.register_enemy_combatants(_enemy_combatants)


func _bind_enemy_bodies() -> void:
	for enemy_combatant: Combatant in _enemy_combatants:
		if not is_instance_valid(enemy_combatant):
			continue

		var enemy_body: ThugMid = enemy_combatant.body as ThugMid
		if enemy_body == null:
			continue

		enemy_body.bind_encounter_combat_director(self)


func _unbind_enemy_bodies() -> void:
	for enemy_combatant: Combatant in _enemy_combatants:
		if not is_instance_valid(enemy_combatant):
			continue

		var enemy_body: ThugMid = enemy_combatant.body as ThugMid
		if enemy_body == null:
			continue

		enemy_body.clear_encounter_combat_director()


func _get_body_from_combatant(combatant: Combatant) -> Node3D:
	if not is_instance_valid(combatant):
		return null

	return combatant.body as Node3D


func _debug(message: String) -> void:
	if not debug_group_combat:
		return

	print("EncounterCombatDirector: ", message)
