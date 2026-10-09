class_name VFX

## Helpers for particles, rings and floating numbers. Everything is added to the current
## scene (not to whoever called it) so it keeps playing after that node is freed,
## for example after a fireball explodes.

static func current_scene():
	return Engine.get_main_loop().current_scene

## Particles flying out in all directions. `rising` makes them float upwards instead (heal).
static func burst(position: Vector2, color: Color, amount: int = 14, speed: float = 90.0, rising: bool = false):
	var scene = current_scene()
	if scene == null:
		return
	var particles = CPUParticles2D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.amount = amount
	particles.lifetime = 0.5
	particles.explosiveness = 0.9
	particles.direction = Vector2.UP
	particles.spread = 35.0 if rising else 180.0
	particles.gravity = Vector2(0, -18) if rising else Vector2.ZERO
	particles.initial_velocity_min = speed * 0.4
	particles.initial_velocity_max = speed
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 3.5
	particles.color = color
	var fade_out = Gradient.new()
	fade_out.offsets = PackedFloat32Array([0.0, 1.0])
	fade_out.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	particles.color_ramp = fade_out
	particles.z_index = 50
	scene.add_child(particles)
	particles.global_position = position
	particles.emitting = true
	scene.get_tree().create_timer(1.0).timeout.connect(particles.queue_free)

static func ring(position: Vector2, radius: float, color: Color, duration: float = 0.3):
	var scene = current_scene()
	if scene == null:
		return
	var ring_node = RingVFX.new()
	ring_node.color = color
	ring_node.max_radius = radius
	ring_node.duration = duration
	ring_node.z_index = 40
	scene.add_child(ring_node)
	ring_node.global_position = position

## Text that floats up and fades out (damage numbers, "Steam!", "+15").
static func floating_text(position: Vector2, text: String, color: Color = Color(1, 1, 1), font_size: int = 10):
	var scene = current_scene()
	if scene == null:
		return
	var label = Label.new()
	label.text = text
	label.z_index = 100
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	label.add_theme_constant_override("outline_size", 3)
	scene.add_child(label)
	label.reset_size()
	label.global_position = position - label.size * 0.5 + Vector2(randf_range(-4.0, 4.0), 0.0)

	var tween = label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position:y", label.global_position.y - 16.0, 0.7).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.3).set_delay(0.45)
	tween.chain().tween_callback(label.queue_free)
