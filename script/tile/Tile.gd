class_name Tile
extends StaticBody2D

const GRID_SIZE := Vector2i.ONE

@export var max_hp: int = 1

var hp: int
var grid_pos := Vector2i.ZERO

@onready var sprite: Sprite2D = $Sprite2D


func apply_data(data: TankConfig.TileData) -> void:
	max_hp = data.max_hp
	hp = max_hp
	sprite.texture = load(data.tile_resource)
	scale_tile()
	pass


func scale_tile() -> void:
	var texture_size := sprite.texture.get_size()
	var target_size := Vector2(GRID_SIZE) * TankConfig.tile_size
	scale = target_size / texture_size

	grid_pos = TankConfig.clamp_grid_to_bounds(
		TankConfig.world_to_grid(global_position, GRID_SIZE),
		GRID_SIZE,
	)
	global_position = TankConfig.grid_to_world(grid_pos, GRID_SIZE)
	pass


func take_damage(amount: int) -> void:
	if amount <= 0:
		return

	hp = maxi(hp - amount, 0)
	if hp <= 0:
		destroy()
	pass


func destroy() -> void:
	queue_free()
	pass
