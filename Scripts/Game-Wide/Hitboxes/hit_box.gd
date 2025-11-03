extends Area3D
class_name HitBox

signal hit_landed(hitbox: HitBox, target: HurtBox, world_pos: Vector3)

@export var data: AttackData
@export var owner_combatant_path: NodePath
#@export var debug_mesh: MeshInstance3d
@export var owner_team_override: int = -1 # if >=0 overrides data.owner_team

@export var target_world_size: Vector3 = Vector3(0.35, 0.25, 0.25)
@export var target_world_offset: Vector3 = Vector3(0.20, 0.10, 0.40)
@export var enforce_world_space: bool = true
@export var show_debug_mesh: bool = false

var combatant: Combatant
var _active: bool = false
var _already_hit: Dictionary = {} #target -> hits count

@onready var col: CollisionShape3D = $CollisionShape3D
@onready var dbg: MeshInstance3D = $MeshInstance3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	monitorable = true
	monitoring = false
	combatant = get_node_or_null(owner_combatant_path) as Combatant
	
	_ensure_collision_shape()
	_apply_world_targets()
	area_entered.connect(_on_area_entered)
	_update_debug_visuals()
	var hb: HitBox = self as HitBox
	if hb != null:
		hb.hit_landed.connect(_on_hit_landed)

func _on_hit_landed(hitbox: HitBox, target: HurtBox, world_pos: Vector3) -> void:
	print("JAB HIT! hitbox=", hitbox.get_path(), " target=", target.get_path(), " pos=", world_pos)
	Hitstop_Loader.apply(0.06, 0.05)
	
func _update_debug_visuals()-> void:
	if dbg != null:
		dbg.visible = show_debug_mesh and _active
		
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
		var s: Vector3 = global_transform.basis.get_scale().abs()
		box.size = Vector3(
			target_world_size.x / max(0.0001, s.x),
			target_world_size.y / max(0.0001, s.y),
			target_world_size.z / max(0.0001, s.z)
		)
	if enforce_world_space and target_world_offset != Vector3.ZERO:
		var parent3d: Node3D = get_parent() as Node3D
		if parent3d:
			var ps: Vector3 = parent3d.global_transform.basis.get_scale().abs()
			transform.origin = Vector3(
				target_world_offset.x / max(0.0001, ps.x),
				target_world_offset.y / max(0.0001, ps.y),
				target_world_offset.z / max(0.0001, ps.z)
			)

func activate(duration_seconds: float = 0.10) -> void:
	_active = true
	_already_hit.clear()
	monitoring = true
	_update_debug_visuals()
	print("[HitBox]", name, "Active for ", duration_seconds, "s")
	var t: SceneTreeTimer = get_tree().create_timer(duration_seconds, false)
	t.timeout.connect(deactivate)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func begin_active(frames: int)-> void:
	var hz: int = Engine.get_physics_ticks_per_second()
	var sec: float = float(frames) / float(hz)
	activate(sec)

func deactivate()->void:
	_active = false
	monitoring = false
	_update_debug_visuals()

func _on_area_entered(other: Area3D) -> void:
	if not _active: return
	var hb: HurtBox = other as HurtBox
	if hb == null: return
	
	var my_team: int = 0
	my_team = int(combatant.team_id)
	if data == null or hb.combatant == null: 
		#if data == null:
			#print("no data")
		#elif hb.combatant == null:
			#print("no combatant")
		return
	if hb.owner_team == my_team: return
	
	var key: RID = hb.get_rid()
	var hits_so_far: int = int(_already_hit.get(key, 0))
	var allowed_hits: int = 1
	var multi_enabled: bool = false
	if data != null:
		multi_enabled = data.can_multi_hit
	if multi_enabled:
		allowed_hits = max(1, data.max_hits_per_target)
	else:
		allowed_hits = 1
		
	if hits_so_far >= allowed_hits:
		return

	_already_hit[key] = hits_so_far + 1

# apply effects
	if data != null and hb.combatant != null:
		hb.combatant.receive_hit(
		data.damage,
		data.knockback,
		data.hitstun_frames,
		data.hitstop_frames
	)
	
	emit_signal("hit_landed",self, hb, global_transform.origin)
	
#func set_debug_visible(v: bool)-> void:
	#if is_instance_valid(debug_mesh):
		#debug_mesh.visible = v
