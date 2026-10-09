class_name GestureTemplate
extends Resource

@export var gesture_name: String = "New Gesture"
@export var points: Array[Vector2] = []
@export var spell_color: Color = Color.WHITE
@export var bidirectional: bool = true
@export_range(1,2,0.05,"or_greater") var difficulty_scaler: float = 1.0
## If true, the system will test every possible starting point along the loop.
@export var is_closed_shape: bool = false
@export var allow_flipped_h: bool = false
@export var normalize_on_load: bool = true

func _init() -> void:
	call_deferred("_check_optimize")

func _check_optimize() -> void:
	if normalize_on_load and not points.is_empty():
		optimize_template()

func optimize_template() -> void:
	if is_closed_shape:
		points = GestureRecognizer.resample_closed(points, GestureRecognizer.NUM_POINTS)
	else:
		points = GestureRecognizer.resample(points, GestureRecognizer.NUM_POINTS)
	points = GestureRecognizer.normalize_shape(points)
