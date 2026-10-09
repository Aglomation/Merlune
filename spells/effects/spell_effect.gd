extends Node2D
class_name SpellEffect

## Base for what a spell does in the world. SpellCaster creates the effect scene of the spell
## and calls setup(). Make a new kind of effect by extending this and overriding on_setup().
## (_ready runs BEFORE setup, so don't read `data` in _ready.)
##
## Existing effects:  projectile_effect, zone_effect, self_effect, lightning_effect

var data: SpellData
var caster: Node2D
var target_position: Vector2

func setup(spell_caster_node, origin: Vector2, target: Vector2, spell_data: SpellData):
	caster = spell_caster_node
	data = spell_data
	target_position = target
	global_position = origin
	z_index = 10
	on_setup()

func on_setup():
	pass

func enemies_near(center: Vector2, radius: float):
	var found = []
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		if enemy.global_position.distance_to(center) <= radius:
			found.append(enemy)
	return found
