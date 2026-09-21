class_name GestureRecognizer
extends RefCounted

# Plain $1 style matching:
# resample -> normalize -> average point to point distance (lower = better).
# No rotation stuff on purpose, so an upside down triangle is NOT a triangle.

const NUM_POINTS: int = 32

## Resamples a path into exactly N equidistant points to ensure fair comparisons
static func resample(points: Array[Vector2], n: int) -> Array[Vector2]:
	var local_points: Array[Vector2] = points.duplicate()
	if local_points.size() < 2:
		var padded: Array[Vector2] = []
		var base := local_points[0] if local_points.size() == 1 else Vector2.ZERO
		for i in range(n):
			padded.append(base)
		return padded

	var path_len := get_path_length(local_points)
	if path_len <= 0.0001:
		# Whole path sits in one spot (like a click with no movement),
		# skip so we don't divide by zero below
		var still_points: Array[Vector2] = []
		for i in range(n):
			still_points.append(local_points[0])
		return still_points

	var interval := path_len / (n - 1)
	var new_points: Array[Vector2] = [local_points[0]]
	var accumulated_dist := 0.0
	var i := 1

	while i < local_points.size():
		var pt1 := local_points[i - 1]
		var pt2 := local_points[i]
		var dist := pt1.distance_to(pt2)

		if dist > 0.0 and (accumulated_dist + dist) >= interval:
			var q := pt1.lerp(pt2, (interval - accumulated_dist) / dist)
			new_points.append(q)
			local_points.insert(i, q)
			accumulated_dist = 0.0
		else:
			accumulated_dist += dist
		i += 1

	while new_points.size() < n:
		new_points.append(local_points[-1])
	if new_points.size() > n:
		new_points = new_points.slice(0, n)

	return new_points

## Same as resample but treats the path as a loop: N points spread evenly
## around the whole thing, without the start point showing up twice.
## This is what lets closed shapes start from any point.
static func resample_closed(points: Array[Vector2], n: int) -> Array[Vector2]:
	if points.is_empty():
		return resample(points, n)
	var looped: Array[Vector2] = points.duplicate()
	looped.append(points[0])
	var result := resample(looped, n + 1)
	result.resize(n)
	return result

static func get_path_length(points: Array[Vector2]) -> float:
	var total_dist := 0.0
	for i in range(1, points.size()):
		total_dist += points[i - 1].distance_to(points[i])
	return total_dist

## Diagonal of the bounding box, used as a "how big is this drawing" number
static func get_bounding_box_diagonal(points: Array[Vector2]) -> float:
	if points.is_empty():
		return 0.0
	var min_x := points[0].x
	var max_x := points[0].x
	var min_y := points[0].y
	var max_y := points[0].y
	for p in points:
		min_x = min(min_x, p.x)
		max_x = max(max_x, p.x)
		min_y = min(min_y, p.y)
		max_y = max(max_y, p.y)
	return Vector2(max_x - min_x, max_y - min_y).length()

## Centers on the centroid and scales so the longest side is 1.
## Uniform scale so lines/rectangles keep their proportions.
static func normalize_shape(points: Array[Vector2]) -> Array[Vector2]:
	if points.is_empty():
		return points

	var min_x := points[0].x
	var max_x := points[0].x
	var min_y := points[0].y
	var max_y := points[0].y

	for p in points:
		min_x = min(min_x, p.x)
		max_x = max(max_x, p.x)
		min_y = min(min_y, p.y)
		max_y = max(max_y, p.y)

	var max_side: float = maxf(max_x - min_x, max_y - min_y)
	if max_side == 0.0:
		max_side = 1.0

	var centroid := Vector2.ZERO
	for p in points:
		centroid += p
	centroid /= points.size()

	var normalized: Array[Vector2] = []
	for p in points:
		normalized.append((p - centroid) / max_side)

	return normalized

