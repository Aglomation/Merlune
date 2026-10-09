extends Node
class_name SpellCaster

## Turns a drawn gesture into a spell. Child of the player.
## world/game.gd calls cast_gesture() when you have finished drawing.
## Flow: gesture name -> find the SpellData -> check the delay -> spawn its effect scene.

signal spell_cast(spell)
signal cast_failed(reason)

## The spells the player knows. Add new ones from spells/library/.
@export var spells: Array[SpellData] = []
## Real seconds between casting ANY two spells.
@export var global_cast_delay: float = 0.3
## If the aim point is within this many pixels of an enemy, aim at the enemy instead.
@export var aim_assist_radius: float = 40.0
## Where spells start, relative to the player's position.
@export var origin_offset: Vector2 = Vector2(0, 4)

var spells_by_gesture_name: Dictionary = {}
## SpellData -> real time (msec) when it can be cast again.
var spell_ready_at: Dictionary = {}
var any_spell_ready_at: int = 0

func _ready() -> void:
	for spell in spells:
		spells_by_gesture_name[spell.gesture_name.to_lower()] = spell

## Real seconds until the spell can be cast. 0 when it is ready.
## Real time on purpose: the game is in slow motion while drawing.
func get_remaining_delay(spell: SpellData):
	var ready_at = max(spell_ready_at.get(spell, 0), any_spell_ready_at)
	return max(ready_at - Time.get_ticks_msec(), 0) / 1000.0

func cast_gesture(gesture_name: String, aim_position: Vector2):
	if gesture_name == "":
		cast_failed.emit("Fizzle...")
		return

	var spell = spells_by_gesture_name.get(gesture_name.to_lower())
	if spell == null:
		cast_failed.emit("Unknown symbol (%s)" % gesture_name)
		return

	if get_remaining_delay(spell) > 0:
		cast_failed.emit("%s isn't ready yet" % spell.display_name)
		return

	cast(spell, aim_position)

func cast(spell: SpellData, aim_position: Vector2):
	var player = get_parent()
	var origin = player.global_position + origin_offset

	var target = aim_position
	if spell.cast_range > 0 && origin.distance_to(target) > spell.cast_range:
		target = origin + (target - origin).normalized() * spell.cast_range
	if spell.snap_to_enemies:
		target = snap_to_closest_enemy(target)

	var effect = spell.effect_scene.instantiate()
	get_tree().current_scene.add_child(effect)
	effect.setup(player, origin, target, spell)

	var now = Time.get_ticks_msec()
	spell_ready_at[spell] = now + int(spell.recast_delay * 1000)
	any_spell_ready_at = now + int(global_cast_delay * 1000)
	spell_cast.emit(spell)

func snap_to_closest_enemy(position: Vector2):
	var closest_enemy = null
	var closest_distance = aim_assist_radius
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		var distance = enemy.global_position.distance_to(position)
		if distance <= closest_distance:
			closest_distance = distance
			closest_enemy = enemy
	if closest_enemy:
		return closest_enemy.global_position
	return position
