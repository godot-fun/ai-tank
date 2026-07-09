extends Tank
class_name EnemyEasy

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
	var player := TankHelper.find_player()
	if player == null:
		return pick_random_direction()
	if randf() < 0.35:
		return pick_random_not_blocked_direction()
	return pick_direction_toward(TankHelper.get_tank_grid(player))


func play_enter_animation() -> void:
	visible = false
	moving = true
	update_facing(Vector2i.DOWN)

	var target_pos := global_position
	global_position = Vector2(
		target_pos.x,
		-grid_size.y * TileConfig.TILE_SIZE * 0.5 - TileConfig.TILE_SIZE,
	)
	visible = true

	var duration := global_position.distance_to(target_pos) / speed
	var tween := create_tween()
	tween.tween_property(self, "global_position", target_pos, duration)
	tween.finished.connect(func() -> void:
		moving = false
		global_position = TankConfig.grid_to_world(grid_pos, grid_size)
	)
	pass
