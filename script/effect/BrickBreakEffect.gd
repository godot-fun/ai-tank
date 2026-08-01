## 砖墙破碎特效
##
## 【原理】
## 单张 Sprite2D 无法在着色器里让各块砖独立旋转、飞出，因此采用「贴图切片 + 多精灵」：
## 1. 用 AtlasTexture 把整张贴图按网格裁成多块小图；
## 2. 每块对应一个 Sprite2D，初始位置拼成完整墙体；
## 3. Tween 驱动位移 / 旋转 / 透明度，模拟碎块飞散；
## 4. 动画结束后销毁本节点（子碎块一并释放）。
##
## 【坐标系】
## 本节点挂在场景父节点下，global_position = 原砖墙中心。
## 碎块 position 以砖墙中心为原点，范围约 ±TILE_SIZE/2，与 Tile 的 global_position 一致。
##
## 【缩放】
## 原砖墙：512×512 贴图 + Tile.scale = TILE_SIZE/512 → 屏幕 60×60。
## 碎块 Atlas 区域为 chunk_w×chunk_h，再乘相同 tile_scale → 单块屏幕宽 = 60/CHUNK_COLS。
class_name BrickBreakEffect
extends Node2D

# 切片列数 / 行数（4×3 = 12 块，接近砖墙铺贴感）
const CHUNK_COLS := 4
const CHUNK_ROWS := 3
# 碎块飞散 + 淡出总时长（秒）
const BREAK_DURATION := 0.28
# 沿爆开方向的位移（像素，本地坐标）
const FLY_DISTANCE := 36.0
# 竖直下落偏移，模拟重力（像素）
const GRAVITY_DROP := 14.0


## 在 [param world_center] 生成破碎动画，由 [param parent] 托管生命周期。
## [param tile_scale] 须与原砖墙 Tile.scale 一致，保证碎块尺寸正确。
static func spawn(world_center: Vector2, tile_scale: Vector2, texture: Texture2D, parent: Node) -> void:
	if texture == null or parent == null:
		return

	var effect := BrickBreakEffect.new()
	effect.name = "BrickBreakEffect"
	effect.global_position = world_center
	parent.add_child(effect)
	effect._play(tile_scale, texture)
	pass


func _play(tile_scale: Vector2, texture: Texture2D) -> void:
	var tex_size := texture.get_size()
	# 贴图像素尺寸整除网格数，得到每块在图集上的宽高
	var chunk_w := int(tex_size.x / CHUNK_COLS)
	var chunk_h := int(tex_size.y / CHUNK_ROWS)
	var tile_pixel_size := Vector2(TileConfig.TILE_SIZE, TileConfig.TILE_SIZE)

	for row in CHUNK_ROWS:
		for col in CHUNK_COLS:
			_spawn_chunk(col, row, chunk_w, chunk_h, tile_scale, tile_pixel_size, texture)

	# 等飞散动画结束后再销毁（略长于 BREAK_DURATION，避免末帧被截断）
	var timer := get_tree().create_timer(BREAK_DURATION + 0.08)
	timer.timeout.connect(queue_free)
	pass


func _spawn_chunk(
	col: int,
	row: int,
	chunk_w: int,
	chunk_h: int,
	tile_scale: Vector2,
	tile_pixel_size: Vector2,
	texture: Texture2D,
) -> void:
	# AtlasTexture：从大图中裁出 (col, row) 格，不复制像素数据
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(col * chunk_w, row * chunk_h, chunk_w, chunk_h)
	atlas.filter_clip = true  # 裁切边缘不采样邻格，避免接缝脏边

	var piece := Sprite2D.new()
	piece.name = StringUtils.format("Chunk_{}_{}", col, row)
	piece.texture = atlas
	piece.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST  # 像素风，禁止模糊

	# 块中心相对墙体中心的归一化偏移 [-0.5, 0.5]，再换成世界像素偏移
	var local_frac := Vector2(
		(col + 0.5) / float(CHUNK_COLS) - 0.5,
		(row + 0.5) / float(CHUNK_ROWS) - 0.5,
	)
	piece.position = local_frac * tile_pixel_size
	piece.scale = tile_scale
	add_child(piece)

	# 爆开方向：从墙体中心指向该块中心；中心块无方向则随机
	var burst_dir := local_frac
	if burst_dir.length_squared() < 0.01:
		burst_dir = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
	# 叠加随机扰动，避免 12 块轨迹完全对称
	burst_dir = (burst_dir.normalized() + Vector2(randf_range(-0.22, 0.22), randf_range(-0.22, 0.22))).normalized()

	var target_pos := piece.position + burst_dir * FLY_DISTANCE + Vector2(0.0, GRAVITY_DROP)
	var spin := randf_range(-0.55, 0.55)

	# 初帧略放大 + 偏亮，模拟撞击闪白
	piece.modulate = Color(1.25, 1.15, 1.05, 1.0)
	piece.scale *= 1.08

	var tween := create_tween().set_parallel(true)
	# 向外飞出（先快后慢）
	tween.tween_property(piece, "position", target_pos, BREAK_DURATION) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# 碎块自旋
	tween.tween_property(piece, "rotation", spin, BREAK_DURATION) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# 撞击放大迅速回弹到正常 scale
	tween.tween_property(piece, "scale", tile_scale, BREAK_DURATION * 0.35) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# 稍后淡出消失
	tween.tween_property(piece, "modulate", Color(1.0, 1.0, 1.0, 0.0), BREAK_DURATION) \
		.set_delay(0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	pass
