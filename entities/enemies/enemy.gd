extends CharacterBody2D
class_name Enemy

## Base enemy: walks towards the player, hurts on contact and takes spell hits.
## New enemy type: make an inherited scene of enemy.tscn (see ghost.tscn), change the sprite
## and the numbers below. For different movement, extend this script and rewrite
## physics_process or chase_velocity().

@export var display_name: String = "Enemy"
@export var max_health: float = 30.0
@export var max_speed: float = 38.0
## Heavier enemies get pushed back less.
@export var weight: float = 1.0
@export var contact_damage: float = 8.0
@export var contact_knockback: float = 110.0
## Seconds between contact hits.
@export var contact_cooldown: float = 0.9
@export var bob_height: float = 2.0
## Colour of the sprite. Phantoms use a dark purple.
@export var base_tint: Color = Color(1, 1, 1)

@onready var sprite = $Sprite2D
@onready var health = $Health
@onready var status = $Status
@onready var hitbox = $Hitbox

var player: Node2D
var is_stunned: bool = false
var can_attack: bool = true
var flash_tween: Tween
var bob_time: float = 0.0

func _ready() -> void:
	add_to_group("Enemy")
	health.max_health = max_health
	health.health = max_health
	health.health_changed.connect(queue_redraw)
	status.burn_tick.connect(_on_burn_tick)
	status.reaction.connect(_on_reaction)
	sprite.self_modulate = base_tint
	# random start so the enemies don't all float up and down in sync
	bob_time = randf() * TAU

func _physics_process(delta: float) -> void:
	if health.dead:
		return
	if !is_instance_valid(player):
		player = get_tree().get_first_node_in_group("Player")
		return

	# after being hit the enemy slides in the knockback direction instead of walking
	if is_stunned:
		velocity = velocity.move_toward(Vector2.ZERO, 400 * delta)
		move_and_slide()
		return

	velocity = chase_velocity()
	move_and_slide()
	attack_player_on_contact()

func _process(delta: float) -> void:
	bob_time += delta * 4.0
	sprite.position.y = sin(bob_time) * bob_height
	if is_instance_valid(player):
		sprite.flip_h = player.global_position.x < global_position.x
	sprite.modulate = status.tint()

func chase_velocity():
	var to_player = player.global_position - global_position
	# stops right next to the player instead of shaking on top of them
	if to_player.length() <= 8:
		return Vector2.ZERO
	var direction = (to_player.normalized() + separation_push() * 0.8).normalized()
	return direction * max_speed * status.speed_multiplier()

## Pushes away from other enemies that are too close so they don't stack into one blob.
func separation_push():
	const PUSH_DISTANCE = 22.0
	var push = Vector2.ZERO
	for other in get_tree().get_nodes_in_group("Enemy"):
		if other == self:
			continue
		var away = global_position - other.global_position
		var distance = away.length()
		if distance > 0.01 && distance < PUSH_DISTANCE:
			push += away / distance * (1.0 - distance / PUSH_DISTANCE)
	return push

func attack_player_on_contact():
	if !can_attack:
		return
	for area in $ContactArea.get_overlapping_areas():
		if area is HitboxComponent:
			var attack = Attack.new()
			attack.attack_damage = contact_damage
			attack.knockback_force = contact_knockback
			attack.attack_position = global_position
			area.damage(attack)
			can_attack = false
			await get_tree().create_timer(contact_cooldown).timeout
			can_attack = true
			return

## Called by HealthComponent after it has subtracted the damage.
func damage(attack):
	start_white_flash()
	VFX.floating_text(global_position + Vector2(0, -14), str(roundi(attack.attack_damage)), Attack.element_color(attack.element).lightened(0.3))
	# attacks without stun (burning) shouldn't interrupt walking
	if attack.stun_time <= 0:
		return

	is_stunned = true
	velocity = (global_position - attack.attack_position).normalized() * attack.knockback_force / weight
	await get_tree().create_timer(attack.stun_time).timeout
	is_stunned = false

## Called by HealthComponent when health reaches 0. The enemy is freed after this finishes.
func death():
	remove_from_group("Enemy")
	set_process(false)
	status.set_process(false)
	# can't be hit anymore while fading out
	hitbox.set_deferred("monitorable", false)
	GameHandler.enemy_died.emit(global_position)
	VFX.burst(global_position, Color(0.85, 0.92, 1), 18, 70.0)
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.25)
	await tween.finished

# health bar above the head, only visible after taking damage
func _draw() -> void:
	if health.dead || health.health >= health.max_health:
		return
	var ratio = health.health / health.max_health
	draw_rect(Rect2(-8, -22, 16, 2), Color(0.1, 0, 0, 0.8))
	draw_rect(Rect2(-8, -22, 16 * ratio, 2), Color(0.9, 0.2, 0.25))

func start_white_flash():
	if flash_tween and flash_tween.is_valid():
		flash_tween.kill()

	sprite.self_modulate = Color(10, 10, 10)

	flash_tween = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	flash_tween.tween_property(sprite, "self_modulate", base_tint, 0.3)

# Burning damage goes straight to health so it doesn't trigger element reactions.
func _on_burn_tick(damage_amount):
	var attack = Attack.new()
	attack.attack_damage = damage_amount
	attack.stun_time = 0.0
	attack.element = Attack.Element.FIRE
	health.damage(attack)

func _on_reaction(text, color):
	VFX.floating_text(global_position + Vector2(0, -26), text, color, 9)
