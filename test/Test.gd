extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	TankHelper.create_tank(TankConfig.my_tank, Vector2i(10, 10))
	TankHelper.create_tank(TankConfig.enemy_easy, Vector2i(0, 0))
	
	for i in 32:
		TileHelper.create_tile(TileConfig.brick_wall, Vector2i(i, 8))
	for i in 32:
		TileHelper.create_tile(TileConfig.brick_wall, Vector2i(i, 9))
	for i in range(10, 22):
		TileHelper.create_tile(TileConfig.water, Vector2i(i, 12))
	for i in range(14, 18):
		TileHelper.create_tile(TileConfig.steel_wall, Vector2i(i, 6))
	for i in range(6, 10):
		for j in range(14, 17):
			TileHelper.create_tile(TileConfig.forest, Vector2i(i, j))
	for i in range(20, 26):
		for j in range(14, 17):
			TileHelper.create_tile(TileConfig.ice, Vector2i(i, j))
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
