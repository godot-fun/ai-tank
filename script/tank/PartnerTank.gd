extends Tank
class_name PartnerTank

const AI_THINK_INTERVAL := 0.5
const RANDOM_MOVE_EXTRA_STEPS_MAX := 2
const BUFF_SEEK_RANGE := 5


var ai_think_timer := 0.0


func start() -> void:
	facing = Vector2i.UP
	update_facing(facing)
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
	var target_grid := Vector2i.ZERO

	var nearby_buff := BuffHelper.find_nearest_obtainable_buff(self, BUFF_SEEK_RANGE)
	if nearby_buff != null:
		target_grid = nearby_buff.grid_pos
	else:
		var enemy := TankHelper.find_nearest_enemy(self)
		if enemy != null:
			target_grid = enemy.grid_pos
		else:
			var leader := TankHelper.find_player()
			if leader != null and leader != self:
				target_grid = leader.grid_pos

	if target_grid == Vector2i.ZERO:
		return Vector2i.ZERO

	return pick_direction_toward(target_grid)


func fire() -> void:
	if is_aiming_at_home():
		return
	super.fire()


func is_aiming_at_home() -> bool:
	var home := Eagle.egale_first_grid_pos
	var home_max := home + Vector2i.ONE

	var x_overlap := grid_pos.x <= home_max.x and grid_pos.x + grid_size.x - 1 >= home.x
	var y_overlap := grid_pos.y <= home_max.y and grid_pos.y + grid_size.y - 1 >= home.y

	match facing:
		Vector2i.LEFT:
			return grid_pos.x > home_max.x and y_overlap
		Vector2i.RIGHT:
			return grid_pos.x + grid_size.x - 1 < home.x and y_overlap
		Vector2i.DOWN:
			return x_overlap and grid_pos.y + grid_size.y - 1 <= home_max.y
	return false