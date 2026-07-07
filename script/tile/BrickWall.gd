## 可破坏砖墙
##
## 【idle】brick_mortar 着色器：暗红砖面呼吸 + 砂浆加深 + 弱铆钉光（对比 SteelWall 冷金属）。
## 【击毁】BrickBreakEffect 切片飞散；轻伤 SpriteUtils.play_hit_flash。
##
## 【击毁流程】
## 1. 从 TileHelper 注销；
## 2. 缓存贴图/缩放后 spawn 碎裂；
## 3. 隐藏 sprite 并 queue_free。
extends Tile
class_name BrickWall

const MORTAR_SHADER := "res://shader/brick_mortar.gdshader"

static var mortar_material: ShaderMaterial


func start() -> void:
	setup_mortar_material()
	pass


func setup_mortar_material() -> void:
	if mortar_material == null:
		mortar_material = ShaderMaterial.new()
		mortar_material.shader = load(MORTAR_SHADER)
	sprite.material = mortar_material
	pass


func take_damage(amount: int) -> void:
	if amount <= 0 or hp <= 0:
		return

	hp = maxi(hp - amount, 0)
	if hp <= 0:
		play_destroy_break()
	else:
		SpriteUtils.play_hit_flash(sprite)
	pass


func play_destroy_break() -> void:
	var texture := sprite.texture
	var world_center := global_position
	var tile_scale := scale
	var parent_node := get_parent()

	sprite.visible = false
	BrickBreakEffect.spawn(world_center, tile_scale, texture, parent_node)
	queue_free()
	pass
