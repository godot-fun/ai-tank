class_name BulletSizeBuff
extends IBuff

const BULLET_SIZE_EFFECT_VALUE := 0.3
const BULLET_DAMAGE_EFFECT_VALUE := 1

func trigger(tank: Tank) -> void:
	tank.bullet_size = tank.bullet_size + BULLET_SIZE_EFFECT_VALUE
	tank.bullet_damage = tank.bullet_damage + BULLET_DAMAGE_EFFECT_VALUE
	pass

static func type() -> BuffType:
	return BuffType.BULLET_SIZE

static func new_buff() -> IBuff:
	return BulletSizeBuff.new()