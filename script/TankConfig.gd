class_name TankConfig

const tile_size: int = 60

# 地图的格子的长宽
static var map_grid_width: int = DisplayServer.window_get_size().x / tile_size
static var map_grid_height: int = DisplayServer.window_get_size().y / tile_size


static func grid_to_world(grid: Vector2i) -> Vector2:
	return Vector2(
		(grid.x + 0.5) * tile_size,
		(grid.y + 0.5) * tile_size,
	)


static func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		floori(world_pos.x / tile_size),
		floori(world_pos.y / tile_size),
	)


static func is_in_bounds(grid: Vector2i) -> bool:
	return grid.x >= 0 and grid.x < map_grid_width \
		and grid.y >= 0 and grid.y < map_grid_height
