extends CharacterBody3D
	
class_name ThugMid

# --- Control & movement modes ---

enum ControlMode {
	PLAYER,
	DUMMY_IDLE,
	DUMMY_BLOCK_ALL,
	DUMMY_BLOCK_SECOND_HIT,
	AI_PROFILE_1,
	AI_PROFILE_2,
	AI_PROFILE_3,
}

enum MovementMode {
	LANE,
	ARENA,
}

@export var control_mode: ControlMode = ControlMode.AI_PROFILE_2
@export var movement_mode: MovementMode = MovementMode.LANE

# --- AI "intent" fields (brain writes into these) ---

## -1.0 = move back, 0.0 = stand still, +1.0 = move forward (along lane)
var desired_lane_dir: float = 0.0

## Requested attack “role” (e.g. &"fast_poke", &"heavy_poke"), or &"" for none
var pending_attack_role: StringName = &""

var wants_guard: bool = false 

# --- Common interface used by States (mirrors Player.gd) ---

@onready var visuals: Node3D = $Visuals
@onready var animation_player: AnimationPlayer = $"Visuals/mixamo_base/AnimationPlayer"
@onready var state_machine: Node = $controllers/state_machine
@onready var combatant: Combatant = $Combatant
@onready var ai_brain: Node = $AIBrain   # later you can type this to ThugMidAIBrain
@export var lane_axis: Vector3 = Vector3.FORWARD

func _ready() -> void:
	# Give all State nodes a reference to this CharacterBody3D
	state_machine.init(self)


func _physics_process(delta: float) -> void:
	# No input gating here – AI / states decide if we stand still.
	state_machine.process_physics(delta)


func _process(delta: float) -> void:
	state_machine.process_frame(delta)


# --- Optional helpers for the AI brain (nice clean API) ---

func set_desired_lane_dir(dir: float) -> void:
	desired_lane_dir = clampf(dir, -1.0, 1.0)


func clear_desired_lane_dir() -> void:
	desired_lane_dir = 0.0


func request_attack(role: StringName) -> void:
	pending_attack_role = role


func clear_attack_request() -> void:
	pending_attack_role = &""

func set_guarding(on: bool) -> void:
	wants_guard = on
