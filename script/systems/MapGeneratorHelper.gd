class_name MapGeneratorHelper

const TANK_SIZE := Vector2i(2, 2)

const OBSTACLE_ZONE_TOP := 4
const OBSTACLE_ZONE_BOTTOM := 12


static func calc_enemy_count(level: int) -> int:
	return BattleProgress.INITIAL_ENEMY_COUNT + (level - 1) * BattleProgress.ENEMY_COUNT_PER_LEVEL


static func build(parent: Node, level: int, enemy_count: int = -1) -> void:
	if enemy_count < 0:
		enemy_count = calc_enemy_count(level)

	TileHelper.clear_grid()
	EagleHelper.create_eagle()

	var player_spawns := get_player_spawns()
	_add_eagle_brick_ring()
	_place_obstacle_clusters(level, player_spawns)
	_place_level_features(level, player_spawns)

	TankHelper.create_tank(TankConfig.my_tank, player_spawns[0])
	TankHelper.create_tank(TankConfig.partner_tank, player_spawns[1])
	pass


static func get_player_spawns() -> Array[Vector2i]:
	var eagle_pos := EagleHelper.grid_pos
	var spawn_y := eagle_pos.y - 2
	var ring_left := eagle_pos.x - 1
	var ring_right := eagle_pos.x + Eagle.GRID_SIZE.x
	var my_spawn := TankConfig.clamp_grid_to_bounds(
		Vector2i(ring_left - TANK_SIZE.x, spawn_y),
		TANK_SIZE,
	)
	var partner_spawn := TankConfig.clamp_grid_to_bounds(
		Vector2i(ring_right + 1, spawn_y),
		TANK_SIZE,
	)
	return [my_spawn, partner_spawn]


static func get_enemy_spawn_points() -> Array[Vector2i]:
	var max_x := TankConfig.map_grid_width - TANK_SIZE.x
	return [
		Vector2i(0, 0),
		Vector2i(max_x / 2, 0),
		Vector2i(max_x, 0),
	]


static func try_spawn_enemy_at(grid: Vector2i) -> bool:
	if TankHelper.is_move_blocked(grid, TANK_SIZE):
		return false
	TankHelper.create_tank(TankConfig.enemy_easy, grid)
	return true


static func _add_eagle_brick_ring() -> void:
	for cell in _get_eagle_brick_ring_cells():
		if TileHelper.has_tile_at(cell):
			continue
		TileHelper.create_tile(TileConfig.brick_wall, cell)
	pass


static func _get_eagle_brick_ring_cells() -> Array[Vector2i]:
	var eagle_pos := EagleHelper.grid_pos
	var left := eagle_pos.x - 1
	var right := eagle_pos.x + Eagle.GRID_SIZE.x
	var top := eagle_pos.y - 1
	var bottom := eagle_pos.y + Eagle.GRID_SIZE.y
	var cells: Array[Vector2i] = []

	for x in range(left, right + 1):
		_append_ring_cell(cells, Vector2i(x, top), eagle_pos)

	for y in range(top + 1, bottom + 1):
		_append_ring_cell(cells, Vector2i(left, y), eagle_pos)
		_append_ring_cell(cells, Vector2i(right, y), eagle_pos)

	if bottom < TankConfig.map_grid_height:
		for x in range(left, right + 1):
			_append_ring_cell(cells, Vector2i(x, bottom), eagle_pos)

	return cells


static func _append_ring_cell(cells: Array[Vector2i], cell: Vector2i, eagle_pos: Vector2i) -> void:
	if not _is_cell_in_bounds(cell):
		return
	if _is_cell_in_eagle(cell, eagle_pos):
		return
	if cells.has(cell):
		return
	cells.append(cell)


static func _is_cell_in_eagle(cell: Vector2i, eagle_pos: Vector2i) -> bool:
	return cell.x >= eagle_pos.x and cell.x < eagle_pos.x + Eagle.GRID_SIZE.x \
		and cell.y >= eagle_pos.y and cell.y < eagle_pos.y + Eagle.GRID_SIZE.y


static func _place_obstacle_clusters(level: int, player_spawns: Array[Vector2i]) -> void:
	var target_tiles := mini(10 + level * 4, 72)
	var placed := 0
	var attempts := 0
	var max_attempts := target_tiles * 10

	while placed < target_tiles and attempts < max_attempts:
		attempts += 1
		var center := _random_obstacle_cell(player_spawns)
		if center == Vector2i(-1, -1):
			break

		var cell := _pick_tile_cell(level)
		var cluster_size := randi_range(2, mini(3 + level / 2, 8))
		placed += _stamp_cluster(center, cell, cluster_size, player_spawns)
	pass


static func _place_level_features(level: int, player_spawns: Array[Vector2i]) -> void:
	if level >= 3:
		_place_water_channels(level, player_spawns)
	if level >= 5:
		_place_steel_forts(level, player_spawns)
	if level >= 7:
		_place_forest_patches(level, player_spawns)
	if level >= 9:
		_place_ice_patches(level, player_spawns)
	pass


