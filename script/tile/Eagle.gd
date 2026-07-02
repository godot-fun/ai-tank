extends Tile
class_name Eagle

const TEXTURE := "res://image/characters/eagle_base_1.png"
const TEXTURE_DESTROYED := "res://image/characters/eagle_base_6.png"

@warning_ignore("integer_division")
static var egale_first_grid_pos := Vector2i((TileConfig.MAP_GRID_WIDTH - 2) / 2, TileConfig.MAP_GRID_HEIGHT - 2)

static var egale_sprite: Sprite2D

static func create_base() -> void:
	create_eagle()
	create_base_bricks()

static func create_eagle() -> void:
	egale_sprite = Sprite2D.new()
	egale_sprite.texture = load(TEXTURE)
	egale_sprite.position = TankConfig.grid_to_world(egale_first_grid_pos, Vector2i.ONE) + TileConfig.ONE_GRID_SIZE * 0.5
	
	var texture_size := egale_sprite.texture.get_size()
	var target_size := Vector2(Vector2i.ONE * 2) * TileConfig.TILE_SIZE
	egale_sprite.scale = target_size / texture_size

	var parent: Node = (Engine.get_main_loop() as SceneTree).current_scene
	parent.add_child(egale_sprite)
	
	for x in range(2):
		for y in range(2):
			TileHelper.create_tile(TileConfig.eagle, egale_first_grid_pos + Vector2i(x, y))	
	pass

static func create_base_bricks() -> void:
	var pos := egale_first_grid_pos
	for x in range(-1, 3):
		TileHelper.create_tile(TileConfig.brick_wall_eagle, pos + Vector2i(x, -1))
	for y in range(2):
		TileHelper.create_tile(TileConfig.brick_wall_eagle, pos + Vector2i(-1, y))
		TileHelper.create_tile(TileConfig.brick_wall_eagle, pos + Vector2i(2, y))
	pass


func destroy() -> void:
	egale_sprite.texture = load(TEXTURE_DESTROYED)
	pass
