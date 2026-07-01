extends Tank
class_name PartnerTank

const AI_THINK_INTERVAL := 0.5

var ai_think_timer := 0.0


func start() -> void:
	apply_data(TankConfig.partner_tank)
	facing = Vector2i.UP
	update_facing(facing)
	ai_think_timer = AI_THINK_INTERVAL
	pass


func update(delta: float) -> void:
	ai_think_timer -= delta

	if moving:
		fire()
		return

	if ai_think_timer <= 0.0:
		ai_think_timer = AI_THINK_INTERVAL
		var direction := pick_move_direction()
		if direction != Vector2i.ZERO:
			try_move(direction)
	pass


func pick_move_direction() -> Vector2i:
	var target_grid := Vector2i.ZERO

	var enemy := TankHelper.find_nearest_enemy(self)
	if enemy != null:
		target_grid = TankHelper.get_tank_grid(enemy)
	else:
		var leader := TankHelper.find_player()
		if leader != null and leader != self:
			target_grid = TankHelper.get_tank_grid(leader)

	if target_grid == Vector2i.ZERO:
		return Vector2i.ZERO

	return pick_direction_toward(target_grid)
	pass


func pick_direction_toward(target_grid: Vector2i) -> Vector2i:
	var diff := target_grid - grid_pos
	if diff == Vector2i.ZERO:
		return Vector2i.ZERO

	var candidates: Array[Vector2i] = []
	if diff.x != 0:
		candidates.append(Vector2i.RIGHT if signi(diff.x) > 0 else Vector2i.LEFT)
	if diff.y != 0:
		candidates.append(Vector2i.DOWN if signi(diff.y) > 0 else Vector2i.UP)

	candidates.shuffle()
	for direction in candidates:
		if not TankHelper.is_move_blocked(grid_pos + direction, grid_size, self):
			return direction

	return Vector2i.ZERO
	pass
