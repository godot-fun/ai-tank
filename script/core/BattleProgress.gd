class_name BattleProgress

const LEVEL_TIME: Array[float] = [30, 35, 40, 60, 70
								, 45, 50, 55, 70, 80
								, 60, 60, 60, 80, 90
								, 60, 60, 60, 80, 90
								, 60, 60, 60, 90, 100
								, 60, 60, 60, 90, 110
								, 60, 60, 60, 90, 120]

static var level := 0

static var score := 0

static var level_ended := false

static func init() -> void:
	level = 0
	score = 0
	level_ended = false
	pass


static func get_time_limit() -> float:
	return LEVEL_TIME[min(level, LEVEL_TIME.size() - 1)]

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