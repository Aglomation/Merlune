extends Area2D
class_name HitboxComponent

## The part of a creature that things can hit. Spells and enemy attacks look for these Area2Ds
## and call damage(attack) on them. Sits on its own physics layer (see project settings):
## player_hitbox = 4, enemy_hitbox = 5.

@export var health_component: HealthComponent
@export var status_component: StatusComponent
## Seconds of invulnerability after being hit (the player uses this).
@export var invulnerable_time: float = 0.0

var invulnerable: bool = false

func damage(attack: Attack):
	if invulnerable:
		return

	# Reactions happen BEFORE the damage is taken because they can change the attack
	# (fire on a wet target does more damage).
	if status_component:
		status_component.react(attack)
	if health_component:
		health_component.damage(attack)

	if invulnerable_time > 0:
		invulnerable = true
		await get_tree().create_timer(invulnerable_time).timeout
		invulnerable = false
