class_name BestFireGridStrategy

## 以当前坦克为原点，只在周围 SEARCH_RANGE 格内自底向上找最佳向上射击站位。
## 条件：无友方坦克、站位到顶无钢铁/水/老鹰硬挡（砖可打碎，仍可作为候选）。
## 同一行取弹道砖块最少的列。找不到返回 Vector2i.MIN。
const SEARCH_RANGE := 6

static func find_best_fire_grid(tank: Tank) -> Vector2i:
	var size := tank.grid_size
	var origin := tank.grid_pos
	var max_x := TileConfig.MAP_GRID_WIDTH - size.x
	var max_y := TileConfig.MAP_GRID_HEIGHT - size.y
	if max_x < 0 or max_y < 0:
		return Vector2i.MIN

	var y_from := mini(origin.y + SEARCH_RANGE, max_y)
	var y_to := maxi(origin.y - SEARCH_RANGE, 0)
	var x_from := maxi(origin.x - SEARCH_RANGE, 0)
	var x_to := mini(origin.x + SEARCH_RANGE, max_x)

	for y in range(y_from, y_to - 1, -1):
		var best := Vector2i.MIN
		var best_bricks := 2147483647
		for x in range(x_from, x_to + 1):
			var grid_pos := Vector2i(x, y)
			if TankHelper.is_area_blocked_by_player_tank(grid_pos, size, tank):
				continue
			if fire_lane_has_hard_obstacle(grid_pos, size):
				continue

			var bricks := count_fire_lane_bricks(grid_pos, size)
			if bricks < best_bricks:
				best_bricks = bricks
				best = grid_pos

		if best != Vector2i.MIN:
			return best

	return Vector2i.MIN


## 站位占地到地图顶是否有钢铁、水或老鹰等硬障碍（砖可打碎，不视为硬挡）。
static func fire_lane_has_hard_obstacle(grid: Vector2i, grid_size: Vector2i) -> bool:
	for x in range(grid.x, grid.x + grid_size.x):
		for y in range(grid.y + grid_size.y - 1, -1, -1):
			var tile := TileHelper.get_tile(Vector2i(x, y))
			if tile == null:
				continue
			if tile is BrickWall:
				continue
			if tile is SteelWall or tile is Eagle or tile is Water or tile is BrickWallEagle:
				return true
	return false


## 统计站位上方弹道上的砖块数量（不含当前站位占地行，含 BrickWallEagle）。
static func count_fire_lane_bricks(grid: Vector2i, grid_size: Vector2i) -> int:
	var count := 0
	for x in range(grid.x, grid.x + grid_size.x):
		for y in range(grid.y - 1, -1, -1):
			var tile := TileHelper.get_tile(Vector2i(x, y))
			if tile is BrickWall:
				count += 1
	return count
