class_name BuffHelper

const BUFF_SCENE := "res://scene/buff/Buff.tscn"

static var map_buffs: Array[Buff] = []


static func create_buff(data: BuffConfig.BuffData, grid: Vector2i) -> void:
	var scene: PackedScene = load(BUFF_SCENE)
	var buff = scene.instantiate()
	buff.apply_data(data, grid)

	var parent: Node = (Engine.get_main_loop() as SceneTree).current_scene
	parent.add_child(buff)
	register_map_buff(buff)
	pass


static func register_map_buff(buff: Buff) -> void:
	map_buffs.append(buff)
	buff.tree_exiting.connect(func() -> void: unregister_map_buff(buff))
	pass


static func unregister_map_buff(buff: Buff) -> void:
	map_buffs.erase(buff)
	pass


static func find_nearest_obtainable_buff(from_tank: Tank, max_dist: int) -> Buff:
	var nearest: Node = null
	var nearest_dist := INF

	for buff in map_buffs:
		if not is_instance_valid(buff):
			continue
		if !BuffManager.can_add_buff(from_tank, buff.type()):
			continue
		var dist := absi(from_tank.grid_pos.x - buff.grid_pos.x) + absi(from_tank.grid_pos.y - buff.grid_pos.y)
		if dist <= max_dist and dist < nearest_dist:
			nearest_dist = dist
			nearest = buff

	return nearest
