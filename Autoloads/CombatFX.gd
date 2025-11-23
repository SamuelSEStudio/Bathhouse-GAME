extends Node
class_name CombatFX

# Global toggles (accessibility / perf)
@export var enable_hitstop: bool = true
@export var enable_shake: bool = true
@export var enable_vfx: bool = true
@export var enable_sfx: bool = true

# Optional per-project fallbacks if AttackData fields are unset or zero
@export var default_hitstop_sec: float = 0.0
@export var default_hitstop_scale: float = 0.05
@export var default_shake_dur: float = 0.0
@export var default_shake_mag: float = 0.05
@export var fallback_vfx: PackedScene
@export var fallback_sfx: AudioStream

# Discovery options
@export var hitbox_group: StringName = &"HitBoxes"

func _ready() -> void:
	# Connect to all existing HitBoxes
	_connect_existing_hitboxes()
	# Auto-connect to future ones
	get_tree().node_added.connect(_on_node_added)

func _connect_existing_hitboxes() -> void:
	var nodes: Array[Node] = get_tree().get_nodes_in_group(hitbox_group)
	for n in nodes:
		var hb: HitBox = n as HitBox
		if hb != null and not hb.hit_landed.is_connected(_on_hit_landed):
			hb.hit_landed.connect(_on_hit_landed)

func _on_node_added(node: Node) -> void:
	var hb: HitBox = node as HitBox
	if hb != null and not hb.hit_landed.is_connected(_on_hit_landed):
		hb.hit_landed.connect(_on_hit_landed)

func _on_hit_landed(hitbox: HitBox, target: HurtBox, world_pos: Vector3) -> void:
	var a: AttackData = hitbox.data

	# --- HITSTOP ---
	if enable_hitstop:
		var hs_sec: float = default_hitstop_sec
		var hs_scale: float = default_hitstop_scale
		if a != null:
			if a.hitstop_sec > 0.0:
				hs_sec = a.hitstop_sec
			if a.hitstop_scale > 0.0:
				hs_scale = a.hitstop_scale
		if hs_sec > 0.0:
			Hitstop_Loader.apply(hs_sec, hs_scale)

	# --- CAMERA SHAKE ---
	if enable_shake:
		var dur: float = default_shake_dur
		var mag: float = default_shake_mag
		if a != null:
			if a.camera_shake_dur > 0.0:
				dur = a.camera_shake_dur
			if a.camera_shake_mag > 0.0:
				mag = a.camera_shake_mag
		if dur > 0.0 and mag > 0.0:
			CameraShake_Loader.kick(dur, mag)

	# --- VFX ---
	if enable_vfx:
		var vfx: PackedScene = null
		if a != null and a.vfx_scene != null:
			vfx = a.vfx_scene
		elif fallback_vfx != null:
			vfx = fallback_vfx
		if vfx != null:
			var fx: Node3D = vfx.instantiate() as Node3D
			if fx != null:
				fx.global_transform.origin = world_pos
				get_tree().current_scene.add_child(fx)

	# --- SFX ---
	if enable_sfx:
		var stream: AudioStream = null
		if a != null and a.sfx != null:
			stream = a.sfx
		elif fallback_sfx != null:
			stream = fallback_sfx
		if stream != null:
			var p: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
			p.stream = stream
			p.global_transform.origin = world_pos
			get_tree().current_scene.add_child(p)
			p.play()
