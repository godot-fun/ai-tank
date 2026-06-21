class_name TileHelper

const TILE_SCENE := "res://scene/Tile.tscn"


static func create_tile(data: TankConfig.TileData, grid: Vector2i) -> Tile:
	var scene: PackedScene = load(TILE_SCENE)
	var tile: StaticBody2D = scene.instantiate()
	tile.set_script(load(data.script_resource))

	var clamped_grid := TankConfig.clamp_grid_to_bounds(grid, Tile.GRID_SIZE)
	tile.global_position = TankConfig.grid_to_world(clamped_grid, Tile.GRID_SIZE)

	var parent: Node = (Engine.get_main_loop() as SceneTree).current_scene
	parent.add_child(tile)

	return tile as Tile
