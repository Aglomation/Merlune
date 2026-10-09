extends Node2D
class_name RingVFX

## An expanding, fading ring. Used for explosions and pulses. Create it with VFX.ring().

var color: Color = Color(1, 1, 1)
var max_radius: float = 30.0
var duration: float = 0.3
var time_alive: float = 0.0

func _process(delta: float) -> void:
	time_alive += delta
	queue_redraw()
	if time_alive >= duration:
		queue_free()

func _draw() -> void:
	var progress = clamp(time_alive / duration, 0.0, 1.0)
	# starts fast and slows down at the end
	var radius = max_radius * (1.0 - pow(1.0 - progress, 3.0))
	var alpha = 1.0 - progress
	draw_circle(Vector2.ZERO, radius, Color(color.r, color.g, color.b, alpha * 0.3))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(color.r, color.g, color.b, alpha), 2.0)
