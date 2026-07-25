extends Tank
class_name EnemyBoss4Cannon

func fire() -> void:
	if can_fire():
		fire_to(Vector2i.UP)
		fire_to(Vector2i.DOWN)
		fire_to(Vector2i.LEFT)
		fire_to(Vector2i.RIGHT)
	pass