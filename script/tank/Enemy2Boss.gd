extends Tank
class_name Enemy2Boss

func fire() -> void:
	if can_fire():
		fire_to(facing)
		fire_to(-facing)
	pass