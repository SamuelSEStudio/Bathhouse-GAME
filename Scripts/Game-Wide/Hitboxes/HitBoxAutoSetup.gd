@tool
extends Node
class_name HitboxAutoSetup

@export var hitbox_scene: PackedScene
@export var skel: Skeleton3D
@export var profile: HitProfile
@export var owner_combatant_path: NodePath = ^"../Combatant"
@export var selected_move: StringName = &""

const LAYER_HITBOX: int = 1 << 5
const MASK_HITBOX: int = 1 << 6

@export_category("Actions")
@export var build_selected: bool: set = _build_selected_btn
@export var build_all: bool: set = _build_all_btn
@export var remove_selected: bool: set = _remove_selected_btn
@export var remove_all: bool: set = _remove_all_btn

func _build_selected_btn(_v: bool) -> void:
	if Engine.is_editor_hint() and selected_move != StringName():
		var a := profile.find_by_move(selected_move)
		if a: _build_asset(a)

func _build_all_btn(_v: bool) -> void:
	if Engine.is_editor_hint():
		for a in profile.all_for_build():
			_build_asset(a)

func _remove_selected_btn(_v: bool) -> void:
	if Engine.is_editor_hint() and selected_move != StringName():
		var a := profile.find_by_move(selected_move)
		if a: _remove_asset(a)

func _remove_all_btn(_v: bool) -> void:
	if Engine.is_editor_hint():
		for a in profile.all_for_build():
			_remove_asset(a)

func _build_asset(a: AttackAsset) -> void:
	if skel == null or hitbox_scene == null or a == null: return
	var bone := _find_first_bone(skel, a.bone_names)
	if String(bone) == "": return
	var ba := _ensure_ba(skel, bone)          # BA_HIT_<bone>
	var hb := ba.get_node_or_null(String(a.node_name)) as Area3D
	if hb == null:
		hb = hitbox_scene.instantiate() as Area3D
		hb.name = String(a.node_name)
		ba.add_child(hb, true)
		hb.owner = ba.owner
	# wire
	hb.collision_layer = LAYER_HITBOX
	hb.collision_mask  = MASK_HITBOX
	var h := hb as HitBox
	if h:
		h.owner_combatant_path = owner_combatant_path
		h.data                 = a.data
		h.target_world_size    = a.target_world_size
		h.target_world_offset  = a.target_world_offset
		h.show_debug_mesh      = a.show_debug_mesh
		h.enforce_world_space  = true
	# unique editor shape
	var col := hb.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col == null:
		col = CollisionShape3D.new(); col.name = "CollisionShape3D"
		hb.add_child(col, true); col.owner = hb.owner
	if col.shape == null:
		var box := BoxShape3D.new()
		box.resource_local_to_scene = true
		col.shape = box
		
	print("[HurtboxAutoSetup] Built hitbox")

func _remove_asset(a: AttackAsset) -> void:
	var prefix := "BA_HIT_"
	for c in skel.get_children():
		var ba := c as BoneAttachment3D
		if ba == null or not String(ba.name).begins_with(prefix): continue
		var child := ba.get_node_or_null(String(a.node_name))
		if child != null and child is Area3D:
			child.queue_free()

func _find_first_bone(s: Skeleton3D, names: PackedStringArray) -> StringName:
	for n in names:
		if s.find_bone(n) != -1: return StringName(n)
	return StringName()

func _ensure_ba(s: Skeleton3D, bone: StringName) -> BoneAttachment3D:
	var name := "BA_HIT_%s" % [bone]
	var ba := s.get_node_or_null(name) as BoneAttachment3D
	if ba != null: ba.bone_name = bone; return ba
	ba = BoneAttachment3D.new()
	ba.name = name; ba.bone_name = bone
	s.add_child(ba, true); ba.owner = s.owner
	return ba