static func _place_water_channels(level: int, player_spawns: Array[Vector2i]) -> void:
	var channel_count := mini(1 + level / 4, 3)
	for _i in channel_count:
		var y := randi_range(OBSTACLE_ZONE_TOP + 1, OBSTACLE_ZONE_BOTTOM - 1)
		var gap_start := randi_range(2, TankConfig.map_grid_width - 8)
		var gap_width := randi_range(4, 6 + level / 3)
		for x in range(TankConfig.map_grid_width):
			if x >= gap_start and x < gap_start + gap_width:
				continue
			_try_place_tile(TileConfig.water, Vector2i(x, y), player_spawns)
	pass


static func _place_steel_forts(level: int, player_spawns: Array[Vector2i]) -> void:
	var fort_count := mini(1 + level / 5, 4)
	for _i in fort_count:
		var origin := _random_obstacle_cell(player_spawns)
		if origin == Vector2i(-1, -1):
			continue
		for x in range(2):
			for y in range(2):
				_try_place_tile(TileConfig.steel_wall, origin + Vector2i(x, y), player_spawns)
	pass


static func _place_forest_patches(level: int, player_spawns: Array[Vector2i]) -> void:
	var patch_count := mini(1 + level / 3, 5)
	for _i in patch_count:
		var center := _random_obstacle_cell(player_spawns)
		if center == Vector2i(-1, -1):
			continue
		_stamp_cluster(center, TileConfig.forest, randi_range(3, 5 + level / 4), player_spawns)
	pass


static func _place_ice_patches(level: int, player_spawns: Array[Vector2i]) -> void:
	var patch_count := mini(1 + level / 4, 4)
	for _i in patch_count:
		var center := _random_obstacle_cell(player_spawns)
		if center == Vector2i(-1, -1):
			continue
		_stamp_cluster(center, TileConfig.ice, randi_range(2, 4 + level / 5), player_spawns)
	pass


static func _pick_tile_cell(level: int) -> TileConfig.TileCell:
	var options: Array[TileConfig.TileCell] = [TileConfig.brick_wall]
	if level >= 5:
		options.append(TileConfig.steel_wall)
	if level >= 7:
		options.append(TileConfig.forest)
	if level >= 9:
		options.append(TileConfig.ice)
	return options[randi() % options.size()]


static func _stamp_cluster(
	center: Vector2i,
	cell: TileConfig.TileCell,
	size: int,
	player_spawns: Array[Vector2i],
) -> int:
	var placed := 0
	var current := center
	for _step in size:
		if _try_place_tile(cell, current, player_spawns):
			placed += 1
		var direction := Vector2i(
			randi_range(-1, 1),
			randi_range(-1, 1),
		)
		if direction == Vector2i.ZERO:
			direction = Vector2i.RIGHT
		current += direction
	return placed


static func _try_place_tile(cell: TileConfig.TileCell, grid: Vector2i, player_spawns: Array[Vector2i]) -> bool:
	if _is_cell_blocked_for_obstacle(grid, player_spawns):
		return false
	TileHelper.create_tile(cell, grid)
	return true


static func _is_cell_blocked_for_obstacle(grid: Vector2i, player_spawns: Array[Vector2i]) -> bool:
	if not _is_cell_in_bounds(grid):
		return true
	if TileHelper.has_tile_at(grid):
		return true
	if grid.y >= TankConfig.map_grid_height - 5:
		return true
	if _is_in_base_area(grid):
		return true
	return _is_in_player_spawn(grid, player_spawns)


static func _is_in_base_area(grid: Vector2i) -> bool:
	var eagle_pos := EagleHelper.grid_pos
	if _is_cell_in_eagle(grid, eagle_pos):
		return true
	for cell in _get_eagle_brick_ring_cells():
		if cell == grid:
			return true
	return false


static func _is_in_player_spawn(grid: Vector2i, player_spawns: Array[Vector2i]) -> bool:
	for spawn in player_spawns:
		if grid.x >= spawn.x and grid.x < spawn.x + TANK_SIZE.x \
				and grid.y >= spawn.y and grid.y < spawn.y + TANK_SIZE.y:
			return true
	return false


static func _random_obstacle_cell(player_spawns: Array[Vector2i]) -> Vector2i:
	for _attempt in 32:
		var cell := Vector2i(
			randi_range(1, TankConfig.map_grid_width - 2),
			randi_range(OBSTACLE_ZONE_TOP, OBSTACLE_ZONE_BOTTOM),
		)
		if not _is_cell_blocked_for_obstacle(cell, player_spawns):
			return cell
	return Vector2i(-1, -1)


static func _is_cell_in_bounds(grid: Vector2i) -> bool:
	return grid.x >= 0 and grid.x < TankConfig.map_grid_width \
		and grid.y >= 0 and grid.y < TankConfig.map_grid_height
