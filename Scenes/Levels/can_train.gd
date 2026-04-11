extends Area3D
class_name TrainingEntranceArea

@export var entrance_id: StringName = &"park_train_01"
@export_file("*.tscn")

var practice_scene_path: String = "res://Scenes/Levels/world_park_practice.tscn"

@export var practice_timeline: StringName = &"Train_Park"

@export_range(5.0, 1800.0, 1.0)
var prompt_every_sec: float = 60.0

var _armed: bool = true

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if !_armed:
		return
	if !(body is Player):
		return

	# NEW: one-shot per entrance (until you reset it)
	if TrainingFlow.is_entrance_disabled(entrance_id):
		return

	_armed = false

	if practice_timeline != &"":
		Dialogic.start_timeline(String(practice_timeline))
		await Dialogic.timeline_ended

	var p: Player = body as Player
	TrainingFlow.enter_training(
		practice_scene_path,
		p.global_transform,
		prompt_every_sec,
		entrance_id
	)

	return
