extends SpellEffect
class_name SelfEffect

## Happens instantly on the player. Used for healing.
## Calls heal() on the caster, so whatever casts it needs that method.

func on_setup():
	if data.heal_amount > 0 && caster.has_method("heal"):
		caster.heal(data.heal_amount)

	var ring_radius = 26.0
	if data.radius > 0:
		ring_radius = data.radius
	VFX.ring(global_position, ring_radius, data.color, 0.5)
	VFX.burst(global_position, data.color, 14, 28.0, true)
	queue_free()
