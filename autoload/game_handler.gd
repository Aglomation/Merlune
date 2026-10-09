extends Node

## Global state that has to survive a scene reload (autoload "GameHandler").
## When the player dies the arena is reloaded, but the death counter keeps going.
## Later this is the place for NPC dialogue to look at `deaths` (death loop idea).

signal player_died
signal enemy_died(position)
signal stats_changed

var deaths: int = 0
## Kills in the current run. Reset every time the arena starts.
var kills: int = 0

func _ready() -> void:
	enemy_died.connect(_on_enemy_died)
	player_died.connect(_on_player_died)

func start_run() -> void:
	kills = 0
	stats_changed.emit()

func _on_enemy_died(_position):
	kills += 1
	stats_changed.emit()

func _on_player_died():
	deaths += 1
	stats_changed.emit()
