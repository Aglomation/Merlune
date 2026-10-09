# Merlune

2D game where you cast spells by drawing symbols with the mouse. Godot 4.7.

## Controls
| Input | Does |
|---|---|
| WASD / arrow keys | Walk |
| Hold right click | Focus: time slows to 0.2x, the world gets darker, a crosshair follows the mouse |
| Left click while focusing | Locks the aim at the cursor, then draw the symbol anywhere while holding the button |
| Let go of left click | Casts the spell at the locked aim point |

Letting go of right click while drawing cancels the spell.

| Shape | Spell | Notes |
|---|---|---|
| Line | Lightning | Fast, weak, hits everything on the line |
| Star | Fireball | Explodes, sets things on fire |
| Water drop | Water Splash | Makes enemies wet and slower |
| Heart | Heal | 15 HP, 8 second delay |
| Zigzag | Lava | Area on the ground. Hurts you a bit too if you stand in it |

Combos: water then fire = Steam!, water then lightning = Shocked!, water puts out burning.

## Folders
```
autoload/    game_handler.gd (kills and deaths, survives scene reloads)
combat/      attack, health_component, hitbox_component, status_component
entities/    player/ and enemies/ (enemy.tscn is the base, ghost + phantom inherit it)
gestures/    drawing + recognizing: gesture_canvas, gesture_recognizer, gesture_template, templates/
spells/      spell_data, spell_caster, library/ (the spells), effects/ (what spells do). See spells/README.md
ui/          hud, spell_slot, aim_reticle
vfx/         particles, rings and floating numbers
world/       main.tscn + game.gd (connects everything), arena, enemy_spawner
Assets/      sprites and tiles
```

## How a hit works
`HitboxComponent.damage(attack)` -> `StatusComponent.react(attack)` (element combos) ->
`HealthComponent.damage(attack)` -> `damage(attack)` on the owner (flash, knockback) ->
`death()` on the owner when health is 0.

## Add things
- **Spell:** see spells/README.md
- **Enemy:** make an inherited scene of `entities/enemies/enemy.tscn` (like ghost.tscn), then add it to `enemy_scenes` on EnemySpawner in main.tscn.
- **Map:** duplicate `world/arena.tscn`, repaint the tiles, move PlayerSpawn.
