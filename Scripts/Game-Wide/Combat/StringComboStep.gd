extends Resource
class_name StringComboStep

@export var animation_name: StringName = &""      # AnimationPlayer track name
@export var move_id: StringName = &""            # Key that matches your AttackAsset.move

@export_range(0.05, 2.0, 0.01)
var total_time: float = 0.35                     # Length of this step in seconds

@export_range(0.0, 2.0, 0.01)
var cancel_open: float = 0.10                    # Time window start for chaining

@export_range(0.0, 2.0, 0.01)
var cancel_close: float = 0.25                   # Time window end for chaining

@export var next_on_p: int = -1 #links to next punch in combo
@export var next_on_k: int = -1 #links to next kick in combo
#directional
@export var next_on_p_forward: int = -1
@export var next_on_p_back: int = -1
@export var next_on_k_forward: int = -1
@export var next_on_k_back: int = -1
