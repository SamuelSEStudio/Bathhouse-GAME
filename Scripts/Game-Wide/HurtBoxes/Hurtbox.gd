extends Area3D
class_name HurtBox

@export var owner_combatant_path: NodePath
@export var owner_team: int = 0
var combatant: Combatant

@onready var col: CollisionShape3D = $CollisionShape3D
@onready var dbg: MeshInstance3D = $MeshInstance3D

# Region & desired world targets (set by the tool)
@export var region: StringName = &""
@export var target_world_size: Vector3 = Vector3.ZERO
@export var target_world_offset: Vector3 = Vector3.ZERO
@export var enforce_world_space: bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	combatant = get_node_or_null(owner_combatant_path) as Combatant
	monitoring = true
	_ensure_collision_shape()
	_apply_world_targets()
	debug_print_world_size(&"Head")
	#debug_shape_and_scale()

func _ensure_collision_shape() -> void:
	if col == null:
		col = CollisionShape3D.new()
		col.name = "CollisionShape3D"
		add_child(col, true)
		col.owner = owner
	var box: BoxShape3D = col.shape as BoxShape3D
	if box == null:
		box = BoxShape3D.new()
		col.shape = box
func _apply_world_targets() -> void:
	var box := col.shape as BoxShape3D
	if box == null:
		return
	if enforce_world_space and target_world_size != Vector3.ZERO:
		var self_scale: Vector3 = global_transform.basis.get_scale().abs()
		box.size = Vector3(
			target_world_size.x / max(0.0001, self_scale.x),
			target_world_size.y / max(0.0001, self_scale.y),
			target_world_size.z / max(0.0001, self_scale.z)
		)
	if enforce_world_space and target_world_offset != Vector3.ZERO:
		var parent3d: Node3D = get_parent() as Node3D
		if parent3d:
			var parent_scale: Vector3 = parent3d.global_transform.basis.get_scale().abs()
			transform.origin = Vector3(
				target_world_offset.x / max(0.0001, parent_scale.x),
				target_world_offset.y / max(0.0001, parent_scale.y),
				target_world_offset.z / max(0.0001, parent_scale.z)
			)
	
func debug_print_world_size(tag: StringName = &"") -> void:
	if col == null:
		push_warning("HurtBox: no CollisionShape3D")
		return
	var shape := col.shape as BoxShape3D
	if shape == null:
		print("HurtBox has no BoxShape3D")
		return
	# Node’s world scale (includes Skeleton/BoneAttachment scale)
	var s: Vector3 = global_transform.basis.get_scale().abs()
	# BoxShape3D.size is full width/height/depth in local space
	var world_size: Vector3 = shape.size * s
	print("[HB] ", tag, " world_size=", world_size, "  world_pos=", global_transform.origin)
	
#func sync_debug_mesh_to_shape() -> void:
	#var shape := col.shape as BoxShape3D
	#if shape == null or dbg == null: return
#
	## Prefer a BoxMesh so we set size directly (avoid scale confusion)
	#var bm := BoxMesh.new()
	#bm.size = shape.size  # full size, not half-extents
	#dbg.mesh = bm
#
	## Keep node scales neutral so we don't double-scale
	#scale = Vector3.ONE
	#dbg.scale = Vector3.ONE
#func debug_shape_and_scale(tag: StringName = &"") -> void:
	#var col := $CollisionShape3D
	#var shape := col.shape as BoxShape3D
	#var node_scale: Vector3 = global_transform.basis.get_scale().abs()
	#if shape == null:
		#print("[HB] ", tag, " no BoxShape3D")
		#return
	#print("[HB] ", tag, " shape.size(local)=", shape.size,
		#"  node_scale=", node_scale,
		#"  world_size=", shape.size * node_scale)
		#
#func _debug_after_apply() -> void:
	#debug_shape_and_scale()
	#debug_print_world_size(&"Head")
