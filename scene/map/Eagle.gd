extends StaticBody2D
class_name Eagle

const GRID_SIZE := Vector2i(2, 2)
const TEXTURE_INTACT := "res://image/characters/eagle_base_1.png"
const TEXTURE_DESTROYED := "res://image/characters/eagle_base_6.png"

signal destroyed

var grid_pos := Vector2i.ZERO

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	setup_sprite(TEXTURE_INTACT)
	align_to_grid()
	pass



func take_damage(amount: int, attacker_team: int) -> void:
	if amount <= 0:
		return
	_destroy()
	pass


func _destroy() -> void:
	setup_sprite(TEXTURE_DESTROYED)
	destroyed.emit()
#	get_tree().paused = true
	pass


func setup_sprite(texture_path: String) -> void:
	sprite.texture = load(texture_path)
	var texture_size := sprite.texture.get_size()
	var target_size := Vector2(GRID_SIZE) * TankConfig.tile_size
	scale = target_size / texture_size
	pass


func align_to_grid() -> void:
	grid_pos = EagleHelper.grid_pos
	global_position = TankConfig.grid_to_world(grid_pos, GRID_SIZE)
	pass
