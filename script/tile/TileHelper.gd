class_name TileHelper

const TILE_SCENE := "res://scene/Tile.tscn"

# 一个二维数组
static var grids: Array = []


static func has_tile_at(grid: Vector2i) -> bool:
	if not is_cell_in_bounds(grid):
		return false

	ensure_grid()
	return grids[grid.x][grid.y] != null


static func clear_grid() -> void:
	grids.clear()
	pass


static func create_tile(data: TileConfig.TileCell, grid: Vector2i) -> Tile:
	var scene: PackedScene = load(TILE_SCENE)
	var tile: StaticBody2D = scene.instantiate()
	tile.set_script(load(data.script_resource))
	tile.apply_data(data)
	
	var clamped_grid := TankConfig.clamp_grid_to_bounds(grid, Vector2i.ONE)
	tile.global_position = TankConfig.grid_to_world(clamped_grid, Vector2i.ONE)

	var parent: Node = (Engine.get_main_loop() as SceneTree).current_scene
	parent.add_child(tile)

	return tile as Tile


static func register_tile(tile: Tile) -> void:
	ensure_grid()
	var cell := tile.grid_pos
	if is_cell_in_bounds(cell):
		grids[cell.x][cell.y] = tile
	pass


static func unregister_tile(tile: Tile) -> void:
	if grids.is_empty():
		return

	var cell := tile.grid_pos
	if is_cell_in_bounds(cell) and grids[cell.x][cell.y] == tile:
		grids[cell.x][cell.y] = null
	pass


static func is_area_blocked_for_tank(grid: Vector2i, grid_size: Vector2i) -> bool:
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			if is_grid_blocked_for_tank(grid + Vector2i(x, y)):
				return true
	return false


static func is_grid_blocked_for_tank(grid: Vector2i) -> bool:
	if not is_cell_in_bounds(grid):
		return false

	ensure_grid()
	var tile: Tile = grids[grid.x][grid.y]
	return tile != null and tile.blocks_tank()


static func is_area_on_ice(grid: Vector2i, grid_size: Vector2i) -> bool:
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			if is_grid_ice(grid + Vector2i(x, y)):
				return true
	return false


static func is_grid_ice(grid: Vector2i) -> bool:
	if not is_cell_in_bounds(grid):
		return false

	ensure_grid()
	var tile: Tile = grids[grid.x][grid.y]
	return tile != null and tile.is_ice()


static func ensure_grid() -> void:
	if not grids.is_empty():
		return

	grids.resize(TileConfig.MAP_GRID_WIDTH)
	for x in range(TileConfig.MAP_GRID_WIDTH):
		var column: Array = []
		column.resize(TileConfig.MAP_GRID_HEIGHT)
		grids[x] = column
	pass


static func is_cell_in_bounds(grid: Vector2i) -> bool:
	return grid.x >= 0 and grid.x < TileConfig.MAP_GRID_WIDTH and grid.y >= 0 and grid.y < TileConfig.MAP_GRID_HEIGHT
