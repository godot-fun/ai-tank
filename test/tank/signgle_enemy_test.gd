extends Node2D


func _ready() -> void:
	TankHelper.create_tank(TankConfig.my_tank, Vector2i(0, TankConfig.TileConfig.MAP_GRID_HEIGHT))
	TankHelper.create_tank(TankConfig.only_fire_enemy, Vector2i(0, 0))
	pass

