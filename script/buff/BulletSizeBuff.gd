class_name BulletSizeBuff
extends Buff


func trigger(tank: Tank) -> void:
	tank.bullet_size = tank.bullet_size + 0.3 
	pass