extends Node2D
class_name AimReticle

## Crosshair at the aim point plus a dotted line from the player to it.
## It is drawn in screen space (UI layer) so the dark focus effect doesn't dim it.
## world/game.gd moves it every frame while you hold right click.

var line_start: Vector2 = Vector2.ZERO
## Locked = you have started drawing, the aim no longer follows the mouse.
var locked: bool = false

func _ready() -> void:
	hide()

func show_aim(player_screen_position: Vector2, aim_screen_position: Vector2, is_locked: bool):
	line_start = player_screen_position
	position = aim_screen_position
	locked = is_locked
	show()
	queue_redraw()

func hide_aim():
	hide()

func _draw() -> void:
	var color = Color(1, 1, 1, 0.75)
	if locked:
		color = Color(1, 0.85, 0.3, 1)
	draw_arc(Vector2.ZERO, 9.0, 0.0, TAU, 24, color, 1.5)
	draw_line(Vector2(-14, 0), Vector2(-5, 0), color, 1.5)
	draw_line(Vector2(5, 0), Vector2(14, 0), color, 1.5)
	draw_line(Vector2(0, -14), Vector2(0, -5), color, 1.5)
	draw_line(Vector2(0, 5), Vector2(0, 14), color, 1.5)
	# line_start is in screen space, this node is at the aim point, so subtract our position
	draw_dashed_line(Vector2.ZERO, line_start - position, Color(color.r, color.g, color.b, 0.35), 1.0, 4.0)
