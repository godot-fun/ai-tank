class_name TileHelper

const TILE_SCENE := "res://scene/Tile.tscn"

# 一个二维数组
static var grids: Array[Array] = create_grids()


static func create_grids() -> Array[Array]:
	var result: Array[Array] = []
	result.resize(TileConfig.MAP_GRID_WIDTH)
	for x in range(TileConfig.MAP_GRID_WIDTH):
		var column: Array = []
		column.resize(TileConfig.MAP_GRID_HEIGHT)
		result[x] = column
	return result


static func clear_grid() -> void:
	for x in range(grids.size()):
		var column: Array = grids[x]
		for y in range(column.size()):
			var tile: Tile = column[y]
			if tile != null:
				tile.queue_free()
	grids = create_grids()


static func create_tile(data: TileConfig.TileCell, grid: Vector2i) -> Tile:
	var scene: PackedScene = load(TILE_SCENE)
	var tile: Tile = scene.instantiate()
	tile.set_script(load(data.script_resource))
	tile.apply_data(data, grid)

	var parent: Node = (Engine.get_main_loop() as SceneTree).current_scene
	parent.add_child(tile)

	return tile as Tile


static func get_tile(grid: Vector2i) -> Tile:
	if not is_cell_in_bounds(grid):
		return null
	return grids[grid.x][grid.y]


static func remove_tile_at(grid: Vector2i) -> void:
	var tile := get_tile(grid)
	if tile == null:
		return
	grids[grid.x][grid.y] = null
	tile.queue_free()
	pass


static func replace_tile(data: TileConfig.TileCell, grid: Vector2i) -> Tile:
	remove_tile_at(grid)
	return create_tile(data, grid)


static func register_tile(tile: Tile) -> void:
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

	var tile: Tile = grids[grid.x][grid.y]
	return tile != null and tile.blocks_tank()


static func is_area_on_ice(grid: Vector2i, grid_size: Vector2i) -> bool:
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var cell := grid + Vector2i(x, y)
			if not is_cell_in_bounds(cell):
				continue
			var tile: Tile = grids[cell.x][cell.y]
			if tile != null and tile is Ice:
				return true
	return false


static func is_cell_in_bounds(grid: Vector2i) -> bool:
	return grid.x >= 0 and grid.x < TileConfig.MAP_GRID_WIDTH and grid.y >= 0 and grid.y < TileConfig.MAP_GRID_HEIGHT
