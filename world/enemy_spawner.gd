extends Node
class_name EnemySpawner

## Spawns enemies just outside the screen, more and faster the longer you survive.
## The enemies are added to the parent of this node (the world).

@export var enemy_scenes: Array[PackedScene] = []
## Enemies placed close to the player when the run starts.
@export var start_count: int = 3
@export var starting_max_alive: int = 6
@export var absolute_max_alive: int = 14
@export var starting_spawn_interval: float = 3.0
@export var fastest_spawn_interval: float = 1.0
## Every this many seconds one more enemy is allowed and spawns get faster.
@export var seconds_per_difficulty_level: float = 15.0
@export var min_spawn_distance: float = 380.0
@export var max_spawn_distance: float = 480.0

## Enemies are only placed inside this rectangle. Set by world/game.gd.
var world_bounds: Rect2 = Rect2()
var player: Node2D
var running: bool = false
var time_until_spawn: float = 1.5
var time_running: float = 0.0

func start(player_to_chase):
	player = player_to_chase
	running = true
	for i in start_count:
		var offset = Vector2.from_angle(randf() * TAU) * randf_range(120.0, 200.0)
		spawn_enemy_at(clamp_to_world(player.global_position + offset))

func stop():
	running = false

func _process(delta: float) -> void:
	if !running || !is_instance_valid(player):
		return
	time_running += delta
	var level = int(time_running / seconds_per_difficulty_level)
	var max_alive = min(starting_max_alive + level, absolute_max_alive)
	var interval = max(starting_spawn_interval * pow(0.9, level), fastest_spawn_interval)

	time_until_spawn -= delta
	if time_until_spawn > 0:
		return
	time_until_spawn = interval
	if get_tree().get_nodes_in_group("Enemy").size() >= max_alive:
		return

	var spawn_point = find_offscreen_point()
	if spawn_point != null:
		spawn_enemy_at(spawn_point)

func spawn_enemy_at(position: Vector2):
	if enemy_scenes.is_empty():
		return
	var enemy = enemy_scenes.pick_random().instantiate()
	get_parent().add_child(enemy)
	enemy.global_position = position
	VFX.burst(position, Color(0.7, 0.5, 1), 12, 60.0)

## A random point around the player that is not visible on screen. Null if none was found.
func find_offscreen_point():
	var viewport = get_viewport()
	var visible_world_area = (viewport.get_canvas_transform().affine_inverse() * viewport.get_visible_rect()).grow(24.0)
	for attempt in 12:
		var offset = Vector2.from_angle(randf() * TAU) * randf_range(min_spawn_distance, max_spawn_distance)
		var point = clamp_to_world(player.global_position + offset)
		if !visible_world_area.has_point(point):
			return point
	return null

func clamp_to_world(point: Vector2):
	if world_bounds.has_area():
		return point.clamp(world_bounds.position, world_bounds.end)
	return point
