class_name BattleProgress

const TIME_LIMIT_SECONDS_MAX := 90.0
const TIME_LIMIT_SECONDS := 30.0
const TIME_PER_LEVEL := 5

const LEVEL_TIME: Array[float] = [30, 35, 40, 60, 75
								, 45, 50, 55, 75, 90
								, 60, 60, 60, 75, 90
								, 60, 60, 60, 75, 90
								, 60, 60, 60, 75, 90
								, 60, 60, 60, 75, 90
								, 60, 60, 60, 75, 90]

static var level := 0

static var score := 0

static var level_ended := false

static func init() -> void:
	level = 0
	score = 0
	level_ended = false
	pass


static func get_time_limit() -> float:
	return min(TIME_LIMIT_SECONDS + level * TIME_PER_LEVEL, TIME_LIMIT_SECONDS_MAX)

static func start_level() -> void:
	level_ended = false
	LevelConfig.load_level(BattleProgress.level)
	Eagle.create_base()
	TankHelper.create_tank(TankConfig.my_tank, Eagle.my_tank_start_grid_pos)
	TankHelper.create_tank(TankConfig.partner_tank_1, Eagle.partner_start_grid_pos)
	if level >= 4:
		TankHelper.create_tank(TankConfig.partner_tank_2, Eagle.partner_start_grid_pos)
	if level >= 9:
		TankHelper.create_tank(TankConfig.partner_tank_3, Eagle.partner_start_grid_pos)
	if level >= 14:
		TankHelper.create_tank(TankConfig.partner_tank_4, Eagle.partner_start_grid_pos)
	if level >= 19:
		TankHelper.create_tank(TankConfig.partner_tank_5, Eagle.partner_start_grid_pos)
	if level >= 24:
		TankHelper.create_tank(TankConfig.partner_tank_6, Eagle.partner_start_grid_pos)
	pass
	
static func end_level() -> void:
	level_ended = true
	level += 1
	pass


static func fail_level() -> void:
	level_ended = true
	pass