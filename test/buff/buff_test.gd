extends Node2D


func _ready() -> void:
	GameManager.init()
	Eagle.create_base()
	TankHelper.create_tank(TankConfig.my_tank, Eagle.player_tank_start_grid_pos)
	
	BuffHelper.create_buff(BuffConfig.bullet_size_buff, Vector2i(4, 4))
	BuffHelper.create_buff(BuffConfig.bullet_size_buff, Vector2i(4, 6))
	BuffHelper.create_buff(BuffConfig.bullet_size_buff, Vector2i(4, 8))
	
	BuffHelper.create_buff(BuffConfig.bullet_speed_buff, Vector2i(1, 4))
	BuffHelper.create_buff(BuffConfig.bullet_speed_buff, Vector2i(1, 6))
	BuffHelper.create_buff(BuffConfig.bullet_speed_buff, Vector2i(1, 8))
	
	BuffHelper.create_buff(BuffConfig.bullet_fire_interval_buff, Vector2i(7, 4))
	BuffHelper.create_buff(BuffConfig.bullet_fire_interval_buff, Vector2i(7, 6))
	BuffHelper.create_buff(BuffConfig.bullet_fire_interval_buff, Vector2i(7, 8))
	
	BuffHelper.create_buff(BuffConfig.tank_speed_buff, Vector2i(10, 4))
	BuffHelper.create_buff(BuffConfig.tank_speed_buff, Vector2i(10, 6))
	BuffHelper.create_buff(BuffConfig.tank_speed_buff, Vector2i(10, 8))
	
	BuffHelper.create_buff(BuffConfig.tank_hp_buff, Vector2i(13, 4))
	BuffHelper.create_buff(BuffConfig.tank_hp_buff, Vector2i(13, 6))
	BuffHelper.create_buff(BuffConfig.tank_hp_buff, Vector2i(13, 8))
	
	BuffHelper.create_buff(BuffConfig.tank_size_buff, Vector2i(16, 4))
	BuffHelper.create_buff(BuffConfig.tank_size_buff, Vector2i(16, 6))
	BuffHelper.create_buff(BuffConfig.tank_size_buff, Vector2i(16, 8))
	
	BuffHelper.create_buff(BuffConfig.tank_respawn_buff, Vector2i(19, 4))
	BuffHelper.create_buff(BuffConfig.tank_respawn_buff, Vector2i(19, 6))
	BuffHelper.create_buff(BuffConfig.tank_respawn_buff, Vector2i(19, 8))
	
	BuffHelper.create_buff(BuffConfig.freeze_buff, Vector2i(22, 4))
	BuffHelper.create_buff(BuffConfig.freeze_buff, Vector2i(22, 6))
	BuffHelper.create_buff(BuffConfig.freeze_buff, Vector2i(22, 8))
	
	BuffHelper.create_buff(BuffConfig.air_strike_buff, Vector2i(25, 4))
	BuffHelper.create_buff(BuffConfig.air_strike_buff, Vector2i(25, 6))
	BuffHelper.create_buff(BuffConfig.air_strike_buff, Vector2i(25, 8))
	
	BuffHelper.create_buff(BuffConfig.eagle_steel_buff, Vector2i(28, 4))
	BuffHelper.create_buff(BuffConfig.eagle_steel_buff, Vector2i(28, 6))
	BuffHelper.create_buff(BuffConfig.eagle_steel_buff, Vector2i(28, 8))
	
	await ThreadUtils.async_sleep(3000)
	TankHelper.create_tank(TankConfig.elite_enemy_easy, Vector2i(10, 0))
	await ThreadUtils.async_sleep(3000)
	TankHelper.create_tank(TankConfig.elite_enemy_easy, Vector2i(15, 0))
	await ThreadUtils.async_sleep(3000)
	TankHelper.create_tank(TankConfig.elite_enemy_easy, Vector2i(20, 0))
	await ThreadUtils.async_sleep(3000)
	TankHelper.create_tank(TankConfig.elite_enemy_easy, Vector2i(25, 0))
	await ThreadUtils.async_sleep(3000)
	TankHelper.create_tank(TankConfig.elite_enemy_easy, Vector2i(30, 0))
	pass
