extends Tank
class_name MyTank

var grid_pos := Vector2i.ZERO
var facing := Vector2i(0, -1)
var moving := false

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	apply_data(TankConfig.my_tank)
	scale_tank()
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


func scale_tank() -> void:
	var texture_size := sprite.texture.get_size()
	var target_size := Vector2(TankConfig.tank_grid_size) * TankConfig.tile_size
	scale = target_size / texture_size

	grid_pos = TankConfig.clamp_grid_to_bounds(TankConfig.world_to_grid(global_position))
	global_position = TankConfig.grid_to_world(grid_pos)
	pass


func update_facing(direction: Vector2i) -> void:
	facing = direction
	sprite.rotation = Vector2(direction).angle() + PI / 2.0
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


func try_move(direction: Vector2i) -> void:
	update_facing(direction)

	var target_grid := grid_pos + direction
	if not TankConfig.is_in_bounds(target_grid):
		return

	grid_pos = target_grid
	moving = true

	var move_duration := TankConfig.tile_size / speed
	var tween := create_tween()
	tween.tween_property(self, "global_position", TankConfig.grid_to_world(grid_pos), move_duration)
	tween.finished.connect(on_move_finished)
	pass


func try_shoot() -> void:
	if not can_fire():
		return

	var aim_direction := read_direction()
	if aim_direction != Vector2i.ZERO:
		update_facing(aim_direction)

	var bullet_scene: PackedScene = load(bullet_resource)
	var bullet: BasicBullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)

	var spawn_offset := Vector2(facing) * TankConfig.tile_size
	bullet.launch(global_position + spawn_offset, facing, team, bullet_speed, bullet_damage)
	start_fire_cooldown()
	pass


func on_move_finished() -> void:
	moving = false
	var direction := read_direction()
	if direction != Vector2i.ZERO:
		try_move(direction)
	pass
