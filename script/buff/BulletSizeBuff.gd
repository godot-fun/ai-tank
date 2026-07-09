class_name BulletSizeBuff
extends Buff

const MAX_BULLET_SIZE: float = 1.5

func trigger(tank: Tank) -> void:
	tank.bullet_size = min(tank.bullet_size + 0.3, MAX_BULLET_SIZE)
	pass