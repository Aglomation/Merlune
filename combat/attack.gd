class_name Attack

## One hit, passed around as an object: HitboxComponent -> HealthComponent -> owner.damage(attack).
## Spells, enemy contact damage and burning all create one of these.
## Add new elements at the END of the enum, saved spell files store the number.

enum Element { NONE, FIRE, WATER, NATURE, LIGHTNING }

var attack_damage: float = 0.0
var knockback_force: float = 0.0
## Where the hit comes from. Knockback pushes away from this point.
var attack_position: Vector2 = Vector2(0, 0)
## How long the target stops and can't walk after being hit.
var stun_time: float = 0.2
var element: Element = Element.NONE
## Name of a status to apply ("burning", "wet") or "" for none.
var status: String = ""
var status_time: float = 0.0

static func element_color(element_type) -> Color:
	match element_type:
		Element.FIRE:
			return Color(1, 0.45, 0.1)
		Element.WATER:
			return Color(0.35, 0.65, 1)
		Element.NATURE:
			return Color(0.45, 0.85, 0.35)
		Element.LIGHTNING:
			return Color(1, 0.95, 0.4)
	return Color(1, 1, 1)
