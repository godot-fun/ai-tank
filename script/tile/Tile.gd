class_name Tile
extends StaticBody2D

@export var max_hp: int = 1

var hp: int
var grid_pos := Vector2i.ZERO
var bullet_hit_sound_resource := ""

@onready var sprite: Sprite2D = $Sprite2D


func apply_data(data: TileConfig.TileCell) -> void:
	max_hp = data.max_hp
	hp = max_hp
	bullet_hit_sound_resource = data.bullet_hit_sound_resource
	sprite.texture = load(data.tile_resource)
	scale_tile()
	pass


func blocks_tank() -> bool:
	return true


func blocks_bullet() -> bool:
	return true


func is_ice() -> bool:
	return false

func scale_tile() -> void:
	var texture_size := sprite.texture.get_size()
	var target_size := Vector2.ONE * TankConfig.tile_size
	scale = target_size / texture_size

	grid_pos = TankConfig.clamp_grid_to_bounds(
		TankConfig.world_to_grid(global_position, Vector2i.ONE),
		Vector2i.ONE,
	)
	global_position = TankConfig.grid_to_world(grid_pos, Vector2i.ONE)
	TileHelper.register_tile(self)
	pass


func _exit_tree() -> void:
	TileHelper.unregister_tile(self)
	pass


func play_bullet_hit_sound() -> void:
	if StringUtils.is_blank(bullet_hit_sound_resource):
		return

	Audio.play_sound(bullet_hit_sound_resource)
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
