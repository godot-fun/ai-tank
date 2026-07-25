extends EnemyEasy
class_name EnemyBoss2Cannon

func fire() -> void:
	if can_fire():
		fire_to(facing)
		fire_to(facing * -1)
	pass