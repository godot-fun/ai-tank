extends Node2D


func _ready() -> void:
	Eagle.create_base()
	TankHelper.create_tank(TankConfig.my_partner_tank, Eagle.player_tank_start_grid_pos)
	TankHelper.create_tank_with_buffs(TankConfig.only_fire_enemy, Eagle.egale_first_grid_pos + Vector2i.LEFT * 4, [BulletSizeBuff.new()])
	
	BuffHelper.create_buff(BuffConfig.tank_hp_buff, Vector2i(Eagle.player_tank_start_grid_pos.x, 4))
	BuffHelper.create_buff(BuffConfig.tank_hp_buff, Vector2i(Eagle.player_tank_start_grid_pos.x, 6))
	BuffHelper.create_buff(BuffConfig.tank_hp_buff, Vector2i(Eagle.player_tank_start_grid_pos.x, 8))
	
	TileHelper.create_tile(TileConfig.brick_wall, Vector2i(12, 8))
	TileHelper.create_tile(TileConfig.steel_wall, Vector2i(14, 8))
	TileHelper.create_tile(TileConfig.forest, Vector2i(16, 8))
	TileHelper.create_tile(TileConfig.ice, Vector2i(18, 8))
	TileHelper.create_tile(TileConfig.water, Vector2i(20, 8))
	
	pass
