extends Tile
class_name Eagle

const TEXTURE_DESTROYED := "res://image/characters/eagle_base_6.png"

signal destroyed

@warning_ignore("integer_division")
static var egale_first_grid_pos := Vector2i((TankConfig.map_grid_width - 2) / 2, TankConfig.map_grid_height - 2)


static func create_base() -> void:
	for x in range(2):
		for y in range(2):
			TileHelper.create_tile(TileConfig.eagle, egale_first_grid_pos + Vector2i(x, y))


func _ready() -> void:
	apply_data(TileConfig.eagle)
	pass


func destroy() -> void:
	sprite.texture = load(TEXTURE_DESTROYED)
	destroyed.emit()
	pass
