extends Tank
class_name OnlyFireEnemy


func start() -> void:
	update_facing(Vector2i.DOWN)
	pass


func update(delta: float) -> void:
	fire()
	pass
