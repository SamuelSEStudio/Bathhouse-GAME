extends State
class_name PracticeMoveState
#
#@export var practice_idle_state: State
#@export var fall_state: State 
#
#@export var walk_speed := 4.0
#@export var sidestep_speed := 3.0
#@export var backstep_speed := 8.0
#@export var backstep_duration := 0.25
#
#@export var attack_actions: Array[StringName] = [&"Attack",&"LightAttack", &"HeavyAttack"]
#@export var run_action: StringName = &"Run"
#
#@export var target_group: StringName =&"enemies"
#@export var target_search_radius := 25.0
#@export var lane_center:=Node3D
#@export var dummy_target_distance := 3.5
#
#@export var lane_half_width := 2.5
#
#var _side_axis := Vector3.RIGHT
#var _depth_axis:= Vector3.FORWARD
#var _facing_dir := Vector3.RIGHT
#var _locked_rotation_y := 0.0
#
#var _in_backstep := false
#var _backstep_time := 0.0
#var _dummy_target: Node3D = null
#
#func enter() -> void:
	#super()
	#_refresh_axes()
	#_facing_dir = _side_axis
	#_locked_rotation_y = _yaw_from_dir(_facing_dir)
	#player.velocity.x = 0
	#player.velocity.z = 0
	#_ensure_dummy_target()
	#
## Called when the node enters the scene tree for the first time.
#func exit() -> void:
	#_in_backstep = false
	#_backstep_time =0.0
	#
#func _ready() -> void:
	#pass # Replace with function body.
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process_input(delta: float) -> void:
	#pass
	#
#func process_physics(delta: float) -> State:
	#_refresh_axes()
	#
	#var x := Input.get_action_strength("Right") - Input.get_action_strength("Left")
	#var z := Input.get_action_strength("Forward") - Input.get_action_strength("Backward")
	#z = 0.0
	#var moving_lr : bool = abs(x) > 0.01
	#var moving_depth : bool = abs(z) > 0.01
	#var moving : bool = moving_lr or moving_depth
	#
	#var lane_fb: int = _lane_input_to_fb(x)  # +1 forward, -1 backward, 0 none
	#
	#if Input.is_action_just_pressed("Backstep") and player.is_on_floor() and !_in_backstep:
		#_start_backstep()
		#
	#var horiz_vel := Vector3.ZERO
	#
	#if _in_backstep:
		#_backstep_time -= delta
		#if _backstep_time <= 0.0:
			#_in_backstep = false
		#else:
			#horiz_vel = -_facing_dir * backstep_speed
	#else:
		#horiz_vel = (_side_axis * ( x * walk_speed)) + (_depth_axis * (z * sidestep_speed))
		#
	#player.velocity.x = horiz_vel.x
	#player.velocity.z = horiz_vel.z
#
	##----TARGET FACING--------
	#var target_pos:= _get_target_position()
	#var aim_dir := Vector3.ZERO
	#
	#if target_pos:
		#aim_dir = target_pos - player.global_position
		#aim_dir.y = 0.0
		#if aim_dir.length_squared() > 0.0001:
			#aim_dir = aim_dir.normalized()
			#
	#var enemy_behind := aim_dir != Vector3.ZERO and aim_dir.dot(_facing_dir) <0.0
	#var any_dir_just :bool = Input.is_action_just_pressed("Right")\
	#or Input.get_action_strength("Left") \
	#or Input.get_action_strength("Backward") \
	#or Input.get_action_strength("Forward")
	#var attack_just := any_action_just_pressed(attack_actions)
	#
	#if Input.is_action_pressed("Run") and moving_lr:
		#_facing_dir = _side_axis if x >= 0.0 else -_side_axis
	#elif enemy_behind and (attack_just or any_dir_just):
		#_flip_facing()
	#if aim_dir == Vector3.ZERO:
		#_locked_rotation_y = _yaw_from_dir(_facing_dir)
	#else:
		#if aim_dir.dot(_facing_dir) >= 0.0:
			#_locked_rotation_y = _yaw_from_dir(aim_dir)
		#else:
			#_locked_rotation_y = _yaw_from_dir(_facing_dir)
	#player.visuals.global_rotation.y = _locked_rotation_y
	#player.velocity += player.get_gravity() * delta
	#player.move_and_slide()
	#
	#_apply_lane_clamp()
	#if !player.is_on_floor():
		#return fall_state
	#if !_in_backstep and !moving and player.velocity.length() < 0.01:
		#return practice_idle_state
	#return null
	#
