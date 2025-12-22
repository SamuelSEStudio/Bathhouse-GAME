extends Camera3D
class_name FightCam2D

@export var player_ref: Node3D # attach to player
@export var opponent_ref: Node3D # Attach opponent
@export var player_anchor: Node3D #attach to a point on player eg. chest area rather than root
@export var opponent_anchor: Node3D #attach to point on opponent higher for smaller char, lower for larger

@export_range(0.05, 1.0, 0.01) var center_smooth_time: float = 0.25
@export_range(0.05, 1.0, 0.01) var orbit_smooth_time: float = 0.25
@export_range(0.0, 1.0, 0.01) var anchor_y_influence: float = 0.4
@export_range(0.05, 1.0, 0.01) var smooth_time: float = 0.15
@export_range(1.0, 2.0, 0.01) var padding: float = 1.15              # how much empty frame around targets

@export var min_distance: float = 15.0
@export var max_distance: float = 30.0
@export var vertical_offset: float = 2.5                              # local UP offset (world units)
@export var horizontal_offset: float = 3.0                            # local RIGHT offset (world units)


#@export var yaw_only_aim: bool = true
@export var fixed_pitch_degrees: float = -8.0
# Choose how to supply targets
#@export var target_groups: Array[StringName] = [&"player",&"enemy"]                        # used if use_group == false
@export var lane_right_world: Vector3 = Vector3.FORWARD
@export var keep_player_on_left: bool = false
var _smoothed_center: Vector3 = Vector3.ZERO
var _smoothed_flat_right: Vector3 = Vector3.RIGHT
var _has_prev_frame: bool = false
#var _targets: Array[Node3D] = []

func _ready() -> void:
	
	#process_priority = 100
	call_deferred("make_current") #makes sure that this is the current camera in scene
	#_refresh_targets()
	
func set_player(n: Node3D) -> void:
	player_ref = n

func set_opponent(n: Node3D) -> void:
	opponent_ref = n

#func process(_dt: float) -> void:
	#var cur: Camera3D = get_viewport().get_camera_3d()
	#if cur != self:
		#print("Cam Overide by: ", cur and cur.name)
		#make_current()
func _target_pos(body: Node3D, anchor: Node3D) -> Vector3:
	var body_pos: Vector3 = body.global_transform.origin
	
	if is_instance_valid(anchor):
		var anchor_pos: Vector3 = anchor.global_transform.origin
		
		# XZ from body (stable), Y blended between body and anchor
		var blended_y: float = lerp(body_pos.y, anchor_pos.y, anchor_y_influence)
		return Vector3(body_pos.x, blended_y, body_pos.z)
	
	return body_pos
	
func _physics_process(delta: float) -> void:
	if not is_instance_valid(player_ref):
		return
	
	# --- 1. Raw target positions / center ---
	var p: Vector3 = _target_pos(player_ref, player_anchor)
	var center_raw: Vector3 = p
	var have_enemy: bool = is_instance_valid(opponent_ref)
	var e: Vector3 = p
	
	if have_enemy:
		e = _target_pos(opponent_ref, opponent_anchor)
		center_raw = (p + e) * 0.5
	
	# --- 2. Raw lane-right vector (Tekken rail) ---
	var flat_right_raw: Vector3
	
	if have_enemy:
		# lane_dir = player -> enemy, flattened
		flat_right_raw = e - p
		flat_right_raw.y = 0.0
		var len: float = flat_right_raw.length()
		if len <= 0.001:
			flat_right_raw = Vector3.RIGHT
		else:
			flat_right_raw /= len
		
		# Flip if we *don't* want player on left
		if not keep_player_on_left:
			flat_right_raw = -flat_right_raw
	else:
		# Fallback to world-defined lane
		flat_right_raw = Vector3(lane_right_world.x, 0.0, lane_right_world.z)
		var len2: float = flat_right_raw.length()
		if len2 <= 0.001:
			flat_right_raw = Vector3.RIGHT
		else:
			flat_right_raw /= len2
	
	# --- 3. Init smoothed values on first frame ---
	if not _has_prev_frame:
		_smoothed_center = center_raw
		_smoothed_flat_right = flat_right_raw
		_has_prev_frame = true
	else:
		# Center smoothing (lag in following players)
		var w_center: float = 1.0 - exp(-delta / max(0.0001, center_smooth_time))
		_smoothed_center = _smoothed_center.lerp(center_raw, w_center)
		
		# Orbit smoothing (lag in rail rotation)
		var w_orbit: float = 1.0 - exp(-delta / max(0.0001, orbit_smooth_time))
		_smoothed_flat_right = _smoothed_flat_right.lerp(flat_right_raw, w_orbit)
		if _smoothed_flat_right.length() > 0.0001:
			_smoothed_flat_right = _smoothed_flat_right.normalized()
		else:
			_smoothed_flat_right = flat_right_raw
	
	# --- 4. Build orientation from *smoothed* right vector ---
	var yaw: float = atan2(-_smoothed_flat_right.z, _smoothed_flat_right.x)
	rotation = Vector3(deg_to_rad(fixed_pitch_degrees), yaw, 0.0)
	var basis: Basis = global_basis
	
	# --- 5. Distance using your existing FOV logic, centered on smoothed center ---
	var required_distance: float = min_distance
	if have_enemy:
		required_distance = _compute_required_distance(_smoothed_center, p, e, basis)
	required_distance = clamp(required_distance, min_distance, max_distance)
	
	# --- 6. Desired camera position in CAMERA-LOCAL axes ---
	var desired: Vector3 = _smoothed_center
	desired += basis.x * horizontal_offset      # right
	desired += basis.y * vertical_offset        # up
	desired += basis.z * required_distance      # back
	
	# --- 7. Position smoothing (existing behaviour) ---
	var w_pos: float = 1.0 - exp(-delta / max(0.0001, smooth_time))
	global_position = global_position.lerp(desired, w_pos)
	
	##if have_enemy:
		##center = (player_ref.global_transform.origin + opponent_ref.global_transform.origin) * 0.5
	##else:
		##center = player_ref.global_transform.origin
	#var flat_right: Vector3 = Vector3(lane_right_world.x, 0.0, lane_right_world.z) #ignore y so that camera is stable on jump
	#if flat_right.length() < 0.001:
		#flat_right = Vector3.RIGHT
	#else:
		#flat_right = flat_right.normalized()
	#var yaw: float = atan2(-flat_right.z,flat_right.x)
	#rotation = Vector3(deg_to_rad(fixed_pitch_degrees), yaw, 0.0)
	#var basis: Basis = global_basis
	#
	#var required_distance: float = min_distance
	#if have_enemy:
		#required_distance = _compute_required_distance(center, p, e, basis)
	#required_distance = clamp(required_distance, min_distance, max_distance)
