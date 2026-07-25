class_name PathFinderHelper

## 基于 Godot 内置 AStarGrid2D 的格子寻路。
## from / to 为坦克左上角格子；返回路径含起点，相邻点为四方向一步。


static func find_path(
	from: Vector2i,
	to: Vector2i,
	tank_grid_size: Vector2i,
	exclude: Tank = null,
) -> Array[Vector2i]:
	var region_size := Vector2i(
		TileConfig.MAP_GRID_WIDTH - tank_grid_size.x + 1,
		TileConfig.MAP_GRID_HEIGHT - tank_grid_size.y + 1,
	)
	if region_size.x <= 0 or region_size.y <= 0:
		return []
	if not TileConfig.is_in_bounds(from, tank_grid_size):
		return []

	var astar := AStarGrid2D.new()
	astar.region = Rect2i(Vector2i.ZERO, region_size)
	astar.cell_size = Vector2.ONE
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.update()

	for x in region_size.x:
		for y in region_size.y:
			var cell := Vector2i(x, y)
			if is_solid(cell, tank_grid_size, exclude, to):
				astar.set_point_solid(cell, true)

	# 自身当前位置必须可走，避免被瞬时阻挡卡死
	astar.set_point_solid(from, false)

	var goal := resolve_goal(astar, to, region_size)
	if goal == Vector2i.MIN:
		return []

	var id_path := astar.get_id_path(from, goal)
	return id_path


static func is_solid(
	cell: Vector2i,
	tank_grid_size: Vector2i,
	exclude: Tank,
	goal: Vector2i,
) -> bool:
	if not TileConfig.is_in_bounds(cell, tank_grid_size):
		return true
	if TileHelper.is_area_blocked_for_tank(cell, tank_grid_size):
		return true
	# 目标格允许落在敌方/友方坦克上，否则无法朝目标规划路径
	if cell == goal:
		return false
	return TankHelper.is_area_blocked_by_tank(cell, tank_grid_size, exclude)


static func resolve_goal(astar: AStarGrid2D, to: Vector2i, region_size: Vector2i) -> Vector2i:
	var clamped := Vector2i(
		clampi(to.x, 0, region_size.x - 1),
		clampi(to.y, 0, region_size.y - 1),
	)
	if not astar.is_in_bounds(clamped.x, clamped.y):
		return Vector2i.MIN

	if not astar.is_point_solid(clamped):
		return clamped

	# 目标被砖墙等永久挡住时，改走向最近可达格
	var best := Vector2i.MIN
	var best_dist := INF
	for x in region_size.x:
		for y in region_size.y:
			var cell := Vector2i(x, y)
			if astar.is_point_solid(cell):
				continue
			var dist := absi(cell.x - clamped.x) + absi(cell.y - clamped.y)
			if dist < best_dist:
				best_dist = dist
				best = cell
	return best
