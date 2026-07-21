extends Node2D


func _ready() -> void:
	TankHelper.create_tank(TankConfig.my_tank, Eagle.player_tank_start_grid_pos)
	TankHelper.create_tank_with_buffs(TankConfig.only_fire_enemy, Vector2i(10, 0), [BulletSizeBuff.new()])
	
	BuffHelper.create_buff(BuffConfig.tank_hp_buff, Vector2i(Eagle.player_tank_start_grid_pos.x, 4))
	BuffHelper.create_buff(BuffConfig.tank_hp_buff, Vector2i(Eagle.player_tank_start_grid_pos.x, 6))
	BuffHelper.create_buff(BuffConfig.tank_hp_buff, Vector2i(Eagle.player_tank_start_grid_pos.x, 8))
	
	pass
