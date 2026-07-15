class_name FreezeBuff
extends Buff

const EFFECT_DURATION := 7.0


func trigger(tank: Tank) -> void:
	var enemies: Array[Tank] = []
	for target in TankHelper.tanks:
		if target.team == TankConfig.Team.ENEMY and target.is_alive():
			target.set_physics_process(false)
			enemies.append(target)

	tank.get_tree().create_timer(EFFECT_DURATION).timeout.connect(func() -> void:
		for enemy in enemies:
			if is_instance_valid(enemy):
				enemy.set_physics_process(true)
	)
