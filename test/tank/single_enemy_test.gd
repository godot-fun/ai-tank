extends Node2D


func _ready() -> void:
	TankHelper.create_tank(TankConfig.my_tank, Eagle.player_tank_start_grid_pos)
	TankHelper.create_tank(TankConfig.only_fire_enemy, Vector2i(10, 0))
	pass
