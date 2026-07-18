class_name TankHelper

const TANK_SCENE := "res://scene/Tank.tscn"

static var tanks: Array[Tank] = []


static func get_alive_enemy_count() -> int:
	var count := 0
	for tank in tanks:
		if tank.team == TankConfig.Team.ENEMY and tank.is_alive():
			count += 1
	return count


static func find_spawn_grid(grid: Vector2i, grid_size: Vector2i, search_right: bool = false) -> Vector2i:
	if not is_move_blocked(grid, grid_size):
		return grid

	var step := 1 if search_right else -1
	var x := grid.x + step
	var max_x := TileConfig.MAP_GRID_WIDTH - grid_size.x

	while (search_right and x <= max_x) or (not search_right and x >= 0):
		var candidate := Vector2i(x, grid.y)
		if not is_move_blocked(candidate, grid_size):
			return candidate
		x += step

	return Vector2i.MIN


static func create_tank(data: TankConfig.TankData, grid: Vector2i, search_right: bool = false) -> Tank:
	var buff_container := BuffManager.get_buff_container(data.id)
	return create_tank_with_buffs(data, grid, search_right, buff_container.buffs)

static func create_tank_with_buffs(data: TankConfig.TankData, grid: Vector2i, search_right: bool = false, buffs: Array[IBuff] = []) -> Tank:
	var spawn_grid := find_spawn_grid(grid, data.grid_size, search_right)
	if spawn_grid == Vector2i.MIN:
		return null
	var scene: PackedScene = load(TANK_SCENE)
	var script: Script = load(data.script_resource)
	var tank: Tank = scene.instantiate()
	tank.set_script(script)
	tank.apply_data(data, spawn_grid)
	
	var parent: Node = (Engine.get_main_loop() as SceneTree).current_scene
	parent.add_child(tank)
	
	BuffManager.trigger_buffs(tank, buffs)

	tank.play_enter_animation()
	return tank

# ----------------------------------------------------------------------------------------------------------------------
static func register_tank(tank: Tank) -> void:
	tanks.append(tank)
	pass


static func unregister_tank(tank: Tank) -> void:
	tanks.erase(tank)
	pass


static func find_player() -> Tank:
	for tank in tanks:
		if tank.team == TankConfig.Team.PLAYER:
			return tank
	return null


static func find_nearest_enemy(from_tank: Tank) -> Tank:
	var nearest: Tank = null
	var nearest_dist := INF

	for tank in tanks:
		if tank.team != TankConfig.Team.ENEMY or not tank.is_alive():
			continue
		var dist := absi(from_tank.grid_pos.x - tank.grid_pos.x) + absi(from_tank.grid_pos.y - tank.grid_pos.y)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = tank

	return nearest

static func is_move_blocked(grid: Vector2i, grid_size: Vector2i, exclude: Tank = null) -> bool:
	if not TileConfig.is_in_bounds(grid, grid_size):
		return true
	if TileHelper.is_area_blocked_for_tank(grid, grid_size):
		return true
	if is_area_blocked_by_tank(grid, grid_size, exclude):
		return true
	return false


static func is_area_blocked_by_tank(grid: Vector2i, grid_size: Vector2i, exclude: Tank = null) -> bool:
	for tank in tanks:
		if tank == exclude:
			continue
		if grid.x < tank.grid_pos.x + tank.grid_size.x and grid.x + grid_size.x > tank.grid_pos.x \
			and grid.y < tank.grid_pos.y + tank.grid_size.y and grid.y + grid_size.y > tank.grid_pos.y:
			return true
	return false
