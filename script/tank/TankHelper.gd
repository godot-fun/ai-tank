class_name TankHelper

const TANK_SCENE := "res://scene/Tank.tscn"

static var tanks: Array[Tank] = []


static func get_alive_enemy_count() -> int:
	var count := 0
	for tank in tanks:
		if tank.team == TankConfig.Team.ENEMY and tank.is_alive():
			count += 1
	return count


static func create_tank(data: TankConfig.TankData, grid: Vector2i) -> Tank:
	var scene: PackedScene = load(TANK_SCENE)
	var script: Script = load(data.script_resource)
	var tank: Tank = scene.instantiate()
	tank.set_script(script)
	tank.apply_data(data)
	
	tank.grid_pos = TankConfig.clamp_grid_to_bounds(grid, data.grid_size)
	
	var parent: Node = (Engine.get_main_loop() as SceneTree).current_scene
	parent.add_child(tank)

	tank.play_enter_animation()
	return tank


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


static func get_tank_grid(tank: Tank) -> Vector2i:
	return TankConfig.world_to_grid(tank.global_position, tank.grid_size)


static func is_move_blocked(grid: Vector2i, grid_size: Vector2i, exclude: Tank = null) -> bool:
	if not TankConfig.is_in_bounds(grid, grid_size):
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
		if _areas_overlap(grid, grid_size, tank.grid_pos, tank.grid_size):
			return true
	return false


static func _areas_overlap(a_grid: Vector2i, a_size: Vector2i, b_grid: Vector2i, b_size: Vector2i) -> bool:
	return a_grid.x < b_grid.x + b_size.x and a_grid.x + a_size.x > b_grid.x \
		and a_grid.y < b_grid.y + b_size.y and a_grid.y + a_size.y > b_grid.y
