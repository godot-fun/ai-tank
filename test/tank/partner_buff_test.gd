extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Eagle.create_base()
	
	TankHelper.create_tank(TankConfig.my_tank, Vector2i(1, 10))
	TankHelper.create_tank(TankConfig.tank_2, Vector2i(28, 14))

	for i in 32:
		TileHelper.create_tile(TileConfig.steel_wall, Vector2i(i, 12))
	
	BuffHelper.create_buff(BuffConfig.bullet_size_buff, Vector2i(6, 16))
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
