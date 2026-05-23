class_name NPCBase
extends Node3D

signal interaction_started(npc: NPCBase, timeline_name: StringName)
signal interaction_finished(npc: NPCBase)

@export_group("NPC Data")
@export var npc_profile: NPCProfile
@export var timeline_name: StringName = &""

@export_group("Node Paths")
@export var animation_player_path: NodePath
@export var cooldown_timer_path: NodePath
@export var convo_area_path: NodePath

@export_group("Dialogue Cameras")
@export var default_dialogue_camera_path: NodePath
@export var close_dialogue_camera_path: NodePath
@export var side_dialogue_camera_path: NodePath
@export var dramatic_dialogue_camera_path: NodePath

# Legacy fallback.
# Existing scenes like Fisherman already have selfie_cam_path assigned.
@export var selfie_cam_path: NodePath

@export_group("Animation")
@export var default_anim_name: StringName = &""

@export_group("Interaction")
@export var face_player_on_interact: bool = true
@export var use_interaction_cooldown: bool = true
@export var auto_interact_on_body_entered: bool = false

var animation_player: AnimationPlayer = null
var cinematic_cooldown_timer: Timer = null
var convo_area: Area3D = null

var can_cinematic: bool = true

var _dialogue_cameras: Dictionary = {}
var _is_currently_interacting: bool = false
var _current_timeline_name: StringName = &""


func _ready() -> void:
	add_to_group("npcs")

	_resolve_nodes()
	_cache_default_animation()
	_connect_signals()


func _resolve_nodes() -> void:
	animation_player = _get_node_from_path(animation_player_path) as AnimationPlayer
	cinematic_cooldown_timer = _get_node_from_path(cooldown_timer_path) as Timer
	convo_area = _get_node_from_path(convo_area_path) as Area3D

	_resolve_dialogue_cameras()


func _get_node_from_path(path: NodePath) -> Node:
	if String(path) == "":
		return null

	return get_node_or_null(path)


func _resolve_dialogue_cameras() -> void:
	_dialogue_cameras.clear()

	var default_path: NodePath = default_dialogue_camera_path

	# If you have not filled the new default camera path yet,
	# use the old selfie_cam_path so existing NPC scenes still work.
	if String(default_path) == "" and String(selfie_cam_path) != "":
		default_path = selfie_cam_path

	_add_dialogue_camera(&"default", default_path)
	_add_dialogue_camera(&"close", close_dialogue_camera_path)
	_add_dialogue_camera(&"side", side_dialogue_camera_path)
	_add_dialogue_camera(&"dramatic", dramatic_dialogue_camera_path)


func _add_dialogue_camera(slot_name: StringName, camera_path: NodePath) -> void:
	if String(camera_path) == "":
		return

	var camera: Camera3D = get_node_or_null(camera_path) as Camera3D

	if camera == null:
		push_warning("%s has invalid dialogue camera path for slot '%s': %s" % [name, String(slot_name), String(camera_path)])
		return

	_dialogue_cameras[slot_name] = camera


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
	_register_active_dialogue_npc(selected_timeline)

	interaction_started.emit(self, selected_timeline)

	# Important:
	# NPCBase does NOT switch cameras here.
	# Dialogic controls when cameras change by calling GameManager.change_dialogue_cam(...)
	Dialogic.start_timeline(String(selected_timeline))


func can_interact() -> bool:
	if can_cinematic == false:
		return false

	return true


func _register_active_dialogue_npc(selected_timeline: StringName) -> void:
	var game_manager: Node = get_tree().root.get_node_or_null("GameManager")

	if game_manager == null:
		push_warning("GameManager autoload was not found. NPC camera routing will not work.")
		return

	if game_manager.has_method("begin_npc_dialogue") == false:
		push_warning("GameManager has no begin_npc_dialogue method.")
		return

	game_manager.call("begin_npc_dialogue", self, selected_timeline)


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
	var root: Window = get_tree().root

	# Your current code used World_State.
	# These fallbacks prevent a hard crash if the autoload name changes casing later.
	var possible_names: Array[StringName] = [
		&"World_State",
		&"World_state",
		&"WorldStateGlobal"
	]

	for autoload_name: StringName in possible_names:
		var node: Node = root.get_node_or_null(String(autoload_name))
		if node is WorldState:
			return node as WorldState

	return null


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


func get_dialogue_camera(slot_name: StringName = &"default") -> Camera3D:
	var normalised_slot: StringName = StringName(String(slot_name).strip_edges().to_lower())

	if normalised_slot == &"" or normalised_slot == &"npc" or normalised_slot == &"selfie":
		normalised_slot = &"default"

	if _dialogue_cameras.has(normalised_slot):
		return _dialogue_cameras[normalised_slot] as Camera3D

	return null


func set_dialogue_cam(slot_name: StringName = &"default") -> bool:
	var camera: Camera3D = get_dialogue_camera(slot_name)

	if camera == null and slot_name != &"default":
		camera = get_dialogue_camera(&"default")

	if camera == null:
		push_warning("%s has no dialogue camera for slot: %s" % [name, String(slot_name)])
		return false

	camera.make_current()
	return true


# Legacy function.
# Old GameManager.change_selfie_cam(...) calls still route here.
func set_selfie_cam() -> void:
	set_dialogue_cam(&"default")


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


# Keep this method because your NPC scenes already have Convo_area.body_entered
# connected to this method.
func _on_convo_area_body_entered(body: Node3D) -> void:
	if auto_interact_on_body_entered == false:
		return

	if body is Player:
		interact()
