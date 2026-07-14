class_name BulletSizeBuff
extends Buff

const BULLET_SIZE_LEVEL_UP := 0.3
static var max_bullet_size: float = TankConfig.DEFAULT_BULLET_SIZE + BULLET_SIZE_LEVEL_UP * 3

func trigger(tank: Tank) -> void:
	tank.bullet_size = min(tank.bullet_size + BULLET_SIZE_LEVEL_UP, max_bullet_size)
	pass