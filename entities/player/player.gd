extends CharacterBody2D
class_name Player

## The cat. Walks, takes damage, heals and owns the camera.
## Casting is done by the SpellCaster child, hit points by Health, burning/wet by Status.

const SPEED = 105.0

@onready var sprite = $Sprite2D
@onready var health = $Health
@onready var status = $Status
@onready var hitbox = $Hitbox
@onready var spell_caster = $SpellCaster
@onready var camera = $Camera2D

var knockback: Vector2 = Vector2.ZERO
var flash_tween: Tween
var walk_time: float = 0.0
var screen_shake: float = 0.0
## The player can't walk outside this. Set by world/game.gd from the size of the map.
var world_bounds: Rect2 = Rect2()

func _ready() -> void:
	add_to_group("Player")
	status.burn_tick.connect(_on_burn_tick)
	status.reaction.connect(_on_reaction)

	# No smoothing during the first frame, otherwise the camera slides in from the corner.
	camera.position_smoothing_enabled = false
	await get_tree().process_frame
	camera.position_smoothing_enabled = true

func _physics_process(delta: float) -> void:
	var direction = Input.get_vector("left", "right", "up", "down")
	if health.dead:
		direction = Vector2.ZERO

	velocity = direction * SPEED * status.speed_multiplier() + knockback
	knockback = knockback.move_toward(Vector2.ZERO, 500 * delta)
	move_and_slide()

	if world_bounds.has_area():
		global_position = global_position.clamp(world_bounds.position, world_bounds.end)

func _process(delta: float) -> void:
	update_sprite(delta)
	update_camera_shake(delta)

func update_sprite(delta: float):
	if velocity.length() > 5:
		walk_time += delta * 12.0
		sprite.position.y = -abs(sin(walk_time)) * 1.5
		# only turn around when actually moving sideways
		if abs(velocity.x) > 5:
			sprite.flip_h = velocity.x < 0
	else:
		sprite.position.y = move_toward(sprite.position.y, 0.0, 10.0 * delta)

	# while aiming (right click held) the cat looks at the cursor
	if Input.is_action_pressed("mouse_right"):
		sprite.flip_h = get_global_mouse_position().x < global_position.x

	# blinks while invulnerable after a hit
	var tint = status.tint()
	if hitbox.invulnerable && int(Time.get_ticks_msec() / 40) % 2 == 0:
		tint.a = 0.35
	sprite.modulate = tint

func update_camera_shake(delta: float):
	if screen_shake > 0:
		camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * screen_shake
		screen_shake = max(screen_shake - 14.0 * delta, 0.0)
	else:
		camera.offset = Vector2.ZERO

func set_world_bounds(rect: Rect2):
	world_bounds = rect
	camera.limit_left = int(rect.position.x)
	camera.limit_top = int(rect.position.y)
	camera.limit_right = int(rect.end.x)
	camera.limit_bottom = int(rect.end.y)

## Called by HealthComponent after it has subtracted the damage.
func damage(attack):
	start_white_flash()
	screen_shake = 3.0
	knockback += (global_position - attack.attack_position).normalized() * attack.knockback_force
	VFX.floating_text(global_position + Vector2(0, -16), str(roundi(attack.attack_damage)), Color(1, 0.35, 0.35), 11)

## Called by HealthComponent when health reaches 0.
func death():
	set_process(false)
	status.clear()
	VFX.burst(global_position, Color(0.6, 0.4, 0.9), 24, 100.0)
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.8)
	GameHandler.player_died.emit()

## Used by the heal spell (see spells/effects/self_effect.gd).
func heal(amount):
	var healed = health.heal(amount)
	if healed > 0:
		VFX.floating_text(global_position + Vector2(0, -16), "+%d" % roundi(healed), Color(0.5, 1, 0.5), 11)

func start_white_flash():
	if flash_tween and flash_tween.is_valid():
		flash_tween.kill()

	sprite.self_modulate = Color(10, 10, 10)

	flash_tween = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	flash_tween.tween_property(sprite, "self_modulate", Color(1, 1, 1), 0.3)

# Burning damage goes straight to health so it doesn't trigger element reactions.
func _on_burn_tick(damage_amount):
	var attack = Attack.new()
	attack.attack_damage = damage_amount
	attack.stun_time = 0.0
	attack.element = Attack.Element.FIRE
	health.damage(attack)

func _on_reaction(text, color):
	VFX.floating_text(global_position + Vector2(0, -26), text, color, 9)
