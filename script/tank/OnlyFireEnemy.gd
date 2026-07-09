extends Tank
class_name OnlyFireEnemy


func start() -> void:
	update_facing(Vector2i.DOWN)
	pass


func physics_update(delta: float) -> void:
	fire()
	pass

func play_enter_animation() -> void:
	pass