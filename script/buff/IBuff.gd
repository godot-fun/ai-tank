class_name IBuff

enum BuffType {
	BULLET_SIZE,
	BULLET_SPEED,
	BULLET_FIRE_INTERVAL,
	
	TANK_SPEED,
	TANK_HP,
	TANK_RESPAWN,
	TANK_SIZE,
	
	FREEZE,
	AIR_STRIKE,
	EAGLE_STEEL,
	
	UNKNOWN,
}

# Interface-Start
func trigger(tank: Tank) -> void:
	pass

func type() -> BuffType:
	return BuffType.UNKNOWN
# Interface-End