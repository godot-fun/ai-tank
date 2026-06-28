class_name BattleProgress

const INITIAL_ENEMY_COUNT := 30
const ENEMY_COUNT_PER_LEVEL := 5
const TIME_LIMIT_SECONDS := 60.0

static var level := 1


static func get_enemy_count() -> int:
	return INITIAL_ENEMY_COUNT + (level - 1) * ENEMY_COUNT_PER_LEVEL


static func get_time_limit() -> float:
	return TIME_LIMIT_SECONDS


static func start_new_game() -> void:
	level = 1


static func next_level() -> void:
	level += 1
