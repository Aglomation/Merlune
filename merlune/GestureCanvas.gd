class_name GestureCanvas
extends Control
signal starting_draw
signal draw_complete(gesture_name: String)

@export var gesture_templates: Array[GestureTemplate] = []
@export_range(0.1, 0.5) var match_threshold: float = 0.20
@export_range(0.1, 1.0) var shape_complexity_tolerance: float = 0.45
@export_range(0.05, 1.0) var closed_shape_gap_tolerance: float = 0.35
@export var min_gesture_size_px: float = 40.0
@export var default_line_color: Color = Color.WHITE
@export var line_width: float = 8.0
var current_stroke: Array[Vector2] = []
var is_drawing: bool = false
var feedback_line: Line2D
func _ready() -> void:
	# Adds the visual feedback stuff
	feedback_line = Line2D.new()
	feedback_line.default_color = default_line_color
	feedback_line.width = line_width
	feedback_line.joint_mode = Line2D.LINE_JOINT_ROUND
	feedback_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	feedback_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(feedback_line)
# Detects user input and starts the guessing thing
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			start_stroke(event.position)
		else:
			end_stroke()
	elif event is InputEventMouseMotion and is_drawing:
		continue_stroke(event.position)
# Starts stroking it.
func start_stroke(pos: Vector2) -> void:
	is_drawing = true
	current_stroke = [pos]
	feedback_line.points = current_stroke
	feedback_line.default_color = default_line_color
	starting_draw.emit()
# Passes the mouse location to the gesture alg thingy
func continue_stroke(pos: Vector2) -> void:
	if current_stroke.is_empty() or current_stroke[-1].distance_to(pos) > 5.0:
		current_stroke.append(pos)
		feedback_line.add_point(pos)

		var result: String = _recognize(current_stroke)

		if result != "":
			print("It's a "+result)
			# Changes color to the spell color if matched
			for template in gesture_templates:
				if template.gesture_name == result:
					feedback_line.default_color = template.spell_color
					break
		else:
			print("idk")
			# Reverts to default color if you mess it up
			feedback_line.default_color = default_line_color
# When you stop stroking it or smth
func end_stroke() -> void:
	if not is_drawing:
		return
	is_drawing = false

	# Gets final result
	var result: String = _recognize(current_stroke)
	draw_complete.emit(result)
	$Label.text = result if result else "Fail"

	# Removes the lines
	feedback_line.clear_points()
	current_stroke.clear()
# Single place that wires up the new rejection thresholds, so the live-preview
# and final-commit calls can never drift out of sync with each other.
func _recognize(stroke: Array[Vector2]) -> String:
	return GestureRecognizer.recognize(
		stroke,
		gesture_templates,
		match_threshold,
		shape_complexity_tolerance,
		closed_shape_gap_tolerance,
		min_gesture_size_px
	)
