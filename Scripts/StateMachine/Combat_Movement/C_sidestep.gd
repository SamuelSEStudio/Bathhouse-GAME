extends State
class_name PracticeSidestepState

@export var idle_state: State
@export var forward_state: State
@export var other_sidestep_state: State
@export var backward_state: State
@export var fall_state: State
@export var dodge_state: State
@export var guard_state: State

@export var opponent_body: Node3D
@export var speed: float = 4.0
@export var lock_visuals_y: bool = true
@export var depth_sign: float = 1.0
@export var guarded_animation_name: String = "default_guard"

var _locked_y: float = 0.0


func _lane_axis_from_current_camera() -> Vector3:
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam != null:
		var right: Vector3 = cam.global_transform.basis.x
		var flat: Vector3 = Vector3(right.x, 0.0, right.z)

		if flat.length() > 0.0001:
			return flat.normalized()

	return Vector3.RIGHT


func _get_lane_dir() -> Vector3:
	if player == null:
		return _lane_axis_from_current_camera()

	var target: Node3D = opponent_body

	var p: Player = player as Player
	if p != null and p.combat_target != null:
		target = p.combat_target

	if target == null:
		return _lane_axis_from_current_camera()

	var p_pos: Vector3 = player.global_transform.origin
	var e_pos: Vector3 = target.global_transform.origin

	var lane: Vector3 = e_pos - p_pos
	lane.y = 0.0

	var length: float = lane.length()
	if length <= 0.001:
		return _lane_axis_from_current_camera()

	return lane / length


func _get_side_dir(lane_dir: Vector3) -> Vector3:
	var side: Vector3 = Vector3.UP.cross(lane_dir)
	var length: float = side.length()

	if length <= 0.001:
		return Vector3.FORWARD

	return side / length


func enter(payload: Variant = null) -> void:
	super(payload)

	_locked_y = player.visuals.global_rotation.y


func exit() -> void:
	super()

	var p: Player = player as Player
	if p != null:
		p.clear_guard_modifier()


func process_input(event: InputEvent) -> State:
	var fwd: bool = Input.is_action_pressed("Forward")
	var back: bool = Input.is_action_pressed("Backward")

	if !(fwd or back):
		return idle_state

	if depth_sign > 0.0 and back:
		return other_sidestep_state

	if depth_sign < 0.0 and fwd:
		return other_sidestep_state

	return null


func _refresh_guard_animation() -> void:
	var p: Player = player as Player
	if p != null and p.is_guarding():
		play_state_animation(guarded_animation_name)
	else:
		play_state_animation(animation_name)


func process_frame(delta: float) -> State:
	var p: Player = player as Player
	if p != null and p.defence != null:
		var d: DefenceInterpreter = p.defence

		if d.just_requested_dodge:
			d.just_requested_dodge = false
			return dodge_state

	return null


func process_physics(delta: float) -> State:
	_refresh_guard_animation()

	if lock_visuals_y:
		player.visuals.global_rotation.y = _locked_y

	var lane_dir: Vector3 = _get_lane_dir()
	var side_dir: Vector3 = _get_side_dir(lane_dir)

	var dir: Vector3 = (side_dir * depth_sign).normalized()

	var p: Player = player as Player
	var current_speed: float = speed

	if p != null:
		current_speed = p.get_guard_modified_speed(speed)

	player.velocity.x = dir.x * current_speed
	player.velocity.z = dir.z * current_speed

	player.velocity += player.get_gravity() * delta
	player.move_and_slide()

	if p != null:
		p.update_facing_to_combat_target()

	if !player.is_on_floor():
		return fall_state

	return null
