class_name TankHelper

const TANK_SCENE := "res://scene/tank/Tank.tscn"


static func create_tank(data: TankConfig.TankData, grid: Vector2i) -> Tank:
	var scene: PackedScene = load(TANK_SCENE)
	var tank: CharacterBody2D = scene.instantiate()
	tank.set_script(load(data.script_resource))
	
	var clamped_grid := TankConfig.clamp_grid_to_bounds(grid, data.grid_size)
	tank.global_position = TankConfig.grid_to_world(clamped_grid, data.grid_size)
	
	var parent: Node = (Engine.get_main_loop() as SceneTree).current_scene
	parent.add_child(tank)

	return tank as Tank
