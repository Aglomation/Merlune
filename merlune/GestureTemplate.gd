class_name GestureTemplate
extends Resource

@export var gesture_name: String = "New Gesture"
@export var points: Array[Vector2] = []
@export var spell_color: Color = Color.WHITE
@export var bidirectional: bool = true
## If true, the system will test every possible starting point along the loop.
@export var is_closed_shape: bool = false
@export var allow_flipped_h: bool = false
@export var normalize_on_load: bool = true

# Path length / bounding-box diagonal of the ORIGINAL authored points,
# captured before optimize_template() resamples+normalizes `points` below.
# GestureRecognizer uses this to reject drawings that don't have a similar
# level of "wiggliness", even if their point clouds happen to line up.
var expected_ratio: float = 1.0

func _init() -> void:
	call_deferred("_check_optimize")

func _check_optimize() -> void:
	if normalize_on_load and not points.is_empty():
		optimize_template()

func optimize_template() -> void:
	# Only capture the ratio from genuinely raw, hand-authored points - if
	# this runs again later on already-optimized data (e.g. the resource
	# gets duplicated at runtime), don't let it drift.
	if points.size() != GestureRecognizer.NUM_POINTS:
		expected_ratio = GestureRecognizer.get_complexity_ratio(points)
	points = GestureRecognizer.resample(points, GestureRecognizer.NUM_POINTS)
	points = GestureRecognizer.normalize_shape(points)
