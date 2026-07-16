class_name BuffHelper

const BUFF_SCENE := "res://scene/buff/Buff.tscn"


static func create_buff(data: BuffConfig.BuffData, grid: Vector2i) -> void:
	var scene: PackedScene = load(BUFF_SCENE)
	var buff = scene.instantiate()
	buff.apply_data(data, grid)

	var parent: Node = (Engine.get_main_loop() as SceneTree).current_scene
	parent.add_child(buff)
	pass
