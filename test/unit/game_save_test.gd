static func game_save_roundtrip_test() -> void:
	FileUtils.delete_file(GameSave.SAVE_PATH)
	BuffManager.buff_map.clear()
	BattleProgress.level = 5
	BattleProgress.play_mode = BattleProgress.PlayMode.AI

	var player_container := BuffContainer.new()
	player_container.add_buff(BulletSizeBuff.new())
	player_container.add_buff(BulletSizeBuff.new())
	player_container.add_buff(TankSpeedBuff.new())
	BuffManager.buff_map[1] = player_container

	var partner_container := BuffContainer.new()
	partner_container.add_buff(TankHpBuff.new())
	BuffManager.buff_map[2] = partner_container

	GameSave.save()

	BattleProgress.level = 0
	BattleProgress.play_mode = BattleProgress.PlayMode.HUMAN
	BuffManager.buff_map.clear()

	assert(GameSave.load_save())
	assert(BattleProgress.level == 5)
	assert(BattleProgress.play_mode == BattleProgress.PlayMode.AI)
	assert(BuffManager.buff_map.has(1))
	assert(BuffManager.buff_map.has(2))
	assert(BuffManager.buff_map[1].buff_type_of_size(IBuff.BuffType.BULLET_SIZE) == 2)
	assert(BuffManager.buff_map[1].buff_type_of_size(IBuff.BuffType.TANK_SPEED) == 1)
	assert(BuffManager.buff_map[2].buff_type_of_size(IBuff.BuffType.TANK_HP) == 1)

	FileUtils.delete_file(GameSave.SAVE_PATH)
	BuffManager.buff_map.clear()
	BattleProgress.level = 0
	BattleProgress.play_mode = BattleProgress.PlayMode.HUMAN
	pass


static func game_save_missing_file_test() -> void:
	FileUtils.delete_file(GameSave.SAVE_PATH)
	assert(!GameSave.load_save())
	pass
