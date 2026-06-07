extends CharacterBody3D
class_name ThugMid

enum ControlMode {
	PLAYER,
	DUMMY_IDLE,
	DUMMY_BLOCK_ALL,
	DUMMY_BLOCK_SECOND_HIT,
	AI_PROFILE_1,
	AI_PROFILE_2,
	AI_PROFILE_3,
}

enum MovementMode {
	LANE,
	ARENA,
}

@export_group("Control")
@export var control_mode: ControlMode = ControlMode.AI_PROFILE_2
@export var movement_mode: MovementMode = MovementMode.LANE
@export var combat_target: Node3D
@export var invert_facing: bool = true
@export var lane_axis: Vector3 = Vector3.FORWARD

@export_group("Encounter Coordination")
@export var allow_coordinator_autofind_fallback: bool = true
var attack_coordinator: EnemyAttackCoordinator
var role_coordinator: EnemyRoleCoordinator
@export var auto_find_coordinators: bool = true

var desired_lane_dir: float = 0.0
var pending_attack_role: StringName = &""
var wants_guard: bool = false

@onready var visuals: Node3D = $Visuals
@onready var animation_player: AnimationPlayer = $"Visuals/mixamo_base/AnimationPlayer"
@onready var state_machine: Node = $controllers/state_machine
@onready var combatant: Combatant = $Combatant
@onready var ai_brain: Node = $AIBrain


func _ready() -> void:
	add_to_group("enemy_attackers")
	_auto_find_coordinators_if_needed()
	state_machine.init(self)


func _physics_process(delta: float) -> void:
	state_machine.process_physics(delta)


func _process(delta: float) -> void:
	state_machine.process_frame(delta)


func _auto_find_coordinators_if_needed() -> void:
	if not auto_find_coordinators:
		return

	if attack_coordinator == null:
		var attack_nodes: Array[Node] = get_tree().get_nodes_in_group("enemy_attack_coordinators")
		if not attack_nodes.is_empty():
			attack_coordinator = attack_nodes[0] as EnemyAttackCoordinator

	if role_coordinator == null:
		var role_nodes: Array[Node] = get_tree().get_nodes_in_group("enemy_role_coordinators")
		if not role_nodes.is_empty():
			role_coordinator = role_nodes[0] as EnemyRoleCoordinator


func set_desired_lane_dir(dir: float) -> void:
	desired_lane_dir = clampf(dir, -1.0, 1.0)


func clear_desired_lane_dir() -> void:
	desired_lane_dir = 0.0


func update_facing_to_combat_target() -> void:
	if combat_target == null or visuals == null:
		return

	var my_pos: Vector3 = visuals.global_transform.origin
	var t_pos: Vector3 = combat_target.global_transform.origin
	var look_target: Vector3 = Vector3(t_pos.x, my_pos.y, t_pos.z)

	visuals.look_at(look_target, Vector3.UP)

	if invert_facing:
		visuals.rotate_y(PI)


func request_attack_permission(role: StringName, lock_duration: float = -1.0) -> bool:
	if attack_coordinator == null:
		return true

	return attack_coordinator.try_request_attack(self, role, lock_duration)


func release_attack_permission(mark_recovering: bool = true) -> void:
	if attack_coordinator == null:
		return

	attack_coordinator.release_attack_permission(self, mark_recovering)


func has_attack_permission() -> bool:
	if attack_coordinator == null:
		return true

	return attack_coordinator.has_attack_permission(self)


func get_enemy_role() -> EnemyRoleCoordinator.EnemyRole:
	if role_coordinator == null:
		return EnemyRoleCoordinator.EnemyRole.UNASSIGNED

	return role_coordinator.get_role(self)


func request_attack(role: StringName) -> void:
	pending_attack_role = role


func clear_attack_request() -> void:
	pending_attack_role = &""


func set_guarding(on: bool) -> void:
	wants_guard = on
