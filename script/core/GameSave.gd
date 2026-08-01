## 游戏存档：level、play_mode、buff_map
class_name GameSave

const SAVE_PATH := "user://game_save.json"


## tank_id 对应的 buff 类型列表（IBuff 无法直接 JSON 往返）
class BuffMapEntry:
	var buff_types: Array[int] = []
	pass


var level: int = 0
var play_mode: int = 0
## key 为 tank_id 字符串（JSON 字典 key 必须是字符串）
var buff_map: Dictionary[String, BuffMapEntry] = {}


static func from_current() -> GameSave:
	var data := GameSave.new()
	data.level = BattleProgress.level
	data.play_mode = BattleProgress.play_mode as int
	for tank_id: int in BuffManager.buff_map:
		var entry := BuffMapEntry.new()
		for buff: IBuff in BuffManager.buff_map[tank_id].buffs:
			entry.buff_types.append(buff.type() as int)
		data.buff_map[str(tank_id)] = entry
	return data


func apply() -> void:
	BattleProgress.level = level
	BattleProgress.play_mode = play_mode as BattleProgress.PlayMode
	BuffManager.buff_map.clear()
	for tank_id_str: String in buff_map:
		var tank_id := int(tank_id_str)
		var container := BuffContainer.new()
		for buff_type: int in buff_map[tank_id_str].buff_types:
			if !BuffConfig.buff_datas.has(buff_type):
				continue
			container.add_buff(BuffConfig.buff_datas[buff_type].buff.new_buff())
		BuffManager.buff_map[tank_id] = container
	pass


static func has_save() -> bool:
	if !FileAccess.file_exists(SAVE_PATH):
		return false
	return !StringUtils.is_blank(FileUtils.read_file_to_string(SAVE_PATH))


static func save() -> void:
	FileUtils.write_string_to_file(SAVE_PATH, JsonUtils.object_to_json(from_current()))
	Log.info("game saved level:[{}] play_mode:[{}] path:[{}]", BattleProgress.level, BattleProgress.play_mode, SAVE_PATH)
	pass


static func load_save() -> bool:
	var json := FileUtils.read_file_to_string(SAVE_PATH)
	if StringUtils.is_blank(json):
		return false
	var data: GameSave = JsonUtils.json_to_object(json, GameSave)
	if data == null:
		return false
	data.apply()
	return true
