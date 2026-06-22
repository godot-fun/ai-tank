extends Tank
class_name MyTank


func _ready() -> void:
	Log.info("map size:[{} * {}]", TankConfig.map_grid_width, TankConfig.map_grid_height)
	apply_data(TankConfig.my_tank)
	pass


func _physics_process(delta: float) -> void:
	update_fire_cooldown(delta)

	if Input.is_action_pressed("ui_accept"):
		try_shoot()

	if moving:
		return

	var direction := read_direction()
	if direction != Vector2i.ZERO:
		try_move(direction)
	pass


func read_direction() -> Vector2i:
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		return Vector2i(0, -1)
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		return Vector2i(0, 1)
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		return Vector2i(-1, 0)
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		return Vector2i(1, 0)
	return Vector2i.ZERO


func on_move_continue() -> void:
	var direction := read_direction()
	if direction != Vector2i.ZERO:
		try_move(direction)
	pass
