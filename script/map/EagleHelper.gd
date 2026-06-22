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
	return _rects_overlap(grid, grid_size, grid_pos, Eagle.GRID_SIZE)


static func _rects_overlap(
	pos_a: Vector2i,
	size_a: Vector2i,
	pos_b: Vector2i,
	size_b: Vector2i,
) -> bool:
	return pos_a.x < pos_b.x + size_b.x \
		and pos_a.x + size_a.x > pos_b.x \
		and pos_a.y < pos_b.y + size_b.y \
		and pos_a.y + size_a.y > pos_b.y
