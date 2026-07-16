class_name BattleProgress

const INITIAL_ENEMY_COUNT := 9
const ENEMY_COUNT_PER_LEVEL := 5

const SPAWN_FINISH_EARLY_SECONDS := 30.0
const TIME_LIMIT_SECONDS_MAX := 120.0
const TIME_LIMIT_SECONDS := 60.0
const TIME_PER_LEVEL := 5

static var level := 0

static var score := 0

static var level_ended := false

static func init() -> void:
	level = 0
	score = 0
	level_ended = false
	pass

static func get_enemy_count() -> int:
	return INITIAL_ENEMY_COUNT + level * ENEMY_COUNT_PER_LEVEL


static func get_time_limit() -> float:
	return min(TIME_LIMIT_SECONDS + level * TIME_PER_LEVEL, TIME_LIMIT_SECONDS_MAX)

static func start_level() -> void:
	level_ended = false
	LevelConfig.load_level(BattleProgress.level)
	Eagle.create_base()
	TankHelper.create_tank(TankConfig.my_tank, Eagle.my_tank_start_grid_pos)
	TankHelper.create_tank(TankConfig.partner_tank, Eagle.partner_start_grid_pos)
	pass
	
static func end_level() -> void:
	level_ended = true
	level += 1
	pass


static func fail_level() -> void:
	level_ended = true
	pass