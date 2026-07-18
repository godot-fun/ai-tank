class_name BattleProgress

const LEVEL_TIME: Array[float] = [30, 35, 40, 60, 70
								, 45, 50, 55, 70, 80
								, 60, 60, 60, 80, 90
								, 60, 60, 60, 80, 90
								, 60, 60, 60, 90, 100
								, 60, 60, 60, 90, 110
								, 60, 60, 60, 90, 120]

# 关卡编号使用玩家看到的 1-based 编号，区间包含首尾关卡。
class LevelMusicRange:
	var first_level: int
	var last_level: int
	var music: String

	func _init(_first_level: int, _last_level: int, _music: String) -> void:
		first_level = _first_level
		last_level = _last_level
		music = _music
	pass


static var LEVEL_MUSIC_RANGES: Array[LevelMusicRange] = [
	LevelMusicRange.new(1, 3, AudioConfig.BGM_STAGE_1),
	LevelMusicRange.new(4, 6, AudioConfig.BGM_FC_STAGE_1),
	LevelMusicRange.new(7, 9, AudioConfig.BGM_STAGE_2),
	LevelMusicRange.new(10, 12, AudioConfig.BGM_FC_STAGE_2),
	LevelMusicRange.new(13, 15, AudioConfig.BGM_STAGE_3),
	LevelMusicRange.new(16, 18, AudioConfig.BGM_FC_STAGE_3),
	LevelMusicRange.new(19, 21, AudioConfig.BGM_STAGE_4),
	LevelMusicRange.new(22, 24, AudioConfig.BGM_FC_STAGE_4),
	LevelMusicRange.new(25, 28, AudioConfig.BGM_STAGE_5),
	LevelMusicRange.new(29, 33, AudioConfig.BGM_FC_STAGE_5),
	LevelMusicRange.new(34, 35, AudioConfig.BGM_STAGE_6),
]

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


static func get_current_level_music() -> String:
	var level_number := level + 1
	for music_range: LevelMusicRange in LEVEL_MUSIC_RANGES:
		if level_number >= music_range.first_level and level_number <= music_range.last_level:
			return music_range.music

	push_error("No music configured for level: %d" % level_number)
	return AudioConfig.BGM_STAGE_1


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