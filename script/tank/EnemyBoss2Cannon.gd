extends Tank
class_name EnemyBoss2Cannon

func fire() -> void:
	if can_fire():
		fire_to(facing)
		fire_to(-facing)
	pass