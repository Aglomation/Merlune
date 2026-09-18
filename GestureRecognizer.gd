class_name GestureRecognizer
extends RefCounted

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
		# Degenerate: the whole "path" sits in one spot (e.g. a click with
		# no real movement). Avoids a divide-by-zero a few lines down.
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

static func get_path_length(points: Array[Vector2]) -> float:
	var total_dist := 0.0
	for i in range(1, points.size()):
		total_dist += points[i - 1].distance_to(points[i])
	return total_dist

## Diagonal of the axis-aligned bounding box - a scale-invariant "yardstick"
## for a path, independent of how big or where it was drawn.
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

## How much a path "wiggles" relative to its own size: total ink divided by
## the bounding-box diagonal. Scale-invariant, so a tiny clean triangle and
## a huge clean triangle score about the same - but a scribble, which lays
## down a lot of ink inside a comparatively small box, scores much higher
## than any deliberately-drawn shape. This is the thing point-cloud matching
## alone can't see, since normalizing to a unit box throws this info away.
static func get_complexity_ratio(points: Array[Vector2]) -> float:
	var diagonal := get_bounding_box_diagonal(points)
	if diagonal <= 0.0001:
		return INF
	return get_path_length(points) / diagonal

## Scales and centers a shape using uniform scaling to preserve aspect ratio
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
	# Why does godot need -y :sob:
	for p in points:
		var np := Vector2(p.x - centroid.x, -(p.y - centroid.y)) / max_side
		normalized.append(np)

	return normalized

## Calculates weighted point-cloud distance for $P+
static func cloud_distance(pts1: Array[Vector2], pts2: Array[Vector2], start: int) -> float:
	var n := pts1.size()
	var matched: Array[bool] = []
	matched.resize(n)
	matched.fill(false)

	var total_dist := 0.0
	var weight := float(n)

	for i in range(n):
		var idx := (start + i) % n
		var min_dist := INF
		var min_idx := 0

		for j in range(n):
			if not matched[j]:
				var d := pts1[idx].distance_to(pts2[j])
				if d < min_dist:
					min_dist = d
					min_idx = j

		matched[min_idx] = true
		total_dist += min_dist * weight
		weight -= 1.0

	return total_dist / (n * (n + 1) / 2.0)

## Greedy point-cloud matching across start alignments
static func greedy_cloud_match(pts1: Array[Vector2], pts2: Array[Vector2], is_closed: bool) -> float:
	var n := pts1.size()
	var step := 2 if is_closed else 4
	var min_dist := INF

	for i in range(0, n, step):
		var d1 := cloud_distance(pts1, pts2, i)
		var d2 := cloud_distance(pts2, pts1, i)
		# Uses max first instead of min in attempt to not make it be bad
		var pair_dist := maxf(d1, d2)
		min_dist = minf(min_dist, pair_dist)

	return min_dist

## Flips points horizontally around centroid (0,0)
static func flip_horizontal(points: Array[Vector2]) -> Array[Vector2]:
	var flipped: Array[Vector2] = []
	for p in points:
		flipped.append(Vector2(-p.x, p.y))
	return flipped

## Evaluates user path against template database using $P+ algorithm
static func recognize(
	drawn_points: Array[Vector2],
	templates: Array[GestureTemplate],
	score_threshold: float = 0.3,
	ratio_tolerance: float = 0.45,
	closed_gap_tolerance: float = 0.35,
	min_diagonal_px: float = 0.0
) -> String:
	if drawn_points.size() < 4:
		return ""

	var drawn_diagonal := get_bounding_box_diagonal(drawn_points)
	if drawn_diagonal <= 0.0001 or drawn_diagonal < min_diagonal_px:
		return ""

	# Shape "fingerprint" of the raw drawn path, computed BEFORE resampling
	# so a jittery scribble doesn't get smoothed away into looking clean.
	var drawn_ratio := get_complexity_ratio(drawn_points)
	var endpoint_gap_ratio := drawn_points[0].distance_to(drawn_points[-1]) / drawn_diagonal

	var processed_drawn := resample(drawn_points, NUM_POINTS)
	processed_drawn = normalize_shape(processed_drawn)

	var best_match := ""
	var lowest_score := INF

	for template in templates:
		if template.points.size() != NUM_POINTS:
			template.optimize_template()

		# Skip templates whose "wiggliness" doesn't look anything like what
		# was drawn - this is what rejects scribbles even when a handful of
		# their resampled points happen to line up with a template.
		var ratio_diff := absf(drawn_ratio - template.expected_ratio)
		if ratio_diff > template.expected_ratio * ratio_tolerance:
			continue

		# Closed shapes (star, circle, etc.) should end near where they
		# started. A half-finished shape won't - this is what stops a
		# half-drawn star from being read as a finished one.
		if template.is_closed_shape and endpoint_gap_ratio > closed_gap_tolerance:
			continue

		var score := greedy_cloud_match(processed_drawn, template.points, template.is_closed_shape)

		# Reverse stroke direction check
		if template.bidirectional:
			var reversed_pts := template.points.duplicate()
			reversed_pts.reverse()
			score = minf(score, greedy_cloud_match(processed_drawn, reversed_pts, template.is_closed_shape))

		# Horizontal flip check
		if template.allow_flipped_h:
			var flipped_pts := flip_horizontal(template.points)
			score = minf(score, greedy_cloud_match(processed_drawn, flipped_pts, template.is_closed_shape))

			# Flipped AND reversed
			if template.bidirectional:
				var biflip_pts := flipped_pts.duplicate()
				biflip_pts.reverse()
				score = minf(score, greedy_cloud_match(processed_drawn, biflip_pts, template.is_closed_shape))

		if score < lowest_score:
			lowest_score = score
			best_match = template.gesture_name

	if lowest_score <= score_threshold:
		return best_match

	return ""
