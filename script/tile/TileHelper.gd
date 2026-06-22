class_name TileHelper

const TILE_SCENE := "res://scene/Tile.tscn"


static func create_tile(data: TileConfig.TileCell, grid: Vector2i) -> Tile:
	var scene: PackedScene = load(TILE_SCENE)
	var tile: StaticBody2D = scene.instantiate()
	tile.set_script(load(data.script_resource))

	var clamped_grid := TankConfig.clamp_grid_to_bounds(grid, Tile.GRID_SIZE)
	tile.global_position = TankConfig.grid_to_world(clamped_grid, Tile.GRID_SIZE)

	var parent: Node = (Engine.get_main_loop() as SceneTree).current_scene
	parent.add_child(tile)

	return tile as Tile


static func is_area_blocked_for_tank(grid: Vector2i, grid_size: Vector2i) -> bool:
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			if is_grid_blocked_for_tank(grid + Vector2i(x, y)):
				return true
	return false


static func is_grid_blocked_for_tank(grid: Vector2i) -> bool:
	var parent: Node = (Engine.get_main_loop() as SceneTree).current_scene
	for node in parent.get_children():
		if node is Tile and node.blocks_tank() and node.grid_pos == grid:
			return true
	return false
