class_name Buff
extends Area2D

const FLASH_SHADER := "res://shader/buff_flash.gdshader"

static var flash_material: ShaderMaterial

var id: int
var buff: int
var grid_size: Vector2i
var buff_resource: String
var script_resource: String

var grid_pos := Vector2i.ZERO

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	sprite.texture = load(buff_resource)
	setup_flash_material()
	scale_buff()
	start()
	body_entered.connect(on_body_entered)
	pass

func apply_data(data: BuffConfig.BuffData, grid: Vector2i) -> void:
	id = data.id
	buff = data.buff
	grid_size = data.grid_size
	buff_resource = data.buff_resource
	script_resource = data.script_resource
	grid_pos = TileConfig.clamp_grid_to_bounds(grid, data.grid_size)
	global_position = TileConfig.grid_to_world(grid_pos, grid_size)
	pass

func setup_flash_material() -> void:
	if flash_material == null:
		flash_material = ShaderMaterial.new()
		flash_material.shader = load(FLASH_SHADER)
	sprite.material = flash_material
	pass


func scale_buff() -> void:
	var texture_size := sprite.texture.get_size()
	var target_size := Vector2(grid_size) * TileConfig.TILE_SIZE
	scale = target_size / texture_size
	pass

func on_body_entered(body: Node2D) -> void:
	if not body is Tank:
		return
	var tank := body as Tank
	if tank.team != TankConfig.Team.PLAYER:
		return
		
	Audios.play_sfx(AudioConfig.BUFF_LEVEL_UP)
	trigger(tank)
	queue_free()
	pass

# Interface-Start
func start() -> void:
	pass
	

func trigger(tank: Tank) -> void:
	pass
# Interface-End