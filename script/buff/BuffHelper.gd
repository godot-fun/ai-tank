class_name BuffHelper

const BUFF_SCENE := "res://scene/Buff.tscn"


static func create_buff(data: BuffConfig.BuffData, grid: Vector2i) -> Buff:
	var scene: PackedScene = load(BUFF_SCENE)
	var script: Script = load(data.script_resource)
	var buff: Buff = scene.instantiate()
	buff.set_script(script)
	buff.apply_data(data)

	buff.grid_pos = TankConfig.clamp_grid_to_bounds(grid, data.grid_size)

	var parent: Node = (Engine.get_main_loop() as SceneTree).current_scene
	parent.add_child(buff)

	return buff as Buff
