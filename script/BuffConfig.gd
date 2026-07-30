class_name BuffConfig

const DEFAULT_GRID_SIZE: Vector2i = Vector2i(2, 2)

static var buff_datas: Dictionary[int, BuffData] = {}

class BuffData:
	var type: int
	var buff: IBuff
	var grid_size: Vector2i
	var max_stack: int
	var buff_resource: String

	func _init(
		_buff: IBuff,
		_grid_size: Vector2i,
		_max_stack: int,
		_buff_resource: String,
	):
		type = _buff.type()
		buff = _buff
		grid_size = _grid_size
		max_stack = _max_stack
		buff_resource = _buff_resource
		BuffConfig.buff_datas[type] = self
	pass


static var bullet_size_buff: BuffData = BuffData.new(
	BulletSizeBuff.new(),
	DEFAULT_GRID_SIZE,
	3,
	"res://image/buff/bullet_size.png"
)

static var bullet_speed_buff: BuffData = BuffData.new(
	BulletSpeedBuff.new(),
	DEFAULT_GRID_SIZE,
	3,
	"res://image/buff/bullet_speed.png"
)

static var bullet_fire_interval_buff: BuffData = BuffData.new(
	BulletFireIntervalBuff.new(),
	DEFAULT_GRID_SIZE,
	3,
	"res://image/buff/bullet_fire_interval.png"
)

static var tank_speed_buff: BuffData = BuffData.new(
	TankSpeedBuff.new(),
	DEFAULT_GRID_SIZE,
	3,
	"res://image/buff/tank_speed.png"
)

static var tank_hp_buff: BuffData = BuffData.new(
	TankHpBuff.new(),
	DEFAULT_GRID_SIZE,
	3,
	"res://image/buff/tank_hp.png"
)

static var tank_respawn_buff: BuffData = BuffData.new(
	TankRespawnBuff.new(),
	DEFAULT_GRID_SIZE,
	3,
	"res://image/buff/tank_respawn.png"
)

static var tank_size_buff: BuffData = BuffData.new(
	TankSizeBuff.new(),
	Vector2i.ONE,
	1,
	"res://image/buff/tank_size.png"
)

static var freeze_buff: BuffData = BuffData.new(
	FreezeBuff.new(),
	DEFAULT_GRID_SIZE,
	-1,
	"res://image/buff/buff_freeze.png"
)

static var air_strike_buff: BuffData = BuffData.new(
	AirStrikeBuff.new(),
	DEFAULT_GRID_SIZE,
	-1,
	"res://image/buff/buff_air_strike.png"
)

static var eagle_steel_buff: BuffData = BuffData.new(
	EagleSteelBuff.new(),
	Vector2i.ONE,
	-1,
	"res://image/tiles/steel_wall_1.png"
)


static func random_buff() -> BuffData:
	return RandomUtils.random_ele(buff_datas.values())
