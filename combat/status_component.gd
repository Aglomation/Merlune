extends Node
class_name StatusComponent

## Timed effects on a creature (burning, wet) and the combos between elements.
## To add a status: use its name in a spell's `status` field and handle it here.

signal burn_tick(damage_amount)
signal reaction(text, color)

const BURN_DAMAGE_PER_TICK = 3.0
const BURN_TICK_INTERVAL = 0.5
const WET_SPEED_MULTIPLIER = 0.7
const STEAM_DAMAGE_MULTIPLIER = 1.75
const SHOCK_DAMAGE_MULTIPLIER = 1.5

## status name -> seconds left
var statuses: Dictionary = {}
var burn_timer: float = 0.0

func _process(delta: float) -> void:
	for status_name in statuses.keys():
		statuses[status_name] -= delta
		if statuses[status_name] <= 0:
			statuses.erase(status_name)

	if statuses.has("burning"):
		burn_timer += delta
		if burn_timer >= BURN_TICK_INTERVAL:
			burn_timer = 0.0
			burn_tick.emit(BURN_DAMAGE_PER_TICK)

## Called by HitboxComponent before the hit is applied. Can change the attack.
##   fire on wet       -> steam, extra damage and the wetness is gone
##   water on burning  -> puts the fire out
##   lightning on wet  -> extra damage
func react(attack: Attack):
	if attack.element == Attack.Element.FIRE && statuses.has("wet"):
		attack.attack_damage *= STEAM_DAMAGE_MULTIPLIER
		attack.status = ""
		statuses.erase("wet")
		reaction.emit("Steam!", Color(0.85, 0.92, 1))
	elif attack.element == Attack.Element.WATER && statuses.has("burning"):
		statuses.erase("burning")
		reaction.emit("Doused", Color(0.5, 0.8, 1))
	elif attack.element == Attack.Element.LIGHTNING && statuses.has("wet"):
		attack.attack_damage *= SHOCK_DAMAGE_MULTIPLIER
		reaction.emit("Shocked!", Color(1, 0.95, 0.4))

	if attack.status != "":
		# a new application only refreshes the timer if it lasts longer
		statuses[attack.status] = max(statuses.get(attack.status, 0.0), attack.status_time)

func speed_multiplier():
	if statuses.has("wet"):
		return WET_SPEED_MULTIPLIER
	return 1.0

## Colour to multiply the sprite with, white when there is no status.
func tint() -> Color:
	var result = Color(1, 1, 1)
	if statuses.has("burning"):
		result *= Color(1, 0.62, 0.45)
	if statuses.has("wet"):
		result *= Color(0.62, 0.78, 1)
	return result

func clear():
	statuses.clear()
