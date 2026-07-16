class_name BuffConfig

const DEFAULT_GRID_SIZE: Vector2i = Vector2i(2, 2)

static var buff_datas: Dictionary[int, BuffData] = {}

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
		BuffConfig.buff_datas[id] = self
	pass


static var bullet_size_buff: BuffData = BuffData.new(
	0,
	Buff.BuffType.BULLET_SIZE,
	DEFAULT_GRID_SIZE,
	"res://image/buff/bullet_size.png",
	"res://script/buff/BulletSizeBuff.gd",
)

static var bullet_speed_buff: BuffData = BuffData.new(
	1,
	Buff.BuffType.BULLET_SPEED,
	DEFAULT_GRID_SIZE,
	"res://image/buff/bullet_speed.png",
	"res://script/buff/BulletSpeedBuff.gd",
)

static var bullet_fire_interval_buff: BuffData = BuffData.new(
	2,
	Buff.BuffType.BULLET_FIRE_INTERVAL,
	DEFAULT_GRID_SIZE,
	"res://image/buff/bullet_fire_interval.png",
	"res://script/buff/BulletFireIntervalBuff.gd",
)

static var tank_speed_buff: BuffData = BuffData.new(
	3,
	Buff.BuffType.TANK_SPEED,
	DEFAULT_GRID_SIZE,
	"res://image/buff/tank_speed.png",
	"res://script/buff/TankSpeedBuff.gd",
)

static var tank_hp_buff: BuffData = BuffData.new(
	4,
	Buff.BuffType.TANK_HP,
	DEFAULT_GRID_SIZE,
	"res://image/buff/tank_hp.png",
	"res://script/buff/TankHpBuff.gd",
)

static var tank_respawn_buff: BuffData = BuffData.new(
	5,
	Buff.BuffType.TANK_RESPAWN,
	DEFAULT_GRID_SIZE,
	"res://image/buff/tank_respawn.png",
	"res://script/buff/TankRespawnBuff.gd",
)

static var tank_size_buff: BuffData = BuffData.new(
	6,
	Buff.BuffType.TANK_SIZE,
	Vector2i.ONE,
	"res://image/buff/tank_size.png",
	"res://script/buff/TankSizeBuff.gd",
)

static var freeze_buff: BuffData = BuffData.new(
	7,
	Buff.BuffType.FREEZE,
	DEFAULT_GRID_SIZE,
	"res://image/buff/buff_freeze.png",
	"res://script/buff/FreezeBuff.gd",
)

static var air_strike_buff: BuffData = BuffData.new(
	8,
	Buff.BuffType.AIR_STRIKE,
	DEFAULT_GRID_SIZE,
	"res://image/buff/buff_air_strike.png",
	"res://script/buff/AirStrikeBuff.gd",
)


static func random_buff() -> BuffData:
	return RandomUtils.random_ele(buff_datas.values())