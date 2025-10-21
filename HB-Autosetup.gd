@tool
extends Node
class_name HurtboxAutoSetup

# ---- Configure these to match your project ----
@export var hurtbox_scene: PackedScene
@export var skel: Skeleton3D
@export var combatant_path: NodePath = ^"../Combatant"
@export var team_id: int = 0

# Physics layers/masks (example: 4 = HitBoxes, 5 = HurtBoxes)
const LAYER_HURTBOX: int = 1 << 6
const MASK_HURTBOX:  int = 1 << 5

# Name hints for common rigs — adjust to your bones
@export var region_bones: Dictionary = {
	"Head":  PackedStringArray(["mixamorig_Head"]),
	"Torso": PackedStringArray(["mixamorig_Spine2", "mixamorig_Spine1", "mixamorig_Spine", "Chest", "chest"]),
	"Hips":  PackedStringArray(["mixamorig_Hips", "Root", "pelvis", "Hips_1"]),
}

# Per-region default shapes (half-extents) and local offsets (meters)
@export var region_shapes: Dictionary = {
	"Head":  {"extents": Vector3(0.16, 0.16, 1.16), "offset": Vector3(0.00, 0.18, 0.00)},
	"Torso": {"extents": Vector3(0.22, 0.28, 0.18), "offset": Vector3(0.00, 0.05, 0.00)},
	"Hips":  {"extents": Vector3(0.24, 0.18, 0.20), "offset": Vector3(0.00, 0.00, 0.00)},
}

# UI buttons in the Inspector
@export_category("Actions")
@export var build_hurtboxes: bool:
	set = _build_button
@export var rebuild_hurtboxes: bool:
	set = _rebuild_button
@export var remove_hurtboxes: bool:
	set = _remove_button

func _get_skeleton() -> Skeleton3D:
	var s: Skeleton3D = skel
	if s == null:
		push_error("[HurtboxAutoSetup] Skeleton3D not found at: %s")
	return s

func _get_hurtbox_packed() -> PackedScene:
	var ps: PackedScene = hurtbox_scene
	if ps == null:
		push_error("[HurtboxAutoSetup] Could not load HurtBox scene at: %s")
	return ps
	
func _debug_dump_bones(skel:Skeleton3D) -> void:
	for i in skel.get_bone_count():
		print(i, ":", skel.get_bone_name(i))
		
func _find_bone_name(skel: Skeleton3D, options: PackedStringArray) -> StringName:
	var tried: Array[String] = []
	for n in options:
		tried.append(n)
		var idx: int = skel.find_bone(n)
		if idx != -1:
			print("[HB] Found bone: ", n," (idx=", idx, ")")
			return StringName(n)
	# Fallback to first bone if nothing matched
	push_warning("[HB no match. Tried->",tried,".Fallback->", skel.get_bone_name(0))
	return StringName(skel.get_bone_name(0))

func _region_ba_name(region: StringName, bone: StringName) -> String:
	return "BA_%s_%s" % [region, bone]

func _create_or_get_ba(skel: Skeleton3D, region: StringName, bone: StringName) -> BoneAttachment3D:
	var want: String = _region_ba_name(region, bone)
	var existing: BoneAttachment3D = skel.get_node_or_null(want) as BoneAttachment3D
	if existing:
		existing.bone_name = bone
		return existing
	var ba := BoneAttachment3D.new()
	ba.name = want
	ba.bone_name = bone
	skel.add_child(ba, true)
	ba.owner = skel.owner
	return ba

func _wire_hurtbox(hb: Area3D) -> void:
	# Set layers/masks if your HurtBox script doesn't already do it
	hb.collision_layer = LAYER_HURTBOX
	hb.collision_mask  = MASK_HURTBOX
	# Try to set exported fields if present
	if hb.has_method("set"):
		if hb.has_meta("_owner_team") or "owner_team" in hb:
			hb.set("owner_team", team_id)
		if hb.has_meta("_owner_combatant_path") or "owner_combatant_path" in hb:
			hb.set("owner_combatant_path", combatant_path)

func _ensure_shape(hb: Node, region: StringName) -> void:
	var col: CollisionShape3D = hb.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col == null:
		col = CollisionShape3D.new()
		hb.add_child(col, true)
		col.owner = hb.owner
	var box := BoxShape3D.new()
	var ext: Vector3 = (region_shapes[region]["extents"] as Vector3) * 2.0
	box.size = ext
	col.shape = box
	var off: Vector3 = region_shapes[region]["offset"]
	(hb as Node3D).transform.origin = Vector3.ZERO

# ----- Buttons -----
func _build_button(_v: bool) -> void:
	if Engine.is_editor_hint():
		_build(false)

func _rebuild_button(_v: bool) -> void:
	if Engine.is_editor_hint():
		_build(true)

func _remove_button(_v: bool) -> void:
	if Engine.is_editor_hint():
		_remove_all()

# Core
func _build(force_rebuild: bool) -> void:
	if skel == null or hurtbox_scene == null:
		return
	_debug_dump_bones(skel)

	if force_rebuild:
		_remove_all()

	for region in region_bones.keys():
		var bone: StringName = _find_bone_name(skel, region_bones[region])
		var ba: BoneAttachment3D = _create_or_get_ba(skel, StringName(region), bone)

		# Only add HurtBox if none exists under BA
		var existing_hb: Area3D = ba.get_node_or_null("HurtBox") as Area3D
		if existing_hb == null:
			var hb := hurtbox_scene.instantiate() as Area3D
			hb.name = "HurtBox"
			ba.add_child(hb, true)
			hb.owner = ba.owner
			var bidx: int = skel.find_bone(bone)
			print("[HB] Bone =", bone,
			" idx=", bidx,
			" BA parent==Skeleton?", ba.get_parent() == skel,
			" HB parent==BA?", hb.get_parent() == ba)

			await get_tree().process_frame
			print("[HB] bone global:", skel.get_bone_global_pose(bidx).origin,
			" BA global:", ba.global_transform.origin,
			" HB global:", (hb as Node3D).global_transform.origin)
			_wire_hurtbox(hb)
			_ensure_shape(hb, StringName(region))
		else:
			_wire_hurtbox(existing_hb)
			_ensure_shape(existing_hb, StringName(region))

	print("[HurtboxAutoSetup] Built hurtboxes.")

func _remove_all() -> void:
	if skel == null:
		return
	for c in skel.get_children():
		if c is BoneAttachment3D and String(c.name).begins_with("BA_"):
			c.queue_free()
	print("[HurtboxAutoSetup] Removed all BA_* hurtboxes.")
