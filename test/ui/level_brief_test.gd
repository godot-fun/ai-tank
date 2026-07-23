extends Node2D

const LEVEL_BRIEF_SCENE_PATH := "res://scene/ui/LevelBrief.tscn"


func _ready() -> void:
	GameManager.init()
	# 解锁全部友军坦克，便于查看完整列表
	BattleProgress.level = 23

	BuffManager.enemy_kill_counts[TankConfig.my_tank.id] = 15
	BuffManager.enemy_kill_counts[TankConfig.partner_tank_1.id] = 11
	BuffManager.enemy_kill_counts[TankConfig.partner_tank_2.id] = 8
	BuffManager.enemy_kill_counts[TankConfig.partner_tank_3.id] = 6
	BuffManager.enemy_kill_counts[TankConfig.partner_tank_4.id] = 4
	BuffManager.enemy_kill_counts[TankConfig.partner_tank_5.id] = 2
	BuffManager.enemy_kill_counts[TankConfig.partner_tank_6.id] = 1

	seed_buffs(TankConfig.my_tank.id, [
		BulletSizeBuff.new(),
		BulletSizeBuff.new(),
		BulletSpeedBuff.new(),
		TankHpBuff.new(),
	] as Array[IBuff])
	seed_buffs(TankConfig.partner_tank_1.id, [
		TankSpeedBuff.new(),
		TankRespawnBuff.new(),
		TankRespawnBuff.new(),
	] as Array[IBuff])
	seed_buffs(TankConfig.partner_tank_2.id, [
		BulletFireIntervalBuff.new(),
		TankSizeBuff.new(),
	] as Array[IBuff])
	seed_buffs(TankConfig.partner_tank_3.id, [
		BulletSizeBuff.new(),
		TankHpBuff.new(),
		TankHpBuff.new(),
		TankHpBuff.new(),
	] as Array[IBuff])

	await SceneHelper.async_change_scene_to_file(LEVEL_BRIEF_SCENE_PATH)
	pass


func seed_buffs(tank_id: int, buffs: Array[IBuff]) -> void:
	var container := BuffManager.get_buff_container(tank_id)
	for buff: IBuff in buffs:
		container.add_buff(buff)
	pass
