extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	TankHelper.create_tank(TankConfig.my_tank, Vector2i(10, 10))
	TankHelper.create_tank(TankConfig.enemy_easy, Vector2i(0, 0))
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
