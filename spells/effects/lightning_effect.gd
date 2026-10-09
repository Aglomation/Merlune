extends SpellEffect
class_name LightningEffect

## Instant bolt from the player towards the aim point. Hits EVERY enemy close to the line,
## no travel time. Length and thickness come from beam_length / beam_width in the SpellData.

## Distance between the points of the zigzag.
const ZIGZAG_STEP = 14.0
## How far the zigzag can stray from the straight line.
const ZIGZAG_STRENGTH = 6.0
const FLICKER_INTERVAL = 0.05

var time_alive: float = 0.0
var time_until_flicker: float = 0.0
## Where the bolt ends, relative to this node.
var bolt_end: Vector2 = Vector2.ZERO
var bolt_points: PackedVector2Array = PackedVector2Array()

func on_setup():
	var direction = (target_position - global_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	bolt_end = direction * data.beam_length

	damage_enemies_on_line()
	make_zigzag()
	VFX.burst(global_position + bolt_end, data.color, 8, 60.0)

func damage_enemies_on_line():
	var line_start = global_position
	var line_end = global_position + bolt_end
	# an enemy is hit if its centre is closer than half the beam width plus roughly its own size
	var reach = data.beam_width * 0.5 + 6.0
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		var closest_point = Geometry2D.get_closest_point_to_segment(enemy.global_position, line_start, line_end)
		if closest_point.distance_to(enemy.global_position) <= reach:
			enemy.hitbox.damage(data.make_attack(line_start))

## A new random zigzag between the start and the end of the bolt.
func make_zigzag():
	bolt_points = PackedVector2Array()
	var steps = max(int(bolt_end.length() / ZIGZAG_STEP), 2)
	var sideways = bolt_end.normalized().orthogonal()
	bolt_points.append(Vector2.ZERO)
	for i in range(1, steps):
		var along_line = bolt_end * (float(i) / steps)
		bolt_points.append(along_line + sideways * randf_range(-ZIGZAG_STRENGTH, ZIGZAG_STRENGTH))
	bolt_points.append(bolt_end)

func _process(delta: float) -> void:
	time_alive += delta
	time_until_flicker -= delta
	# a new zigzag every few frames makes it look alive
	if time_until_flicker <= 0:
		time_until_flicker = FLICKER_INTERVAL
		make_zigzag()
	queue_redraw()
	if time_alive >= data.lifetime:
		queue_free()

func _draw() -> void:
	if bolt_points.size() < 2:
		return
	var c = data.color
	draw_polyline(bolt_points, Color(c.r, c.g, c.b, 0.25), 7.0)
	draw_polyline(bolt_points, c, 2.5)
	draw_polyline(bolt_points, Color(1, 1, 1), 1.0)
