extends Enemy
class_name EnemyEagle

const AI_THINK_INTERVAL := 0.6
const RANDOM_MOVE_EXTRA_STEPS_MAX := 8

var ai_think_timer := 0.0


func start() -> void:
	update_facing(Vector2i.DOWN)
	ai_think_timer = AI_THINK_INTERVAL
	pass


func physics_update(delta: float) -> void:
	ai_think_timer -= delta

	if moving:
		fire()
		return

	if ai_think_timer <= 0.0:
		ai_think_timer = AI_THINK_INTERVAL
		var direction := pick_move_direction()
		if direction != Vector2i.ZERO:
			move(direction, RandomUtils.random_int_limit(RANDOM_MOVE_EXTRA_STEPS_MAX))
		fire()
	pass


func pick_move_direction() -> Vector2i:
	if randf() < 0.25:
		return pick_random_not_blocked_direction()
	return pick_direction_toward(Eagle.egale_first_grid_pos)
