extends Node2D

const LEVEL_BRIEF_SCENE_PATH := "res://scene/ui/LevelBrief.tscn"
const MIN_BUFF_COUNT := 12
const MAX_BUFF_COUNT := 24

## 会进入 buff_map 的可叠加 buff（即时类 buff 不计入）
const STACKABLE_BUFF_TYPES: Array[int] = [
	IBuff.BuffType.BULLET_SIZE,
	IBuff.BuffType.BULLET_SPEED,
	IBuff.BuffType.BULLET_FIRE_INTERVAL,
	IBuff.BuffType.TANK_SPEED,
	IBuff.BuffType.TANK_HP,
	IBuff.BuffType.TANK_RESPAWN,
	IBuff.BuffType.TANK_SIZE,
]


func _ready() -> void:
	GameManager.init()
	# 解锁全部友军坦克，便于查看完整列表
	BattleProgress.level = 19

	var tanks: Array[TankConfig.TankData] = [
		TankConfig.my_tank,
		TankConfig.partner_tank_1,
		TankConfig.partner_tank_2,
		TankConfig.partner_tank_3,
		TankConfig.partner_tank_4,
		TankConfig.partner_tank_5,
		TankConfig.partner_tank_6,
	]
	for tank_data: TankConfig.TankData in tanks:
		BuffManager.enemy_kill_counts[tank_data.id] = randi_range(0, 20)
		seed_random_buffs(tank_data.id)

	await SceneHelper.async_change_scene_to_file(LEVEL_BRIEF_SCENE_PATH)
	pass


func seed_random_buffs(tank_id: int) -> void:
	var container := BuffManager.get_buff_container(tank_id)
	var count := randi_range(MIN_BUFF_COUNT, MAX_BUFF_COUNT)
	for i in count:
		var buff_type: int = STACKABLE_BUFF_TYPES[randi_range(0, STACKABLE_BUFF_TYPES.size() - 1)]
		var buff := create_buff(buff_type)
		if buff != null:
			container.add_buff(buff)
	pass


func create_buff(buff_type: int) -> IBuff:
	match buff_type:
		IBuff.BuffType.BULLET_SIZE:
			return BulletSizeBuff.new()
		IBuff.BuffType.BULLET_SPEED:
			return BulletSpeedBuff.new()
		IBuff.BuffType.BULLET_FIRE_INTERVAL:
			return BulletFireIntervalBuff.new()
		IBuff.BuffType.TANK_SPEED:
			return TankSpeedBuff.new()
		IBuff.BuffType.TANK_HP:
			return TankHpBuff.new()
		IBuff.BuffType.TANK_RESPAWN:
			return TankRespawnBuff.new()
		IBuff.BuffType.TANK_SIZE:
			return TankSizeBuff.new()
		_:
			return null
