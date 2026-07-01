extends Tank
class_name OnlyFireEnemy


func start() -> void:
	apply_data(TankConfig.enemy_easy)
	update_facing(Vector2i.DOWN)
	pass


func update(delta: float) -> void:
	fire()
	pass

