class_name NPCBase
extends Node3D

signal interaction_started(npc: NPCBase, timeline_name: StringName)
signal interaction_finished(npc: NPCBase)

@export_group("NPC Data")
@export var npc_profile: NPCProfile
@export var timeline_name: StringName = &""

@export_group("Node Paths")
@export var animation_player_path: NodePath
@export var selfie_cam_path: NodePath
@export var cooldown_timer_path: NodePath
@export var convo_area_path: NodePath

@export_group("Animation")
@export var default_anim_name: StringName = &""

@export_group("Interaction")
@export var face_player_on_interact: bool = true
@export var use_interaction_cooldown: bool = true

var animation_player: AnimationPlayer
var selfie_cam: Camera3D
var cinematic_cooldown_timer: Timer
var convo_area: Area3D

var can_cinematic: bool = true
var _is_currently_interacting: bool = false
var _current_timeline_name: StringName = &""


func _ready() -> void:
	add_to_group("npcs")

	_resolve_nodes()
	_cache_default_animation()
	_connect_signals()


func _resolve_nodes() -> void:
	animation_player = get_node_or_null(animation_player_path) as AnimationPlayer
	selfie_cam = get_node_or_null(selfie_cam_path) as Camera3D
	cinematic_cooldown_timer = get_node_or_null(cooldown_timer_path) as Timer
	convo_area = get_node_or_null(convo_area_path) as Area3D


func _cache_default_animation() -> void:
	if animation_player == null:
		return

	if default_anim_name != &"":
		return

	default_anim_name = StringName(animation_player.current_animation)


func _connect_signals() -> void:
	if cinematic_cooldown_timer != null:
		if cinematic_cooldown_timer.timeout.is_connected(_on_cinematic_cooldown_timeout) == false:
			cinematic_cooldown_timer.timeout.connect(_on_cinematic_cooldown_timeout)

	if Dialogic.timeline_ended.is_connected(_on_dialogic_timeline_ended) == false:
		Dialogic.timeline_ended.connect(_on_dialogic_timeline_ended)


func interact() -> void:
	if can_interact() == false:
		return

	var selected_timeline: StringName = NPCDialogueRouter.get_timeline(npc_profile, timeline_name)

	if selected_timeline == &"":
		push_warning("%s has no Dialogic timeline assigned." % name)
		return

	can_cinematic = false
	_is_currently_interacting = true
	_current_timeline_name = selected_timeline

	if face_player_on_interact:
		face_player()

	_register_npc_interaction()

	interaction_started.emit(self, selected_timeline)
	Dialogic.start_timeline(String(selected_timeline))


func can_interact() -> bool:
	if can_cinematic == false:
		return false

	return true


func _register_npc_interaction() -> void:
	if npc_profile == null:
		return

	if npc_profile.npc_id == &"":
		return

	var world_state: WorldState = _get_world_state()
	if world_state == null:
		return

	world_state.mark_npc_met(npc_profile.npc_id)
	world_state.increment_npc_talk_count(npc_profile.npc_id)


func _get_world_state() -> WorldState:
	var node: Node = get_tree().root.get_node_or_null("World_State")
	return node as WorldState


func face_player() -> void:
	var player: Node3D = get_tree().get_first_node_in_group("player") as Node3D

	if player == null:
		return

	var my_position: Vector3 = global_position
	var player_position: Vector3 = player.global_position
	var look_target: Vector3 = Vector3(player_position.x, my_position.y, player_position.z)

	if my_position.distance_squared_to(look_target) <= 0.001:
		return

	look_at(look_target, Vector3.UP)


func play_animation(anim_name: String) -> void:
	if animation_player == null:
		return

	if anim_name == "":
		return

	animation_player.play(anim_name)


func set_selfie_cam() -> void:
	if selfie_cam == null:
		return

	selfie_cam.set_current(true)


func _on_dialogic_timeline_ended() -> void:
	if _is_currently_interacting == false:
		return

	_is_currently_interacting = false
	_current_timeline_name = &""

	if animation_player != null and default_anim_name != &"":
		animation_player.play(String(default_anim_name))

	if use_interaction_cooldown and cinematic_cooldown_timer != null:
		cinematic_cooldown_timer.start()
	else:
		can_cinematic = true

	interaction_finished.emit(self)


func _on_cinematic_cooldown_timeout() -> void:
	can_cinematic = true