#func _lane_input_to_fb(x: float) -> int:
	## +1 = forward along lane, -1 = backward, 0 = none/both
	#if abs(x) <= 0.01:
		#return 0
	#var facing_sign: float = 1.0 if _facing_dir.dot(_side_axis) >= 0.0 else -1.0
	#var key_sign: float = 1.0 if x > 0.0 else -1.0
	#return 1 if key_sign == facing_sign else -1
	#
#func _refresh_axes()-> void:
	#var cam := get_viewport().get_camera_3d()
	#if cam:
		#var right := cam.global_transform.basis.x
		#var fwd := -cam.global_transform.basis.z
		#_side_axis = Vector3(right.x, 0.0, right.z).normalized()
		#_depth_axis = Vector3(fwd.x, 0.0, fwd.z).normalized()
	#else:
		#_side_axis = Vector3.RIGHT
		#_depth_axis = Vector3.FORWARD
		#
#func _yaw_from_dir(dir: Vector3) -> float:
	#return atan2(dir.x,dir.z)
	#
#func _flip_facing()-> void:
	#_facing_dir = -_facing_dir
	#
#func _start_backstep() -> void:
	#pass
#func _apply_lane_clamp() -> void:
	#if lane_half_width <= 0.0: return
	#var center : Node3D = lane_center if lane_center else player
	#var center_pos : Vector3 = center.global_position
	#var delta := player.global_position - center_pos
	#var depth := delta.dot(_depth_axis)
	#var clamped_depth : float = clamp(depth, -lane_half_width, lane_half_width)
	#if clamped_depth != depth:
		#var side_component := delta - _depth_axis * depth
		#var corrected := center_pos + side_component + _depth_axis * clamped_depth
		#player.global_position = Vector3(corrected.x, player.global_position.y, corrected.z)
		#var v_depth := _depth_axis * player.velocity.dot(_depth_axis)
		#player.velocity -= v_depth
		#
#func _get_nearest_target() -> Node3D:
	#var best: Node3D = null
	#var best_d2 := INF
	#for n in get_tree().get_nodes_in_group(target_group):
		#if not (n is Node3D): continue
		#var d2 := player.global_position.distance_squared_to(n.global_position)
		#if d2 < best_d2 and d2 <= target_search_radius * target_search_radius:
			#best = n
			#best_d2 = d2
	#return best
#func _ensure_dummy_target() -> void:
	#if _dummy_target: return
	#_dummy_target = Node3D.new()
	#_dummy_target.name = "PracticeDummyTarget"
	#_dummy_target.visible = false
	#get_tree().current_scene.add_child(_dummy_target)  # world space
	#_update_dummy_target_position(true)
	#
#func _get_target_position() -> Vector3:
	#var real := _get_nearest_target()
	#if real:
		#return real.global_position
	#_update_dummy_target_position(false)
	#return _dummy_target.global_position
	#
#func any_action_just_pressed(names: Array[StringName]) -> bool:
	#for a in names:
		#if InputMap.has_action(a) and Input.is_action_just_pressed(a):
			#return true
	#return false
#func _update_dummy_target_position(force_reset: bool) -> void:
	#var center : Node3D = lane_center if lane_center else player
	#var base := center.global_position
#
	## Place dummy enemy ACROSS the lane center from the player (so they always face “someone”).
	#var side_from_center := (player.global_position - base).dot(_side_axis)
	#var side_sign := 1.0
	#if abs(side_from_center) > 0.001:
		#side_sign = -sign(side_from_center) # opposite side of player
	#elif force_reset:
		#side_sign = 1.0                      # default if perfectly centered
#
	#var target_pos := base + (_side_axis * side_sign * dummy_target_distance)
	## Keep dummy at lane center depth so sidestep makes the player rotate toward it.
	#var depth_at_center := 0.0 # already at base depth
	#target_pos.y = base.y
	#_dummy_target.global_position = target_pos
#
#func cleanup() -> void:
	#if _dummy_target and is_instance_valid(_dummy_target):
		#_dummy_target.queue_free()
		#_dummy_target = null
