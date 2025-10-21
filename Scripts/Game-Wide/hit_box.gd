extends Area3D
class_name Hitbox

@export var data: AttackData
#@export var debug_mesh: MeshInstance3d
@export var active: bool = false setget set_active

var _already_hit: Dictionary {} #target -> hits count

signal hit_landed(target: Node)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	monitoring = false
	area_entered.connect(_on_area_entered)
	_set_debug_visable(false)
func set_active(v: bool) -> void:
	active = v
	monitoring = v
	if v:
		_already_hit.clear()
	_set_debug_visiable(v)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func begin_active(frames: int)-> void:
	set_active(true)
	var sec: float = float(frames) / float(Engine.get_physics_ticks_per_second())
	get_tree().create_timer(sec).timeout.connect(end_active)

func end_active()->void:
	set_active(false)

func _on_area_entered(area: Area3D) -> void:
	if not active: return
	if not (area is HurtBox): return
	var hb: HurtBox = area as HurtBox
	if data == null or hb.combatant == null: return
	if hb.owner_team == data.owner_team: return
	
	var count: int = _already_hit.get(hb, 0)
	if (not data.can_multi_hit and count >= 1) or (data.can_multi_hit and count >= data.max_hits_per_target):
		return
	_already_hit[hb] = count +1
	
	hb.combatant.receive_hit(data.damage, data.knockback, data.hitstun_frames, data.hitstop_frames)
	emit_signal("hit_landed", hb)
	
func set_debug_visible(v: bool)-> void:
	if is_instance_valid(debug_mesh):
		debug_mesh.visible = v
