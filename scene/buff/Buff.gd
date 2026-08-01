class_name Buff
extends Area2D

const FLASH_SHADER := "res://shader/buff_flash.gdshader"
const LIFETIME_SEC := 15.0
const WARN_SEC := 5.0
const WARN_GRAY := Color(0.55, 0.55, 0.55, 1.0)
const WARN_FADE := Color(0.55, 0.55, 0.55, 0.0)

static var flash_material: ShaderMaterial

var type: int
var buff: IBuff
var grid_size: Vector2i
var buff_resource: String

var grid_pos := Vector2i.ZERO

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	z_index = 128
	sprite.texture = load(buff_resource)
	setup_flash_material()
	scale_buff()
	setup_physics_layers()
	body_entered.connect(on_body_entered)
	start_lifetime()
	pass


func setup_physics_layers() -> void:
	collision_layer = PhysicsLayers.BUFF
	collision_mask = PhysicsLayers.PLAYER_TANK
	pass

func start_lifetime() -> void:
	var tween := create_tween()
	tween.tween_interval(LIFETIME_SEC - WARN_SEC)
	tween.tween_callback(start_despawn_warning)
	tween.tween_interval(WARN_SEC)
	tween.tween_callback(queue_free)
	pass

func start_despawn_warning() -> void:
	sprite.material = null
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", WARN_GRAY, WARN_SEC * 0.5)
	tween.tween_property(sprite, "modulate", WARN_FADE, WARN_SEC * 0.5)
	pass

func apply_data(data: BuffConfig.BuffData, grid: Vector2i) -> void:
	type = data.type
	buff = data.buff
	grid_size = data.grid_size
	buff_resource = data.buff_resource
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
	if tank.is_enemy():
		return
		
	trigger_buff(tank)
	pass

func trigger_buff(tank: Tank) -> void:
	if BuffManager.add_buff(tank, type):
		Audios.play_sfx(AudioConfig.BUFF_LEVEL_UP)
		queue_free()
	pass
