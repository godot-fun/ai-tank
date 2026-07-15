class_name BuffConfig


enum Buff {
	BULLET_SIZE,
	BULLET_SPEED,
	BULLET_FIRE_INTERVAL,
	
	TANK_SPEED,
	TANK_HP,
	TANK_RESPAWN,
	TANK_SIZE,
	
	FREEZE,
	AIR_STRIKE,
}

const DEFAULT_GRID_SIZE: Vector2i = Vector2i(2, 2)

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


static var bullet_size_buff: BuffData = BuffData.new(
	0,
	Buff.BULLET_SIZE,
	DEFAULT_GRID_SIZE,
	"res://image/buff/bullet_size.png",
	"res://script/buff/BulletSizeBuff.gd",
)

static var bullet_speed_buff: BuffData = BuffData.new(
	1,
	Buff.BULLET_SPEED,
	DEFAULT_GRID_SIZE,
	"res://image/buff/bullet_speed.png",
	"res://script/buff/BulletSpeedBuff.gd",
)

static var bullet_fire_interval_buff: BuffData = BuffData.new(
	2,
	Buff.BULLET_FIRE_INTERVAL,
	DEFAULT_GRID_SIZE,
	"res://image/buff/bullet_fire_interval.png",
	"res://script/buff/BulletFireIntervalBuff.gd",
)

static var tank_speed_buff: BuffData = BuffData.new(
	3,
	Buff.TANK_SPEED,
	DEFAULT_GRID_SIZE,
	"res://image/buff/tank_speed.png",
	"res://script/buff/TankSpeedBuff.gd",
)

static var tank_hp_buff: BuffData = BuffData.new(
	4,
	Buff.TANK_HP,
	DEFAULT_GRID_SIZE,
	"res://image/buff/tank_hp.png",
	"res://script/buff/TankHpBuff.gd",
)

static var tank_respawn_buff: BuffData = BuffData.new(
	5,
	Buff.TANK_RESPAWN,
	DEFAULT_GRID_SIZE,
	"res://image/buff/tank_respawn.png",
	"res://script/buff/TankRespawnBuff.gd",
)

static var tank_size_buff: BuffData = BuffData.new(
	6,
	Buff.TANK_SIZE,
	DEFAULT_GRID_SIZE,
	"res://image/buff/tank_size.png",
	"res://script/buff/TankSizeBuff.gd",
)