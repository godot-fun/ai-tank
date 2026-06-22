class_name TileHelper

const TILE_SCENE := "res://scene/Tile.tscn"

static var _grid: Array = []


static func create_tile(data: TileConfig.TileCell, grid: Vector2i) -> Tile:
	var scene: PackedScene = load(TILE_SCENE)
	var tile: StaticBody2D = scene.instantiate()
	tile.set_script(load(data.script_resource))

	var clamped_grid := TankConfig.clamp_grid_to_bounds(grid, Vector2i.ONE)
	tile.global_position = TankConfig.grid_to_world(clamped_grid, Vector2i.ONE)

	var parent: Node = (Engine.get_main_loop() as SceneTree).current_scene
	parent.add_child(tile)

	return tile as Tile


static func register_tile(tile: Tile) -> void:
	_ensure_grid()
	var cell := tile.grid_pos
	if _is_cell_in_bounds(cell):
		_grid[cell.x][cell.y] = tile
	pass


static func unregister_tile(tile: Tile) -> void:
	if _grid.is_empty():
		return

	var cell := tile.grid_pos
	if _is_cell_in_bounds(cell) and _grid[cell.x][cell.y] == tile:
		_grid[cell.x][cell.y] = null
	pass


static func is_area_blocked_for_tank(grid: Vector2i, grid_size: Vector2i) -> bool:
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			if is_grid_blocked_for_tank(grid + Vector2i(x, y)):
				return true
	return false


static func is_grid_blocked_for_tank(grid: Vector2i) -> bool:
	if not _is_cell_in_bounds(grid):
		return false

	_ensure_grid()
	var tile: Tile = _grid[grid.x][grid.y]
	return tile != null and tile.blocks_tank()


static func is_area_on_ice(grid: Vector2i, grid_size: Vector2i) -> bool:
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			if is_grid_ice(grid + Vector2i(x, y)):
				return true
	return false


static func is_grid_ice(grid: Vector2i) -> bool:
	if not _is_cell_in_bounds(grid):
		return false

	_ensure_grid()
	var tile: Tile = _grid[grid.x][grid.y]
	return tile != null and tile.is_ice()


static func _ensure_grid() -> void:
	if not _grid.is_empty():
		return

	_grid.resize(TankConfig.map_grid_width)
	for x in range(TankConfig.map_grid_width):
		var column: Array = []
		column.resize(TankConfig.map_grid_height)
		_grid[x] = column
	pass


static func _is_cell_in_bounds(grid: Vector2i) -> bool:
	return grid.x >= 0 and grid.x < TankConfig.map_grid_width \
		and grid.y >= 0 and grid.y < TankConfig.map_grid_height
