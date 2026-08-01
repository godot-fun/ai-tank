## 坦克击毁碎散特效
##
## 【原理】同 BrickBreakEffect：AtlasTexture 切片 → 多 Sprite2D → Tween 飞散。
## 与砖墙差异：
## - 占地 grid_size×TILE_SIZE（通常 2×2 = 120px），飞散距离按体型缩放；
## - 继承击毁前炮塔朝向：碎块 position / burst 按 sprite_rotation 旋转，重力仍沿屏幕向下。
##
## 【缩放】
## 原坦克：贴图 × Sprite2D.scale → 屏幕 grid_size×TILE_SIZE（根节点 scale 保持 1）。
## 碎块 region 为贴图 1/CHUNK 宽，再乘 tank_scale，单块宽 = 坦克宽 / CHUNK_COLS。
class_name TankBreakEffect
extends Node2D

const CHUNK_COLS := 4
const CHUNK_ROWS := 4
const BREAK_DURATION := 0.32
# 以 1 格（60px）坦克为基准的飞散距离，实际 × 体型系数
const FLY_DISTANCE_BASE := 44.0
const GRAVITY_DROP_BASE := 18.0


static func spawn(
	world_center: Vector2,
	tank_scale: Vector2,
	grid_size: Vector2i,
	sprite_rotation: float,
	texture: Texture2D,
	parent: Node,
) -> void:
	if texture == null or parent == null:
		return

	var effect := TankBreakEffect.new()
	effect.name = "TankBreakEffect"
	effect.global_position = world_center
	parent.add_child(effect)
	effect.play(tank_scale, grid_size, texture, sprite_rotation)
	pass


func play(tank_scale: Vector2, grid_size: Vector2i, texture: Texture2D, sprite_rotation: float) -> void:
	var tex_size := texture.get_size()
	var chunk_w := int(tex_size.x / CHUNK_COLS)
	var chunk_h := int(tex_size.y / CHUNK_ROWS)
	var tank_pixel_size := Vector2(grid_size) * TileConfig.TILE_SIZE
	var size_factor := tank_pixel_size.x / float(TileConfig.TILE_SIZE)
	var fly_distance := FLY_DISTANCE_BASE * size_factor
	var gravity_drop := GRAVITY_DROP_BASE * size_factor

	for row in CHUNK_ROWS:
		for col in CHUNK_COLS:
			spawn_chunk(
				col, row, chunk_w, chunk_h,
				tank_scale, tank_pixel_size, texture,
				sprite_rotation, fly_distance, gravity_drop,
			)

	var timer := get_tree().create_timer(BREAK_DURATION + 0.08)
	timer.timeout.connect(queue_free)
	pass


func spawn_chunk(
	col: int,
	row: int,
	chunk_w: int,
	chunk_h: int,
	tank_scale: Vector2,
	tank_pixel_size: Vector2,
	texture: Texture2D,
	sprite_rotation: float,
	fly_distance: float,
	gravity_drop: float,
) -> void:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(col * chunk_w, row * chunk_h, chunk_w, chunk_h)
	atlas.filter_clip = true

	var piece := Sprite2D.new()
	piece.name = StringUtils.format("Chunk_{}_{}", col, row)
	piece.texture = atlas
	piece.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	var local_frac := Vector2(
		(col + 0.5) / float(CHUNK_COLS) - 0.5,
		(row + 0.5) / float(CHUNK_ROWS) - 0.5,
	)
	piece.position = (local_frac * tank_pixel_size).rotated(sprite_rotation)
	piece.rotation = sprite_rotation
	piece.scale = tank_scale
	add_child(piece)

	var burst_dir := local_frac
	if burst_dir.length_squared() < 0.01:
		burst_dir = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
	burst_dir = (burst_dir.normalized() + Vector2(randf_range(-0.25, 0.25), randf_range(-0.25, 0.25))).normalized()
	burst_dir = burst_dir.rotated(sprite_rotation)

	var target_pos := piece.position + burst_dir * fly_distance + Vector2(0.0, gravity_drop)
	var spin := randf_range(-0.65, 0.65)

	piece.modulate = Color(1.3, 1.1, 0.95, 1.0)
	piece.scale *= 1.1

	var tween := create_tween().set_parallel(true)
	tween.tween_property(piece, "position", target_pos, BREAK_DURATION) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(piece, "rotation", sprite_rotation + spin, BREAK_DURATION) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(piece, "scale", tank_scale, BREAK_DURATION * 0.35) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(piece, "modulate", Color(1.0, 1.0, 1.0, 0.0), BREAK_DURATION) \
		.set_delay(0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	pass
