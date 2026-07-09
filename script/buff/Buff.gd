class_name Buff
extends StaticBody2D

var id: int
var buff: int
var grid_size: Vector2i
var buff_resource: String
var script_resource: String

var grid_pos := Vector2i.ZERO

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	sprite.texture = load(buff_resource)
	scale_buff()
	start()
	pass

func start() -> void:
	pass

func apply_data(data: BuffConfig.BuffData) -> void:
	id = data.id
	buff = data.buff
	grid_size = data.grid_size
	buff_resource = data.buff_resource
	script_resource = data.script_resource
	pass

func scale_buff() -> void:
	var texture_size := sprite.texture.get_size()
	var target_size := Vector2(grid_size) * TileConfig.TILE_SIZE
	scale = target_size / texture_size

	grid_pos = TankConfig.clamp_grid_to_bounds(TankConfig.world_to_grid(global_position, Vector2i.ONE), Vector2i.ONE)
	global_position = TankConfig.grid_to_world(grid_pos, Vector2i.ONE)
	pass



