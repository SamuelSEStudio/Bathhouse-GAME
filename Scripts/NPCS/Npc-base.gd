class_name NPCBase
extends Node3D

signal interaction_started(npc: NPCBase, timeline_name: StringName)
signal interaction_finished(npc: NPCBase)
signal schedule_package_changed(npc: NPCBase, package: NPCSchedulePackage)
signal schedule_service_availability_changed(npc: NPCBase, is_available: bool)

@export_group("NPC Data")
@export var npc_profile: NPCProfile
@export var timeline_name: StringName = &""

@export_group("Visual Model")
@export var model_scene: PackedScene
@export var model_mount_path: NodePath
@export var clear_existing_visuals_on_spawn: bool = true
@export var auto_find_animation_player_from_model: bool = true

@export_group("Node Paths")
@export var animation_player_path: NodePath
@export var cooldown_timer_path: NodePath
@export var convo_area_path: NodePath

@export_group("Dialogue Cameras")
@export var default_dialogue_camera_path: NodePath
@export var close_dialogue_camera_path: NodePath
@export var side_dialogue_camera_path: NodePath
@export var dramatic_dialogue_camera_path: NodePath

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
var spawned_model: Node3D = null

var can_cinematic: bool = true

var _dialogue_cameras: Dictionary = {}
var _is_currently_interacting: bool = false
var _current_timeline_name: StringName = &""

var current_schedule_package: NPCSchedulePackage = null
var current_schedule_contexts: Array[StringName] = []
var current_service_available: bool = true

func _ready() -> void:
	add_to_group("npcs")

	_spawn_model_scene()
	_resolve_nodes()
	_cache_default_animation()
	_connect_signals()
	_connect_world_state_schedule_signal()
	_refresh_schedule_from_world_state()

func _spawn_model_scene() -> void:
	if model_scene == null:
		return

	var mount: Node3D = _get_model_mount()

	if mount == null:
		push_warning("%s has no valid model mount path." % name)
		return

	if clear_existing_visuals_on_spawn:
		for child: Node in mount.get_children():
			child.queue_free()

	var instance: Node = model_scene.instantiate()

	if instance is Node3D == false:
		push_warning("%s model_scene root must extend Node3D." % name)
		instance.queue_free()
		return

	spawned_model = instance as Node3D
	mount.add_child(spawned_model)

	spawned_model.position = Vector3.ZERO
	spawned_model.rotation = Vector3.ZERO
	spawned_model.scale = Vector3.ONE

	if auto_find_animation_player_from_model:
		var found_animation_player: AnimationPlayer = _find_animation_player_recursive(spawned_model)
		if found_animation_player != null:
			animation_player = found_animation_player


func _get_model_mount() -> Node3D:
	if String(model_mount_path) == "":
		return self

	var mount: Node3D = get_node_or_null(model_mount_path) as Node3D
	return mount


func _find_animation_player_recursive(start_node: Node) -> AnimationPlayer:
	if start_node is AnimationPlayer:
		return start_node as AnimationPlayer

	for child: Node in start_node.get_children():
		var found: AnimationPlayer = _find_animation_player_recursive(child)
		if found != null:
			return found

	return null


func _resolve_nodes() -> void:
	if animation_player == null:
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

	_resolve_dialogue_cameras_from_spawned_model()
	_resolve_dialogue_cameras_from_exported_paths()
	
func _resolve_dialogue_cameras_from_spawned_model() -> void:
	if spawned_model == null:
		return

	var camera_root: Node = spawned_model.get_node_or_null("DialogueCameras")

	if camera_root == null:
		return

	_add_dialogue_camera_from_node(&"default", camera_root.get_node_or_null("DefaultCam"))
	_add_dialogue_camera_from_node(&"close", camera_root.get_node_or_null("CloseCam"))
	_add_dialogue_camera_from_node(&"side", camera_root.get_node_or_null("SideCam"))
	_add_dialogue_camera_from_node(&"dramatic", camera_root.get_node_or_null("DramaticCam"))


func _resolve_dialogue_cameras_from_exported_paths() -> void:
	var default_path: NodePath = default_dialogue_camera_path

	if String(default_path) == "" and String(selfie_cam_path) != "":
		default_path = selfie_cam_path

	_add_dialogue_camera(&"default", default_path)
	_add_dialogue_camera(&"close", close_dialogue_camera_path)
	_add_dialogue_camera(&"side", side_dialogue_camera_path)
	_add_dialogue_camera(&"dramatic", dramatic_dialogue_camera_path)


func _add_dialogue_camera_from_node(slot_name: StringName, node: Node) -> void:
	if node == null:
		return

	var camera: Camera3D = node as Camera3D

	if camera == null:
		push_warning("%s dialogue camera slot '%s' was not a Camera3D." % [name, String(slot_name)])
		return

	_dialogue_cameras[slot_name] = camera

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

	Dialogic.start_timeline(String(selected_timeline))


