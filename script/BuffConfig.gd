class_name BuffConfig

const DEFAULT_GRID_SIZE: Vector2i = Vector2i(2, 2)

static var buff_datas: Dictionary[int, BuffData] = {}

class BuffData:
	var id: int
	var buff: int
	var grid_size: Vector2i
	var buff_resource: String

	func _init(
		_id: int,
		_buff: int,
		_grid_size: Vector2i,
		_buff_resource: String,
	):
		id = _id
		buff = _buff
		grid_size = _grid_size
		buff_resource = _buff_resource
		BuffConfig.buff_datas[id] = self
	pass


static var bullet_size_buff: BuffData = BuffData.new(
	0,
	IBuff.BuffType.BULLET_SIZE,
	DEFAULT_GRID_SIZE,
	"res://image/buff/bullet_size.png"
)

static var bullet_speed_buff: BuffData = BuffData.new(
	1,
	IBuff.BuffType.BULLET_SPEED,
	DEFAULT_GRID_SIZE,
	"res://image/buff/bullet_speed.png"
)

static var bullet_fire_interval_buff: BuffData = BuffData.new(
	2,
	IBuff.BuffType.BULLET_FIRE_INTERVAL,
	DEFAULT_GRID_SIZE,
	"res://image/buff/bullet_fire_interval.png"
)

static var tank_speed_buff: BuffData = BuffData.new(
	3,
	IBuff.BuffType.TANK_SPEED,
	DEFAULT_GRID_SIZE,
	"res://image/buff/tank_speed.png"
)

static var tank_hp_buff: BuffData = BuffData.new(
	4,
	IBuff.BuffType.TANK_HP,
	DEFAULT_GRID_SIZE,
	"res://image/buff/tank_hp.png"
)

static var tank_respawn_buff: BuffData = BuffData.new(
	5,
	IBuff.BuffType.TANK_RESPAWN,
	DEFAULT_GRID_SIZE,
	"res://image/buff/tank_respawn.png"
)

static var tank_size_buff: BuffData = BuffData.new(
	6,
	IBuff.BuffType.TANK_SIZE,
	Vector2i.ONE,
	"res://image/buff/tank_size.png"
)

static var freeze_buff: BuffData = BuffData.new(
	7,
	IBuff.BuffType.FREEZE,
	DEFAULT_GRID_SIZE,
	"res://image/buff/buff_freeze.png"
)

static var air_strike_buff: BuffData = BuffData.new(
	8,
	IBuff.BuffType.AIR_STRIKE,
	DEFAULT_GRID_SIZE,
	"res://image/buff/buff_air_strike.png"
)


static func random_buff() -> BuffData:
	return RandomUtils.random_ele(buff_datas.values())