class_name BuffConfig


enum Buff {
	BULLET_FIRE_INTERVAL,
	BULLET_SIZE,
	BULLET_SPEED,
	
	TANK_SPEED,
	TANK_HP,
	TANK_RESPAWN,
	TANK_SIZE,
	
	FREEZE,
	AIR_STRIKE,
}



class BuffData:
	var id: int
	var buff: int
	var grid_size: Vector2i
	var buff_resource: String
	var script_resource: String

	func _init(
		_id: int,
		_buff: int,
		_grid_size: Vector2i,
		_buff_resource: String,
		_script_resource: String,
	):
		id = _id
		buff = _buff
		grid_size = _grid_size
		buff_resource = _buff_resource
		script_resource = _script_resource
	pass