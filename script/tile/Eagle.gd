## 玩家基地（老鹰）
##
## 【视觉】eagle_shield 着色器：鹰徽周围 cyan/金色同心能量环，约 2.5s 一圈。
## 【逻辑】2×2 碰撞格 + 独立 egale_sprite；destroy() 切毁损贴图并关闭护盾环。
extends Tile
class_name Eagle

const TEXTURE := "res://image/characters/eagle_base_1.png"
const TEXTURE_DESTROYED := "res://image/characters/eagle_base_6.png"
const SHIELD_SHADER := "res://shader/eagle_shield.gdshader"

@warning_ignore("integer_division")
static var egale_first_grid_pos := Vector2i((TileConfig.MAP_GRID_WIDTH - 2) / 2, TileConfig.MAP_GRID_HEIGHT - 2)
static var player_tank_start_grid_pos := egale_first_grid_pos + Vector2i.LEFT * 3
static var partner_tank_start_grid_pos := egale_first_grid_pos + Vector2i.RIGHT * 3

static var egale_sprite: Sprite2D
static var shield_material: ShaderMaterial


static func create_base() -> void:
	create_eagle()
	create_base_bricks()
	pass


static func create_eagle() -> void:
	egale_sprite = Sprite2D.new()
	egale_sprite.centered = true
	egale_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	egale_sprite.texture = load(TEXTURE)
	egale_sprite.z_index = 1
	egale_sprite.position = TileConfig.grid_to_world(egale_first_grid_pos, Vector2i.ONE) + TileConfig.ONE_GRID_SIZE * 0.5

	var texture_size := egale_sprite.texture.get_size()
	var target_size := Vector2(Vector2i.ONE * 2) * TileConfig.TILE_SIZE
	egale_sprite.scale = target_size / texture_size

	var parent: Node = (Engine.get_main_loop() as SceneTree).current_scene
	parent.add_child(egale_sprite)
	setup_shield_material()

	for x in range(2):
		for y in range(2):
			TileHelper.create_tile(TileConfig.eagle, egale_first_grid_pos + Vector2i(x, y))
	pass


static func setup_shield_material() -> void:
	if shield_material == null:
		shield_material = ShaderMaterial.new()
		shield_material.shader = load(SHIELD_SHADER)
	egale_sprite.material = shield_material
	shield_material.set_shader_parameter("shield_active", 1.0)
	pass


static func base_wall_grids() -> Array[Vector2i]:
	var pos := egale_first_grid_pos
	var grids: Array[Vector2i] = []
	for x in range(-1, 3):
		grids.append(pos + Vector2i(x, -1))
	for y in range(2):
		grids.append(pos + Vector2i(-1, y))
		grids.append(pos + Vector2i(2, y))
	return grids


static func create_base_bricks() -> void:
	for grid in base_wall_grids():
		TileHelper.create_tile(TileConfig.brick_wall_eagle, grid)
	pass


func destroy() -> void:
	egale_sprite.texture = load(TEXTURE_DESTROYED)
	if shield_material != null:
		shield_material.set_shader_parameter("shield_active", 0.0)
	EventBus.events.eagle_death.emit()
	pass
