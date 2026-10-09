extends Control
class_name HUD

## Health bar, the spell bar with the shapes to draw, kill/death counters, the
## "Fireball!" popup and the death screen. The nodes are in hud.tscn.
## world/game.gd calls bind() once the player exists.

var message_tween: Tween
## spell display name -> SpellSlot
var slots: Dictionary = {}

func _ready() -> void:
	GameHandler.stats_changed.connect(update_stats)
	update_stats()

func bind(player, gesture_canvas):
	player.health.health_changed.connect(update_health.bind(player.health))
	update_health(player.health)
	player.spell_caster.spell_cast.connect(_on_spell_cast)
	player.spell_caster.cast_failed.connect(_on_cast_failed)

	for spell in player.spell_caster.spells:
		var slot = SpellSlot.new()
		$Spells.add_child(slot)
		slot.setup(spell, find_template(gesture_canvas, spell.gesture_name), player.spell_caster)
		slots[spell.display_name] = slot

func find_template(gesture_canvas, gesture_name):
	for template in gesture_canvas.gesture_templates:
		if template.gesture_name.to_lower() == gesture_name.to_lower():
			return template
	return null

func update_health(health):
	$Health.max_value = health.max_health
	$Health.value = health.health
	$HealthLabel.text = "HP %d / %d" % [roundi(health.health), roundi(health.max_health)]

func update_stats():
	$Stats.text = "Kills: %d\nDeaths: %d" % [GameHandler.kills, GameHandler.deaths]

func _on_spell_cast(spell):
	if slots.has(spell.display_name):
		slots[spell.display_name].light_up()
	show_message(spell.display_name + "!", spell.color)

func _on_cast_failed(reason):
	show_message(reason, Color(0.75, 0.75, 0.8))

func show_message(text, color):
	$Message.text = text
	$Message.modulate = Color(color.r, color.g, color.b, 1)
	if message_tween:
		message_tween.kill()
	message_tween = create_tween()
	message_tween.tween_interval(0.5)
	message_tween.tween_property($Message, "modulate:a", 0.0, 0.5)

func show_death():
	$DeathScreen/Label.text = "You died...\nbut a cat always comes back.\n\nDeaths: %d    Kills this run: %d" % [GameHandler.deaths, GameHandler.kills]
	create_tween().tween_property($DeathScreen, "color:a", 0.7, 0.8)