#
	## Desired camera position in CAMERA-LOCAL axes
	#var side_sign: float = -1.0 if keep_player_on_left else 1.0
	#var desired: Vector3 = center
	#desired += basis.x * horizontal_offset      # right
	#desired += basis.y * vertical_offset        # up
	#desired += basis.z * required_distance      # back (along camera forward)
#
	## Smooth all axes with a delta-aware weight
	#var w: float = 1.0 - exp(-delta / max(0.0001, smooth_time))
	#global_position = global_position.lerp(desired, w)
	#if yaw_only_aim:
		#var to_center: Vector3 = center - global_position
		#var flat: Vector3 = Vector3(to_center.x,0.0,to_center.z)
		#if flat.length() > 0.0001:
			#var y_rot: float = atan2(-flat.x,-flat.z)
			#rotation= Vector3(deg_to_rad(fixed_pitch_degrees),y_rot,0.0)
	## Aim at the center (full look). For yaw-only, lock pitch from a stored angle.
	#else:
		#look_at(center, Vector3.UP)

#func _compute_center() -> Vector3:
	#var acc: Vector3 = Vector3.ZERO
	#for n: Node3D in _targets:
		#acc += n.global_transform.origin
	#return acc / float(_targets.size())

func _compute_required_distance(center: Vector3, p: Vector3, e: Vector3, basis: Basis) -> float:
	# Compute screen-space extents in camera local axes
	var half_vfov: float = deg_to_rad(fov) * 0.5                          # vertical FOV
	var aspect: float = float(get_viewport().size.x) / float(get_viewport().size.y)
	var half_hfov: float = atan(tan(half_vfov) * aspect)                  # horizontal FOV

	var max_h: float = 0.0
	var max_v: float = 0.0

	for pos: Vector3 in [p,e]:
		var rel: Vector3 = pos - center
		#var offset: Vector3 = n.global_transform.origin - center
		var h_off: float = rel.dot(basis.x)#right
		var v_off: float = rel.dot(basis.y)#up
		max_h = max(max_h, abs(h_off))                     # horizontal spread
		max_v = max(max_v, abs(v_off))                     # vertical spread

	var dist_h: float = (max_h / tan(half_hfov)) 
	var dist_v: float = (max_v / tan(half_vfov)) 
	return max(dist_h, dist_v) * padding

#func _refresh_targets() -> void:
	#_targets.clear()
	#var seen: Dictionary = {}  # de-dup if something is in multiple groups
	#for g: StringName in target_groups:
		#for n: Node in get_tree().get_nodes_in_group(g):
			#var n3d: Node3D = n as Node3D
			#if n3d and not seen.has(n3d):
				#_targets.append(n3d)
				#seen[n3d] = true
