class_name BattleProgress

static var level := 1


static func get_enemy_count() -> int:
	return MapGeneratorHelper.calc_enemy_count(level)


static func start_new_game() -> void:
	level = 1


static func next_level() -> void:
	level += 1
