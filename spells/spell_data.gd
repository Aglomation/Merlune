extends Resource
class_name SpellData

## Everything about ONE spell. To make a new spell, duplicate a file in spells/library/ and
## change the values. No code is needed if it fits one of the effect types in spells/effects/.

@export var display_name: String = "Spell"
## Must be the same as gesture_name in the gesture template (not case sensitive).
@export var gesture_name: String = ""
@export var element: Attack.Element = Attack.Element.NONE
@export var color: Color = Color(1, 1, 1)
## What the spell does in the world. Pick one from spells/effects/.
@export var effect_scene: PackedScene
## Seconds (real time, not slow motion) before THIS spell can be cast again.
## Stops the strong spells from being spammed. 0 = no delay.
@export var recast_delay: float = 0.0
## Moves the aim point onto the closest enemy if there is one near it.
@export var snap_to_enemies: bool = false
## Furthest distance from the player the spell can be aimed. 0 = no limit.
@export var cast_range: float = 0.0

@export_category("Damage")
## Damage per hit. For zones it is damage per tick.
@export var damage: float = 10.0
@export var heal_amount: float = 0.0
@export var knockback: float = 0.0

@export_category("Projectile")
@export var speed: float = 220.0
## Seconds a projectile flies, a zone stays, or a lightning bolt is visible.
@export var lifetime: float = 1.5
## How many extra enemies the projectile goes through.
@export var pierce: int = 0

@export_category("Area")
## Splash radius for projectiles, size of the area for zones.
@export var radius: float = 0.0
@export var tick_interval: float = 0.5
## How much of the damage you take from your own zone (0 = none, 0.4 = 40%).
@export var self_damage_scale: float = 0.0

@export_category("Lightning")
@export var beam_length: float = 220.0
@export var beam_width: float = 12.0

@export_category("Status")
## "burning" or "wet", empty for none. See status_component.gd.
@export var status: String = ""
@export var status_time: float = 0.0

## Builds the Attack for this spell. `position` is where it comes from (knockback direction).
func make_attack(position: Vector2, damage_scale: float = 1.0):
	var attack = Attack.new()
	attack.attack_damage = damage * damage_scale
	attack.knockback_force = knockback
	attack.attack_position = position
	attack.element = element
	attack.status = status
	attack.status_time = status_time
	return attack
