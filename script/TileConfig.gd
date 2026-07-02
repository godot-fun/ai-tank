class_name TileConfig

const TILE_SIZE: int = 60

const ONE_GRID_SIZE: Vector2i = Vector2.ONE * TILE_SIZE

# 地图的格子的长宽
static var MAP_GRID_WIDTH: int = ProjectSettings.get_setting("display/window/size/viewport_width") / TILE_SIZE
static var MAP_GRID_HEIGHT: int = ProjectSettings.get_setting("display/window/size/viewport_height") / TILE_SIZE


class TileCell:
	var id: int
	var hp: int
	var tile_resource: String
	var script_resource: String

	func _init(
		_id: int,
		_hp: int,
		_tile_resource: String,
		_script_resource: String,
	):
		id = _id
		hp = _hp
		tile_resource = _tile_resource
		script_resource = _script_resource

static var brick_wall: TileCell = TileCell.new(
	0,
	1,
	"res://image/tiles/brick_wall_1.png",
	"res://script/tile/BrickWall.gd",
)

static var water: TileCell = TileCell.new(
	1,
	0,
	"res://image/tiles/water_4.png",
	"res://script/tile/Water.gd",
)

static var steel_wall: TileCell = TileCell.new(
	2,
	0,
	"res://image/tiles/steel_wall_3.png",
	"res://script/tile/SteelWall.gd",
)

static var forest: TileCell = TileCell.new(
	3,
	0,
	"res://image/tiles/forest_3.png",
	"res://script/tile/Forest.gd",
)

static var ice: TileCell = TileCell.new(
	4,
	0,
	"res://image/tiles/ice_3.png",
	"res://script/tile/Ice.gd",
)

static var eagle: TileCell = TileCell.new(
	5,
	1,
	"res://image/transparent_512x512.png",
	"res://script/tile/Eagle.gd",
)
