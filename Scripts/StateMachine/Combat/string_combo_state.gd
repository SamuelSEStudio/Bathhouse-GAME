extends State
class_name StringComboState

@export var idle_state: State
@export var steps: Array[StringComboStep] = []

# Optional: hook into your existing ComboInput so special inputs still record
@export var combo_ref: ComboInput

# How long after total_time we still allow a "late" chain
@export_range(0.0, 0.4, 0.01)
var late_chain_grace: float = 0.18

var _step_index: int = 0
var _t: float = 0.0
var _queued_button: StringName = &""  # "P" or "K"


func enter(payload: Variant = null) -> void:
	_step_index = 0
	_t = 0.0
	_queued_button = StringName("")

	if steps.is_empty():
		return

	_play_current_step()


func exit() -> void:
	# Nothing special yet
	pass


func process_input(event: InputEvent) -> State:
	# Record which attack button was pressed during this step
	if event.is_action_pressed("Punch"):
		_queued_button = &"P"
	elif event.is_action_pressed("Kick"):
		_queued_button = &"K"

	# Feed ComboInput history if you want to keep big input-combo logic working
	if combo_ref != null:
		if event.is_action_pressed("Punch"):
			combo_ref.push_punch()
		elif event.is_action_pressed("Kick"):
			combo_ref.push_kick()

	return null


func process_physics(delta: float) -> State:
	if steps.is_empty():
		return idle_state

	_t += delta
	var step: StringComboStep = steps[_step_index]

	var can_chain_now: bool = (_t >= step.cancel_open and _t <= step.cancel_close)

	# Priority 1: chain inside cancel window if we have a queued button
	if can_chain_now and _queued_button != StringName(""):
		if _try_chain(step):
			return null

	# Priority 2: step is over -> either late-chain or end combo
	if _t >= step.total_time:
		# Late-chain grace
		if _queued_button != StringName("") and _t <= step.total_time + late_chain_grace:
			if _try_chain(step):
				return null

		# No valid branch or no input -> go back to idle
		return idle_state

	return null


func _try_chain(step: StringComboStep) -> bool:
	var next_index: int = _get_next_index_for_button(step, _queued_button)

	if next_index >= 0 and next_index < steps.size():
		_advance_to_step(next_index)
		return true

	# No valid branch for that button on this step
	_queued_button = StringName("")
	return false


func _get_next_index_for_button(step: StringComboStep, button: StringName) -> int:
	var forward: bool = false
	var back: bool = false

	if combo_ref != null:
		forward = combo_ref._is_forward_held()
		back = combo_ref._is_back_held()

	if button == &"P":
		if forward and step.next_on_p_forward >= 0:
			return step.next_on_p_forward
		if back and step.next_on_p_back >= 0:
			return step.next_on_p_back
		return step.next_on_p

	elif button == &"K":
		if forward and step.next_on_k_forward >= 0:
			return step.next_on_k_forward
		if back and step.next_on_k_back >= 0:
			return step.next_on_k_back
		return step.next_on_k

	return -1


func _advance_to_step(index: int) -> void:
	_step_index = index
	_t = 0.0
	_queued_button = StringName("")
	_play_current_step()


func _play_current_step() -> void:
	var step: StringComboStep = steps[_step_index]
	player.animation_player.play(step.animation_name)
	_apply_attack_move(step)


func _apply_attack_move(step: StringComboStep) -> void:
	# Currently not needed because your HitBoxes already carry AttackData.
	# Later you can hook this into Combatant if you want a "current move" concept.
	pass
