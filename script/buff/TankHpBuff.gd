class_name TankHpBuff
extends IBuff

const EFFECT_VALUE: int = 1
	
func trigger(tank: Tank) -> void:
	tank.hp = tank.hp + EFFECT_VALUE
	tank.max_hp = tank.max_hp + EFFECT_VALUE
	tank.update_hp_color()
	pass

static func type() -> BuffType:
	return BuffType.TANK_HP