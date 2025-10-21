extends Area3D
class_name HurtBox

@export var owner_combatant_path: NodePath
@export var owner_team: int = 0
var combatant: Combatant

@onready var col: CollisionShape3D = $CollisionShape3D
@onready var dbg: MeshInstance3D = $MeshInstance3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	combatant = get_node_or_null(owner_combatant_path) as Combatant
	monitoring = true
	debug_print_world_size(&"Head")
	sync_debug_mesh_to_shape()
	debug_shape_and_scale()
	
func debug_print_world_size(tag: StringName = &"") -> void:
	var shape := col.shape as BoxShape3D
	if shape == null:
		print("HurtBox has no BoxShape3D")
		return
	# Node’s world scale (includes Skeleton/BoneAttachment scale)
	var s: Vector3 = global_transform.basis.get_scale().abs()
	# BoxShape3D.size is full width/height/depth in local space
	var world_size: Vector3 = shape.size * s
	print("[HB] ", tag, " world_size=", world_size, "  world_pos=", global_transform.origin)
	
func sync_debug_mesh_to_shape() -> void:
	var shape := col.shape as BoxShape3D
	if shape == null or dbg == null: return

	# Prefer a BoxMesh so we set size directly (avoid scale confusion)
	var bm := BoxMesh.new()
	bm.size = shape.size  # full size, not half-extents
	dbg.mesh = bm

	# Keep node scales neutral so we don't double-scale
	scale = Vector3.ONE
	dbg.scale = Vector3.ONE
func debug_shape_and_scale(tag: StringName = &"") -> void:
	var col := $CollisionShape3D
	var shape := col.shape as BoxShape3D
	var node_scale: Vector3 = global_transform.basis.get_scale().abs()
	if shape == null:
		print("[HB] ", tag, " no BoxShape3D")
		return
	print("[HB] ", tag, " shape.size(local)=", shape.size,
		"  node_scale=", node_scale,
		"  world_size=", shape.size * node_scale)
