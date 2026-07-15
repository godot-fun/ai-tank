class_name BattleProgress

const INITIAL_ENEMY_COUNT := 30
const ENEMY_COUNT_PER_LEVEL := 5

const TIME_LIMIT_SECONDS_MAX := 60.0
const TIME_LIMIT_SECONDS := 30.0
const TIME_PER_LEVEL := 5

static var level := 0

static var score := 0

static var level_ended := false

static func get_enemy_count() -> int:
	return INITIAL_ENEMY_COUNT + level * ENEMY_COUNT_PER_LEVEL


static func get_time_limit() -> float:
	return min(TIME_LIMIT_SECONDS + level * TIME_PER_LEVEL, TIME_LIMIT_SECONDS_MAX)


static func start_new_game() -> void:
	level = 0
	score = 0
	level_ended = false
	pass


static func next_level() -> void:
	level += 1
	pass
