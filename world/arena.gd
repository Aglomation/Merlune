extends Node2D
class_name Arena

## One playable map: the tiles and a PlayerSpawn marker.
## For a new map, duplicate arena.tscn, repaint the TileMapLayer and move PlayerSpawn.

## Size of the painted map in pixels. Used for the camera limits and for keeping things inside.
func get_world_rect():
	var used_tiles = $TileMapLayer.get_used_rect()
	var tile_size = Vector2($TileMapLayer.tile_set.tile_size)
	return Rect2(Vector2(used_tiles.position) * tile_size, Vector2(used_tiles.size) * tile_size)

func get_player_spawn():
	return $PlayerSpawn.global_position