func can_interact() -> bool:
	if can_cinematic == false:
		return false

	if is_interaction_available_from_schedule() == false:
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
	_try_open_profile_service_after_dialogue()
	interaction_finished.emit(self)

func _try_open_profile_service_after_dialogue() -> void:
	if npc_profile == null:
		return

	if npc_profile.opens_service_after_dialogue == false:
		return

	if npc_profile.service_type == NPCProfile.ServiceType.NONE:
		return

	var service_manager: ServiceManagerService = get_tree().root.get_node_or_null("ServiceManager") as ServiceManagerService

	if service_manager == null:
		push_warning("ServiceManager autoload was not found.")
		return

	service_manager.open_service_for_profile(npc_profile, self)
func _on_cinematic_cooldown_timeout() -> void:
	can_cinematic = true


func _on_convo_area_body_entered(body: Node3D) -> void:
	if auto_interact_on_body_entered == false:
		return
		
	if body is Player:
		interact()


func refresh_schedule() -> void:
	_refresh_schedule_from_world_state()


func has_schedule_context(context_id: StringName) -> bool:
	return current_schedule_contexts.has(context_id)


func is_service_available_from_schedule() -> bool:
	if npc_profile == null:
		return false

	if npc_profile.schedule_resource == null:
		return true

	return current_service_available


func is_interaction_available_from_schedule() -> bool:
	if current_schedule_package == null:
		return true

	return current_schedule_package.allows_interaction()


func get_current_schedule_package() -> NPCSchedulePackage:
	return current_schedule_package


func _connect_world_state_schedule_signal() -> void:
	var world_state: WorldState = _get_world_state()

	if world_state == null:
		return

	if world_state.time_block_changed.is_connected(_on_world_time_block_changed):
		return

	world_state.time_block_changed.connect(_on_world_time_block_changed)


func _on_world_time_block_changed(_new_time_block: int) -> void:
	_refresh_schedule_from_world_state()


func _refresh_schedule_from_world_state() -> void:
	if npc_profile == null:
		return

	if npc_profile.uses_world_schedule == false:
		return

	if npc_profile.schedule_resource == null:
		current_schedule_package = null
		current_schedule_contexts.clear()
		current_service_available = true
		return

	var world_state: WorldState = _get_world_state()
	var package: NPCSchedulePackage = npc_profile.schedule_resource.get_package_for_current_world_state(world_state)

	_apply_schedule_package(package)


func _apply_schedule_package(package: NPCSchedulePackage) -> void:
	current_schedule_package = package
	current_schedule_contexts.clear()

	if current_schedule_package == null:
		current_service_available = true
		visible = true
		return

	current_schedule_contexts.append_array(current_schedule_package.schedule_contexts)
	current_service_available = current_schedule_package.allows_service()

	_apply_schedule_visibility(current_schedule_package)
	_apply_schedule_location(current_schedule_package)
	_apply_schedule_animation(current_schedule_package)

	schedule_package_changed.emit(self, current_schedule_package)
	schedule_service_availability_changed.emit(self, current_service_available)


func _apply_schedule_visibility(package: NPCSchedulePackage) -> void:
	visible = package.is_visible_in_world()

	set_process(visible)
	set_physics_process(visible)

	var convo_area_node: Area3D = convo_area

	if convo_area_node != null:
		convo_area_node.monitoring = package.allows_interaction()
		convo_area_node.monitorable = package.allows_interaction()


func _apply_schedule_location(package: NPCSchedulePackage) -> void:
	if package.snap_to_marker == false:
		return

	if package.location_id == &"":
		return

	var marker: NPCScheduleMarker = _find_schedule_marker(package.location_id)

	if marker == null:
		push_warning(
			"%s could not find NPCScheduleMarker with id: %s"
			% [name, String(package.location_id)]
		)
		return

	global_transform = marker.get_marker_transform()


func _apply_schedule_animation(package: NPCSchedulePackage) -> void:
	if package.idle_animation == &"":
		return

	play_animation(String(package.idle_animation))


func _find_schedule_marker(location_id: StringName) -> NPCScheduleMarker:
	var markers: Array[Node] = get_tree().get_nodes_in_group("npc_schedule_markers")

	for marker_node: Node in markers:
		var marker: NPCScheduleMarker = marker_node as NPCScheduleMarker

		if marker == null:
			continue

		if marker.matches_id(location_id):
			return marker

	return null


func _debug_print_schedule() -> void:
	if current_schedule_package == null:
		print("%s has no active schedule package." % name)
		return

	print(
		"%s schedule package: %s | service available: %s"
		% [
			name,
			current_schedule_package.get_debug_label(),
			str(current_service_available)
		]
	)
