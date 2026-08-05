## 坦克 Agent 策略：保存文本策略，经 AI 生成 GDScript，游戏中优先使用生成代码。
class_name TankAgentManager

const ROOT_DIR := "user://tank_agent/"
const STRATEGIES_PATH := ROOT_DIR + "strategies.json"
const SCRIPTS_DIR := ROOT_DIR + "scripts/"
const SCRIPT_EXT := ".gd"

## 唯一配置源：agent key → TankConfig.id
static var AGENT_TANK_IDS: Dictionary[String, int] = {
	"my_tank_ai": TankConfig.my_tank_ai.id,
	"partner_tank_1": TankConfig.partner_tank_1.id,
	"partner_tank_2": TankConfig.partner_tank_2.id,
	"partner_tank_3": TankConfig.partner_tank_3.id,
	"partner_tank_4": TankConfig.partner_tank_4.id,
	"partner_tank_5": TankConfig.partner_tank_5.id,
}

const SYSTEM_PROMPT := """你是 Godot 4.x GDScript 坦克 AI 代码生成器。根据用户给出的策略描述，生成完整可运行的坦克脚本。

硬性要求：
1. 第一行必须是：extends PartnerSmartTank
2. 禁止使用 class_name
3. 只输出纯 GDScript 源码，不要 Markdown 代码围栏，不要解释文字
4. 可覆盖 physics_update、pick_move_direction、fire、fire_on_enemy、go_to 等
5. 可用能力：move(direction)、move(direction, extra_steps)、fire()、can_fire()、update_facing(direction)、go_to(target_grid)、find_direct_fire_direction()、ray_detect_nearest_objects_in_front()、BuffHelper.find_nearest_obtainable_buff(self, range)、TankHelper.find_nearest_enemy(self)、TankHelper.find_player()、BestFireGridStrategy.find_best_fire_grid(self)、PathFinderHelper.find_path(...)
6. 成员：grid_pos、facing、moving、ai_think_timer、pending_steps；方向为 Vector2i.UP/DOWN/LEFT/RIGHT
7. 绝不能误伤基地 Eagle；开火前用射线检测跳过 Eagle / BrickWallEagle
8. 代码风格：显式类型、业务方法不加下划线前缀、无 return 的函数末尾写 pass
"""

static var AGENT_KEYS: Array[String] = build_agent_keys()
static var KEY_BY_TANK_ID: Dictionary[int, String] = build_key_by_tank_id()
static var strategies: Dictionary[String, String] = load_strategies()


static func build_agent_keys() -> Array[String]:
	var keys: Array[String] = []
	for key: String in AGENT_TANK_IDS:
		keys.append(key)
	return keys


static func build_key_by_tank_id() -> Dictionary[int, String]:
	var result: Dictionary[int, String] = {}
	for key: String in AGENT_TANK_IDS:
		result[AGENT_TANK_IDS[key]] = key
	return result


static func load_strategies() -> Dictionary[String, String]:
	var result: Dictionary[String, String] = {}
	for key in AGENT_KEYS:
		result[key] = StringUtils.EMPTY

	var json := FileUtils.read_file_to_string(STRATEGIES_PATH)
	if StringUtils.is_blank(json):
		return result

	var data: Variant = JSON.parse_string(json)
	if typeof(data) != TYPE_DICTIONARY:
		Log.error("tank agent strategies parse failed path:[{}]", STRATEGIES_PATH)
		return result

	var dict: Dictionary = data
	for key in AGENT_KEYS:
		if dict.has(key):
			result[key] = str(dict[key])
	return result


static func save_strategies() -> void:
	ensure_dir(ROOT_DIR)
	FileUtils.write_string_to_file(STRATEGIES_PATH, JsonUtils.object_to_json(strategies))
	Log.info("tank agent strategies saved path:[{}]", STRATEGIES_PATH)
	pass


static func get_strategy(key: String) -> String:
	return strategies.get(key, StringUtils.EMPTY)


static func set_strategy(key: String, text: String) -> void:
	if not AGENT_TANK_IDS.has(key):
		Log.error("unknown tank agent key:[{}]", key)
		return
	strategies[key] = text
	pass


static func agent_key_for_tank_id(tank_id: int) -> String:
	return KEY_BY_TANK_ID.get(tank_id, StringUtils.EMPTY)


static func script_path(key: String) -> String:
	return SCRIPTS_DIR + key + SCRIPT_EXT


static func has_generated_script(key: String) -> bool:
	if StringUtils.is_blank(key):
		return false
	var path := script_path(key)
	if !FileAccess.file_exists(path):
		return false
	return !StringUtils.is_blank(FileUtils.read_file_to_string(path))


static func delete_generated_script(key: String) -> void:
	var path := script_path(key)
	if FileAccess.file_exists(path):
		FileUtils.delete_file(path)
		Log.info("tank agent script deleted key:[{}] path:[{}]", key, path)
	pass


static func load_generated_script(key: String) -> Script:
	if !has_generated_script(key):
		return null
	var source := FileUtils.read_file_to_string(script_path(key))
	var script := GDScript.new()
	script.source_code = source
	var err := script.reload()
	if err != OK:
		Log.error("tank agent script reload failed key:[{}] err:[{}]", key, err)
		return null
	return script


## 优先返回 Agent 生成脚本；没有则回退 TankConfig 默认脚本。
static func resolve_script(data: TankConfig.TankData) -> Script:
	var key := agent_key_for_tank_id(data.id)
	if !StringUtils.is_blank(key):
		var agent_script := load_generated_script(key)
		if agent_script != null:
			Log.info("use tank agent script key:[{}] tank_id:[{}]", key, data.id)
			return agent_script
	return load(data.script_resource)


static func async_generate_one(key: String) -> bool:
	var strategy := get_strategy(key)
	if StringUtils.is_blank(strategy):
		delete_generated_script(key)
		return true

	var reply := await OpenAiClient.async_chat(strategy, SYSTEM_PROMPT)
	var code := extract_gdscript(reply)
	if StringUtils.is_blank(code):
		Log.error("tank agent generate empty code key:[{}]", key)
		return false

	ensure_dir(SCRIPTS_DIR)
	FileUtils.write_string_to_file(script_path(key), code)
	Log.info("tank agent script generated key:[{}] path:[{}]", key, script_path(key))
	return true


static func async_generate_all() -> Dictionary:
	var ok_count := 0
	var fail_count := 0
	var skip_count := 0
	for key in AGENT_KEYS:
		if StringUtils.is_blank(get_strategy(key)):
			delete_generated_script(key)
			skip_count += 1
			continue
		if await async_generate_one(key):
			ok_count += 1
		else:
			fail_count += 1
	return {
		"ok": ok_count,
		"fail": fail_count,
		"skip": skip_count,
	}


static func extract_gdscript(text: String) -> String:
	if StringUtils.is_blank(text):
		return StringUtils.EMPTY
	var code := FileUtils.normalize_line_endings_to_lf(text).strip_edges()
	if code.begins_with("```"):
		var first_newline := code.find("\n")
		if first_newline >= 0:
			code = code.substr(first_newline + 1)
		var fence := code.rfind("```")
		if fence >= 0:
			code = code.substr(0, fence)
		code = code.strip_edges()
	return code


static func ensure_dir(dir_path: String) -> void:
	if DirAccess.dir_exists_absolute(dir_path):
		return
	DirAccess.make_dir_recursive_absolute(dir_path)
	pass
