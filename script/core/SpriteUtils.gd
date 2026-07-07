class_name SpriteUtils

## 受击闪白：瞬间提亮 modulate，再缓回白色。
## [param sprite] 须在场景树中，Tween 挂在该节点上。
static func play_hit_flash(
	sprite: CanvasItem,
	flash_color: Color = Color(1.35, 1.2, 1.05),
	duration: float = 0.2,
) -> void:
	sprite.modulate = flash_color
	var tween := sprite.create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, duration)
	pass
