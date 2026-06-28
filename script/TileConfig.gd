class_name TileConfig

class TileCell:
	var id: int
	var max_hp: int
	var tile_resource: String
	var script_resource: String
	var bullet_hit_sound_resource: String

	func _init(
		_id: int,
		_max_hp: int,
		_tile_resource: String,
		_script_resource: String,
		_bullet_hit_sound_resource: String = "",
	):
		id = _id
		max_hp = _max_hp
		tile_resource = _tile_resource
		script_resource = _script_resource
		bullet_hit_sound_resource = _bullet_hit_sound_resource

static var brick_wall: TileCell = TileCell.new(
	0,
	1,
	"res://image/tiles/brick_wall_1.png",
	"res://script/tile/BrickWall.gd",
	"res://audio/sfx/bullet-hit-brick/01.wav",
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
	"res://audio/sfx/bullet-hit-steel/01.wav",
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
