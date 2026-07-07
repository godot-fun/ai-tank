## 可破坏砖墙
##
## 【与钢墙区别】
## - hp 通常为 1，子弹一击即毁；
## - 不用着色器做 idle 动画，击毁时交给 BrickBreakEffect 做实体碎裂。
##
## 【击毁流程】
## 1. 从 TileHelper 格子注销（坦克/子弹逻辑上不再被挡）；
## 2. 缓存贴图/位置/缩放后 spawn 碎裂特效；
## 3. 隐藏 sprite 并 queue_free（本帧末销毁，碰撞随节点一并移除）。
## take_damage 入口用 hp <= 0 挡同帧多颗子弹重复触发。
##
## 【未击毁时】
## 若 hp > 0（未来多段血砖），仅对 sprite 做短暂 modulate 闪白，不碎裂。
extends Tile
class_name BrickWall


func take_damage(amount: int) -> void:
	if amount <= 0 or hp <= 0:
		return

	hp = maxi(hp - amount, 0)
	if hp <= 0:
		_play_destroy_break()
	else:
		SpriteUtils.play_hit_flash(sprite)
	pass


## 致命伤：逻辑上先「拆墙」，再删节点；视觉碎裂由 Effect 承接
func _play_destroy_break() -> void:
	# 在 free 之前缓存，否则子节点与 transform 会随节点销毁而丢失
	var texture := sprite.texture
	var world_center := global_position
	var tile_scale := scale
	var parent_node := get_parent()

	# queue_free 本帧末生效；隐藏避免本帧「整墙 + 碎块」叠影
	sprite.visible = false
	BrickBreakEffect.spawn(world_center, tile_scale, texture, parent_node)
	queue_free()
	pass
