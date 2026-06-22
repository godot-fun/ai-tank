extends StaticBody2D
class_name Eagle

const GRID_SIZE := Vector2i(2, 2)
const TEXTURE_INTACT := "res://image/characters/eagle_base_1.png"
const TEXTURE_DESTROYED := "res://image/characters/eagle_base_6.png"

signal destroyed

var grid_pos := Vector2i.ZERO
var _alive := true

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	_setup_sprite(TEXTURE_INTACT)
	_align_to_grid()
	EagleHelper.register(self)
	pass


func _exit_tree() -> void:
	EagleHelper.unregister()
	pass


func is_alive() -> bool:
	return _alive


func blocks_bullet() -> bool:
	return _alive


func take_damage(amount: int, attacker_team: int) -> void:
	if not _alive or amount <= 0:
		return
	if attacker_team != TankConfig.Team.ENEMY:
		return

	_destroy()
	pass


func _destroy() -> void:
	if not _alive:
		return

	_alive = false
	_setup_sprite(TEXTURE_DESTROYED)
	destroyed.emit()
	get_tree().paused = true
	pass


func _setup_sprite(texture_path: String) -> void:
	sprite.texture = load(texture_path)
	var texture_size := sprite.texture.get_size()
	var target_size := Vector2(GRID_SIZE) * TankConfig.tile_size
	scale = target_size / texture_size
	pass


func _align_to_grid() -> void:
	grid_pos = TankConfig.clamp_grid_to_bounds(grid_pos, GRID_SIZE)
	global_position = TankConfig.grid_to_world(grid_pos, GRID_SIZE)
	pass
