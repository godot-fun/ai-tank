class_name TankHelper

const TANK_SCENE := "res://scene/Tank.tscn"

static var _tanks: Array[Tank] = []


static func create_tank(data: TankConfig.TankData, grid: Vector2i) -> Tank:
	var scene: PackedScene = load(TANK_SCENE)
	var tank: CharacterBody2D = scene.instantiate()
	tank.set_script(load(data.script_resource))
	
	var clamped_grid := TankConfig.clamp_grid_to_bounds(grid, data.grid_size)
	tank.global_position = TankConfig.grid_to_world(clamped_grid, data.grid_size)
	
	var parent: Node = (Engine.get_main_loop() as SceneTree).current_scene
	parent.add_child(tank)

	var result := tank as Tank
	return result


static func register_tank(tank: Tank) -> void:
	_tanks.append(tank)
	pass


static func unregister_tank(tank: Tank) -> void:
	_tanks.erase(tank)
	pass


static func find_player() -> Tank:
	for tank in _tanks:
		if tank.team == TankConfig.Team.PLAYER:
			return tank
	return null


static func get_tank_grid(tank: Tank) -> Vector2i:
	return TankConfig.world_to_grid(tank.global_position, tank.grid_size)
