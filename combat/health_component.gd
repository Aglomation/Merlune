extends Node
class_name HealthComponent

## Hit points. Add it as a child of anything that can die.
## When health reaches 0 it calls death() on the parent (if it has one, and waits for it
## to finish so the parent can play an animation) and then frees the parent.

signal health_changed

@export var max_health: float = 10.0
@export var health: float
## Turn off for things that shouldn't disappear when they die (the player).
@export var free_on_death: bool = true

var dead: bool = false

func _ready() -> void:
	health = max_health

func damage(attack: Attack):
	if dead:
		return
	health -= attack.attack_damage
	health_changed.emit()

	# lets the parent react (white flash, knockback, damage number)
	if get_parent().has_method("damage"):
		get_parent().damage(attack)

	if health <= 0:
		dead = true
		if get_parent().has_method("death"):
			await get_parent().death()
		if free_on_death:
			get_parent().queue_free()

## Returns how much was actually healed (0 when already at full health).
func heal(amount):
	if dead:
		return 0.0
	var health_before = health
	health = min(health + amount, max_health)
	health_changed.emit()
	return health - health_before
