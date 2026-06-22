class_name EagleHelper

const EAGLE_SCENE := "res://scene/map/Eagle.tscn"

@warning_ignore("integer_division")
static var grid_pos := Vector2i(
	(TankConfig.map_grid_width - Eagle.GRID_SIZE.x) / 2,
	TankConfig.map_grid_height - Eagle.GRID_SIZE.y,
)


static func create_eagle() -> Eagle:
	var scene: PackedScene = load(EAGLE_SCENE)
	var eagle: Eagle = scene.instantiate()

	var parent: Node = (Engine.get_main_loop() as SceneTree).current_scene
	parent.add_child(eagle)

	return eagle





static func is_area_blocked_for_tank(grid: Vector2i, grid_size: Vector2i) -> bool:
	return grid.x < grid_pos.x + Eagle.GRID_SIZE.x \
		and grid.x + grid_size.x > grid_pos.x \
		and grid.y < grid_pos.y + Eagle.GRID_SIZE.y \
		and grid.y + grid_size.y > grid_pos.y
