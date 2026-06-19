@tool
class_name NPCScheduleMarker
extends Node3D

@export var marker_id: StringName = &""
@export var marker_display_name: String = ""
@export var show_debug_marker: bool = true

var _debug_mesh_instance: MeshInstance3D = null


func _enter_tree() -> void:
	add_to_group("npc_schedule_markers")


func _ready() -> void:
	if Engine.is_editor_hint():
		_refresh_debug_marker()
	else:
		_hide_debug_marker()


func matches_id(target_id: StringName) -> bool:
	return marker_id != &"" and marker_id == target_id


func get_marker_transform() -> Transform3D:
	return global_transform


func _refresh_debug_marker() -> void:
	if show_debug_marker == false:
		_hide_debug_marker()
		return

	if _debug_mesh_instance == null:
		_debug_mesh_instance = MeshInstance3D.new()
		_debug_mesh_instance.name = "DebugMarkerMesh"
		add_child(_debug_mesh_instance)

		var sphere_mesh: SphereMesh = SphereMesh.new()
		sphere_mesh.radius = 0.15
		sphere_mesh.height = 0.3
		_debug_mesh_instance.mesh = sphere_mesh

	_debug_mesh_instance.visible = true


func _hide_debug_marker() -> void:
	if _debug_mesh_instance != null:
		_debug_mesh_instance.visible = false
