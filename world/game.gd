extends Node2D
class_name Game

## Root of the main scene. This is the only place that knows about all the big parts and
## connects them, so the player, the spells and the UI don't need to know about each other.
##
## HOW CASTING WORKS
##   1. Hold right click: "focus" mode. Time slows down, the world gets darker and a
##      crosshair follows the mouse.
##   2. Press left click on the thing you want to hit. The aim is locked to that spot.
##   3. Keep the left button down and draw the symbol anywhere on the screen.
##   4. Let go of the left button: the spell is cast at the locked aim point.

const FOCUS_TIME_SCALE = 0.2
const FOCUS_DARKNESS = Color(0.45, 0.45, 0.62)

@export var reload_delay: float = 2.4
## How far from the edge of the map things are kept.
@export var world_margin: float = 10.0

@onready var arena = $Arena
@onready var player = $Player
@onready var spawner = $EnemySpawner
@onready var gesture_canvas = $UI/GestureCanvas
@onready var hud = $UI/HUD
@onready var aim_reticle = $UI/AimReticle

var is_focusing: bool = false
var aim_locked: bool = false
## Where the spell will go, in world coordinates.
var aim_position: Vector2 = Vector2.ZERO
var focus_tween: Tween

func _ready() -> void:
	Engine.time_scale = 1.0
	GameHandler.start_run()

	var map_bounds = arena.get_world_rect().grow(-world_margin)
	player.global_position = arena.get_player_spawn()
	player.set_world_bounds(map_bounds)
	spawner.world_bounds = map_bounds

	# drawing only works while focusing
	gesture_canvas.enabled = false
	gesture_canvas.starting_draw.connect(_on_draw_started)
	gesture_canvas.draw_complete.connect(_on_draw_complete)
	GameHandler.player_died.connect(_on_player_died)
	color_strokes_like_spells()

	hud.bind(player, gesture_canvas)
	spawner.start(player)

# Time must never stay slowed when this scene goes away (reload, quit).
func _exit_tree() -> void:
	Engine.time_scale = 1.0

func _process(_delta: float) -> void:
	var wants_focus = Input.is_action_pressed("mouse_right") && !player.health.dead
	if wants_focus != is_focusing:
		set_focus(wants_focus)

	if is_focusing:
		if !aim_locked:
			aim_position = get_global_mouse_position()
		update_aim_reticle()

func set_focus(on: bool):
	is_focusing = on
	Engine.time_scale = FOCUS_TIME_SCALE if on else 1.0
	gesture_canvas.enabled = on

	if !on:
		# letting go of right click while drawing cancels the spell
		gesture_canvas.cancel_stroke()
		aim_locked = false
		aim_reticle.hide_aim()

	# the tween ignores the time scale, otherwise the fade would be 5 times slower
	if focus_tween:
		focus_tween.kill()
	focus_tween = create_tween().set_ignore_time_scale(true)
	focus_tween.tween_property($CanvasModulate, "color", FOCUS_DARKNESS if on else Color(1, 1, 1), 0.15)

# The reticle lives in the UI layer so it isn't darkened, so world positions have to be
# converted to screen positions.
func update_aim_reticle():
	var world_to_screen = get_viewport().get_canvas_transform()
	aim_reticle.show_aim(world_to_screen * player.global_position, world_to_screen * aim_position, aim_locked)

func _on_draw_started(_start_position):
	# the mouse is exactly where the left button was pressed
	aim_position = get_global_mouse_position()
	aim_locked = true

func _on_draw_complete(gesture_name):
	aim_locked = false
	player.spell_caster.cast_gesture(gesture_name, aim_position)

# While drawing, the line gets the colour of the gesture it looks like.
# This makes that the colour of the spell it will cast.
func color_strokes_like_spells():
	for spell in player.spell_caster.spells:
		for template in gesture_canvas.gesture_templates:
			if template.gesture_name.to_lower() == spell.gesture_name.to_lower():
				template.spell_color = spell.color

func _on_player_died():
	set_focus(false)
	spawner.stop()
	gesture_canvas.enabled = false
	hud.show_death()
	await get_tree().create_timer(reload_delay).timeout
	get_tree().reload_current_scene()
