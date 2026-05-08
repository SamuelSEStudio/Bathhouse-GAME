extends Control
class_name HealthDisplay

@export var combatant_path: NodePath
@export var progress_bar_path: NodePath = ^"ProgressBar"

@onready var progress_bar: ProgressBar = get_node_or_null(progress_bar_path) as ProgressBar

var combatant: Combatant = null


func _ready() -> void:
	if combatant_path != NodePath():
		combatant = get_node_or_null(combatant_path) as Combatant

	if combatant == null:
		push_warning("HealthDisplay has no Combatant assigned.")
		return

	if progress_bar == null:
		push_warning("HealthDisplay has no ProgressBar assigned.")
		return

	if !combatant.health_changed.is_connected(_on_health_changed):
		combatant.health_changed.connect(_on_health_changed)

	_sync_initial_health.call_deferred()


func _exit_tree() -> void:
	if combatant != null and combatant.health_changed.is_connected(_on_health_changed):
		combatant.health_changed.disconnect(_on_health_changed)


func _sync_initial_health() -> void:
	if combatant == null or progress_bar == null:
		return

	_update_health(combatant.health, combatant.max_health)


func _on_health_changed(current: int, max_health: int) -> void:
	_update_health(current, max_health)


func _update_health(current: int, max_health: int) -> void:
	if progress_bar == null:
		return

	progress_bar.min_value = 0.0
	progress_bar.max_value = float(max_health)
	progress_bar.value = float(current)