## Flips points horizontally around the centroid (0,0)
static func flip_horizontal(points: Array[Vector2]) -> Array[Vector2]:
	var flipped: Array[Vector2] = []
	for p in points:
		flipped.append(Vector2(-p.x, p.y))
	return flipped

## The actual $1 score: average distance between point i of a and point i of b.
## b_shift starts b from a different index (wraps around), for closed shapes.
## give_up_at bails early (returns INF) once it can't beat the best score anymore.
static func path_distance(a: Array[Vector2], b: Array[Vector2], b_shift: int = 0, give_up_at: float = INF) -> float:
	var n := a.size()
	var limit := give_up_at * n
	var total := 0.0
	for i in range(n):
		total += a[i].distance_to(b[(i + b_shift) % n])
		if total > limit:
			return INF
	return total / n

## Best score of the drawn shape against ONE template, trying every version
## the template allows (flipped, reversed, other start points).
static func score_template(drawn: Array[Vector2], template: GestureTemplate) -> float:
	var best := INF

	var flip_options: Array[bool] = [false]
	if template.allow_flipped_h:
		flip_options.append(true)

	var reverse_options: Array[bool] = [false]
	if template.bidirectional:
		reverse_options.append(true)

	for flip in flip_options:
		for backwards in reverse_options:
			var pts: Array[Vector2] = template.points.duplicate()
			if flip:
				pts = flip_horizontal(pts)
			if backwards:
				pts.reverse()

			# closed shapes can be started from any point on the loop
			var starts := pts.size() if template.is_closed_shape else 1
			for shift in range(starts):
				best = minf(best, path_distance(drawn, pts, shift, best))

	return best

## Does everything and returns a Dictionary, handy for debugging:
##   name    = the matched gesture, "" if nothing was close enough
##   closest = best guess even if it failed
##   score   = distance to that guess (0 = perfect, lower is better)
##   scores  = every template's score by name (gap-rejected ones are missing)
static func recognize_scored(
	drawn_points: Array[Vector2],
	templates: Array[GestureTemplate],
	score_threshold: float = 0.2,
	closed_gap_tolerance: float = 0.35,
	min_diagonal_px: float = 0.0
) -> Dictionary:
	var result := {"name": "", "closest": "", "score": INF, "scores": {}}

	if drawn_points.size() < 4:
		return result

	var drawn_diagonal := get_bounding_box_diagonal(drawn_points)
	if drawn_diagonal <= 0.0001 or drawn_diagonal < min_diagonal_px:
		return result

	# How far the end is from the start compared to the drawing size
	var endpoint_gap_ratio := drawn_points[0].distance_to(drawn_points[-1]) / drawn_diagonal

	# Open version for lines and zigzags, loop version for closed shapes
	var drawn_open := normalize_shape(resample(drawn_points, NUM_POINTS))
	var drawn_closed := normalize_shape(resample_closed(drawn_points, NUM_POINTS))

	for template in templates:
		if template.points.size() != NUM_POINTS:
			template.optimize_template()

		# A half drawn loop shouldn't count as a finished closed shape
		if template.is_closed_shape and endpoint_gap_ratio > closed_gap_tolerance:
			continue

		var drawn: Array[Vector2] = drawn_closed if template.is_closed_shape else drawn_open
		var score := score_template(drawn, template)
		result["scores"][template.gesture_name] = score

		if score < result["score"]:
			result["score"] = score
			result["closest"] = template.gesture_name

	if result["score"] <= score_threshold:
		result["name"] = result["closest"]

	return result

## Just the name, "" if nothing matched
static func recognize(
	drawn_points: Array[Vector2],
	templates: Array[GestureTemplate],
	score_threshold: float = 0.2,
	closed_gap_tolerance: float = 0.35,
	min_diagonal_px: float = 0.0
) -> String:
	var result := recognize_scored(drawn_points, templates, score_threshold, closed_gap_tolerance, min_diagonal_px)
	return result["name"]
