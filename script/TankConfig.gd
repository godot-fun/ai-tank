class_name TankConfig

const tile_size: int = 60
const tank_grid_size := Vector2i(2, 2)
const bullet_speed := 680.0

# 地图的格子的长宽
static var map_grid_width: int = ProjectSettings.get_setting("display/window/size/viewport_width") / tile_size
static var map_grid_height: int = ProjectSettings.get_setting("display/window/size/viewport_height") / tile_size


static func grid_to_world(grid: Vector2i) -> Vector2:
	return Vector2(
		(grid.x + tank_grid_size.x * 0.5) * tile_size,
		(grid.y + tank_grid_size.y * 0.5) * tile_size,
	)


static func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		floori(world_pos.x / tile_size - tank_grid_size.x * 0.5),
		floori(world_pos.y / tile_size - tank_grid_size.y * 0.5),
	)


static func is_in_bounds(grid: Vector2i) -> bool:
	return grid.x >= 0 and grid.x + tank_grid_size.x <= map_grid_width \
		and grid.y >= 0 and grid.y + tank_grid_size.y <= map_grid_height


static func clamp_grid_to_bounds(grid: Vector2i) -> Vector2i:
	return Vector2i(
		clampi(grid.x, 0, map_grid_width - tank_grid_size.x),
		clampi(grid.y, 0, map_grid_height - tank_grid_size.y),
	)
