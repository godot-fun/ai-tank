extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Eagle.create_eagle()
	
	TankHelper.create_tank(TankConfig.my_tank, Vector2i(1, 10))
	TankHelper.create_tank(TankConfig.partner_tank_1, Vector2i(1, 8))
	TankHelper.create_tank(TankConfig.enemy_easy, Vector2i(4, 14))
	TankHelper.create_tank(TankConfig.only_fire_enemy, Vector2i(18, 16))

	TileHelper.create_tile(TileConfig.steel_wall, Vector2i(10, 15))
	TileHelper.create_tile(TileConfig.steel_wall, Vector2i(10, 16))
	TileHelper.create_tile(TileConfig.steel_wall, Vector2i(10, 17))
	
	for i in 32:
		TileHelper.create_tile(TileConfig.steel_wall, Vector2i(i, 14))
	BuffHelper.create_buff(BuffConfig.bullet_size_buff, Vector2i(6, 16))
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
