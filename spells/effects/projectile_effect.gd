extends SpellEffect
class_name ProjectileEffect

## Flies in a straight line towards the aim point and hits enemies on the way.
## Optional splash damage (radius) and piercing. Fireball and Water Splash use this.

var direction: Vector2 = Vector2.RIGHT
var time_alive: float = 0.0
var enemies_hit: int = 0
var hitboxes_already_hit: Array = []
var finished: bool = false

func _ready() -> void:
	$Hitbox.area_entered.connect(_on_hitbox_area_entered)

func on_setup():
	direction = (target_position - global_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	rotation = direction.angle()
	add_particle_trail()

func _physics_process(delta: float) -> void:
	if data == null || finished:
		return
	global_position += direction * data.speed * delta
	time_alive += delta
	queue_redraw()
	if time_alive >= data.lifetime:
		finished = true
		VFX.burst(global_position, data.color, 6, 40.0)
		queue_free()

func _draw() -> void:
	if data == null:
		return
	var pulse = 1.0 + 0.15 * sin(time_alive * 30.0)
	var c = data.color
	draw_circle(Vector2.ZERO, 8.0 * pulse, Color(c.r, c.g, c.b, 0.22))
	draw_circle(Vector2.ZERO, 5.5 * pulse, Color(c.r, c.g, c.b, 0.55))
	draw_circle(Vector2.ZERO, 3.8, c)
	draw_circle(Vector2.ZERO, 2.0, c.lightened(0.6))

func _on_hitbox_area_entered(area: Area2D) -> void:
	if finished || !(area is HitboxComponent) || hitboxes_already_hit.has(area):
		return
	hitboxes_already_hit.append(area)
	area.damage(data.make_attack(global_position))
	enemies_hit += 1

	if data.radius > 0:
		splash_damage(area)

	# goes through `pierce` extra enemies before it explodes
	if enemies_hit > data.pierce:
		finished = true
		VFX.burst(global_position, data.color, 16, 110.0)
		queue_free()

## Half damage to every other enemy near the impact.
func splash_damage(directly_hit_hitbox):
	for enemy in enemies_near(global_position, data.radius):
		if enemy.hitbox == directly_hit_hitbox || hitboxes_already_hit.has(enemy.hitbox):
			continue
		enemy.hitbox.damage(data.make_attack(global_position, 0.5))
	VFX.ring(global_position, data.radius, data.color)

func add_particle_trail():
	var trail = CPUParticles2D.new()
	trail.amount = 18
	trail.lifetime = 0.35
	# false = the particles stay where they were made instead of following the projectile
	trail.local_coords = false
	trail.spread = 180.0
	trail.gravity = Vector2.ZERO
	trail.initial_velocity_min = 4.0
	trail.initial_velocity_max = 18.0
	trail.scale_amount_min = 1.5
	trail.scale_amount_max = 3.0
	trail.color = data.color
	var fade_out = Gradient.new()
	fade_out.offsets = PackedFloat32Array([0.0, 1.0])
	fade_out.colors = PackedColorArray([Color(1, 1, 1, 0.9), Color(1, 1, 1, 0)])
	trail.color_ramp = fade_out
	add_child(trail)
