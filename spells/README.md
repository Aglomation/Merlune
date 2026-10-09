# Spells

Everything about spells is in this folder.

```
spells/
  spell_data.gd        what a spell is (the fields you fill in)
  spell_caster.gd      on the player, turns a drawn gesture into a spell
  library/             ONE .tres PER SPELL  <- the spells themselves (fireball.tres, lava.tres ...)
  effects/             WHAT A SPELL DOES in the world (these are the spell scenes)
    projectile_effect  flies towards the aim point (fireball, water splash)
    zone_effect        area on the ground that ticks (lava)
    self_effect        instant effect on the player (heal)
    lightning_effect   instant bolt that hits everything on a line
    spell_effect.gd    base script all effects extend
```

## Make a new spell with an existing effect type
1. Draw the shape in gesture-maker.html and save the .tres in `gestures/templates/`.
2. Duplicate a file in `spells/library/` (for example `fireball.tres`) and change:
   - `gesture_name` (same as the gesture's name), `display_name`, `color`, `element`
   - `effect_scene` (which file in `effects/` to use)
   - the numbers (damage, speed, radius, `recast_delay`...)
3. Add the new .tres to `spells` on the SpellCaster node in `entities/player/player.tscn`.
4. Add the gesture .tres to `gesture_templates` on `UI/GestureCanvas` in `world/main.tscn`.

## Make a new kind of effect
1. Duplicate a scene + script in `effects/` and extend `SpellEffect`.
2. Do your thing in `on_setup()`. You have `data` (the SpellData), `caster`, `target_position`.
3. Use a spell's `effect_scene` field to point at it.

## Good to know
- `recast_delay` is in real seconds (not slow motion). It stops strong spells being spammed.
- Elements react with each other in `combat/status_component.gd`
  (water then fire = Steam!, water then lightning = Shocked!, water puts out burning).
- `self_damage_scale` on a zone is how much of its damage you take yourself (lava = 0.4).
