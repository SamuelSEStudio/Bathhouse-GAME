extends State
class_name PracticeBackwardState

@export var idle_state: State
@export var forward_state: State
@export var sidestep_state: State
@export var fall_state: State
@export var guard_state: State
@export var dodge_state: State
@export var combo_ref: ComboInput

@export var neutral_kick_state: State
@export var jab_state: State

@export var speed: float = 4.0
@export var lock_visuals_y: bool = true
@export var depth_axis: Vector3 = Vector3.FORWARD
@export var direction_sign: float = 1.0 # +1 = forward, -1 = backward
@export var guarded_animation_name: String = "default_guard"

@export var opponent_body: Node3D

var _locked_y: float = 0.0


func _get_lane_dir() -> Vector3:
	if player == null:
		return depth_axis.normalized()

	if opponent_body != null:
		var p_pos: Vector3 = player.global_transform.origin
		var e_pos: Vector3 = opponent_body.global_transform.origin
		var lane: Vector3 = e_pos - p_pos
		lane.y = 0.0
		var len: float = lane.length()

		if len > 0.001:
			return lane / len

	# Fallbacks when no opponent.
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam != null:
		var right: Vector3 = cam.global_transform.basis.x
		var flat: Vector3 = Vector3(right.x, 0.0, right.z)

		if flat.length() > 0.0001:
			return flat.normalized()

	return depth_axis.normalized()


func enter(payload: Variant = null) -> void:
	super(payload)
	_locked_y = player.visuals.global_rotation.y


func exit() -> void:
	super()

	var p: Player = player as Player
	if p != null:
		p.clear_guard_modifier()


func process_input(event: InputEvent) -> State:
	var left: bool = Input.is_action_pressed("Left")
	var right: bool = Input.is_action_pressed("Right")
	var fwd: bool = Input.is_action_pressed("Forward")
	var back: bool = Input.is_action_pressed("Backward")

	if Input.is_action_just_pressed("Punch"):
		if combo_ref:
			combo_ref.push_punch()
			var s: State = combo_ref.resolve_attack(&"P")
			if s != null:
				return s
		return jab_state

	if Input.is_action_just_pressed("Kick"):
		if combo_ref:
			combo_ref.push_kick()
			var s: State = combo_ref.resolve_attack(&"K")
			if s != null:
				return s
		return neutral_kick_state

	if fwd or back:
		return sidestep_state

	if right and !left:
		return forward_state

	if !left:
		return idle_state

	return null


func _refresh_guard_animation() -> void:
	var p: Player = player as Player
	if p != null and p.is_guarding():
		play_state_animation(guarded_animation_name)
	else:
		play_state_animation(animation_name)


func process_physics(delta: float) -> State:
	_refresh_guard_animation()

	if lock_visuals_y:
		player.visuals.global_rotation.y = _locked_y

	var lane_dir: Vector3 = _get_lane_dir()
	lane_dir.y = 0.0

	if lane_dir.length() > 0.0001:
		lane_dir = lane_dir.normalized()

	var dir: Vector3 = -lane_dir

	var p: Player = player as Player
	var current_speed: float = speed

	if p != null:
		current_speed = p.get_guard_modified_speed(speed)

	player.velocity.x = dir.x * current_speed
	player.velocity.z = dir.z * current_speed

	player.velocity += player.get_gravity() * delta
	player.move_and_slide()

	if !player.is_on_floor():
		return fall_state

	if p != null:
		p.update_facing_to_combat_target()

	return null


func process_frame(delta: float) -> State:
	var p: Player = player as Player
	if p != null and p.defence != null:
		var d: DefenceInterpreter = p.defence

		if d.just_requested_dodge:
			d.just_requested_dodge = false
			return dodge_state

	return null
