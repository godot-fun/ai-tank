class_name EagleHelper

static var _eagle: Eagle = null


static func register(eagle: Eagle) -> void:
	_eagle = eagle
	pass


static func unregister() -> void:
	_eagle = null
	pass


static func get_eagle() -> Eagle:
	return _eagle


static func is_area_blocked_for_tank(grid: Vector2i, grid_size: Vector2i) -> bool:
	if _eagle == null or not _eagle.is_alive():
		return false

	return _rects_overlap(grid, grid_size, _eagle.grid_pos, Eagle.GRID_SIZE)


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
