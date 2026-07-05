extends Node2D


func _ready() -> void:
	TankHelper.create_tank(TankConfig.my_tank, Vector2i(10, TileConfig.MAP_GRID_HEIGHT))
	TankHelper.create_tank(TankConfig.only_fire_enemy, Vector2i(10, 0))
	pass
