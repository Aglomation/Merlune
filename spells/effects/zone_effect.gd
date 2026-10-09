extends SpellEffect
class_name ZoneEffect

## An area on the ground that damages everything standing in it every tick (lava).
## It can hurt the player too, see `self_damage_scale` in the SpellData.

var time_alive: float = 0.0
var time_until_next_tick: float = 0.0

func on_setup():
	# zones appear at the aim point, not at the player
	global_position = target_position
	z_index = 1
	var circle = CircleShape2D.new()
	circle.radius = max(data.radius, 4.0)
	$Hitbox/CollisionShape2D.shape = circle
	VFX.ring(global_position, data.radius, data.color, 0.4)

func _physics_process(delta: float) -> void:
	if data == null:
		return
	time_alive += delta
	time_until_next_tick -= delta
	if time_until_next_tick <= 0:
		time_until_next_tick = max(data.tick_interval, 0.05)
		damage_everything_inside()
	queue_redraw()
	if time_alive >= data.lifetime:
		queue_free()

func damage_everything_inside():
	for area in $Hitbox.get_overlapping_areas():
		if !(area is HitboxComponent):
			continue
		if area.get_parent().is_in_group("Player"):
			hurt_player(area)
		else:
			area.damage(data.make_attack(global_position))

## Standing in your own zone hurts, but less than it hurts enemies and without setting you on fire.
func hurt_player(player_hitbox):
	if data.self_damage_scale <= 0:
		return
	var attack = data.make_attack(global_position, data.self_damage_scale)
	attack.status = ""
	attack.knockback_force = 0.0
	player_hitbox.damage(attack)

func _draw() -> void:
	if data == null:
		return
	var c = data.color
	var radius = max(data.radius, 4.0)
	# fades in during the first 0.2s and out during the last 0.6s
	var fade = min(time_alive / 0.2, 1.0) * clamp((data.lifetime - time_alive) / 0.6, 0.0, 1.0)
	draw_circle(Vector2.ZERO, radius, Color(c.r * 0.45, c.g * 0.12, c.b * 0.05, 0.75 * fade))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(c.r, c.g, c.b, fade), 2.0)
	# bubbles that slowly move around
	for i in 7:
		var angle = i * TAU / 7.0 + time_alive * 0.4
		var distance = radius * 0.6 * (0.5 + 0.5 * sin(time_alive * 2.5 + i * 1.7))
		var bubble_size = 1.5 + 1.5 * abs(sin(time_alive * 3.0 + i))
		draw_circle(Vector2.from_angle(angle) * distance, bubble_size, Color(1, 0.7, 0.2, 0.85 * fade))
