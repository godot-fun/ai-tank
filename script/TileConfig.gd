class_name TileConfig

const BULLET_HIT_BRICK_SOUNDS: Array[String] = [
	"res://audio/sfx/bullet-hit-brick/01.wav",
	"res://audio/sfx/bullet-hit-brick/02.wav",
	"res://audio/sfx/bullet-hit-brick/03.wav",
	"res://audio/sfx/bullet-hit-brick/04.wav",
	"res://audio/sfx/bullet-hit-brick/05.wav",
]

const BULLET_HIT_STEEL_SOUNDS: Array[String] = [
	"res://audio/sfx/bullet-hit-steel/01.wav",
	"res://audio/sfx/bullet-hit-steel/02.wav",
	"res://audio/sfx/bullet-hit-steel/03.wav",
	"res://audio/sfx/bullet-hit-steel/04.wav",
	"res://audio/sfx/bullet-hit-steel/05.wav",
]

class TileCell:
	var id: int
	var max_hp: int
	var tile_resource: String
	var script_resource: String
	var bullet_hit_sound_resources: Array[String]

	func _init(
		_id: int,
		_max_hp: int,
		_tile_resource: String,
		_script_resource: String,
		_bullet_hit_sound_resources: Array[String] = [],
	):
		id = _id
		max_hp = _max_hp
		tile_resource = _tile_resource
		script_resource = _script_resource
		bullet_hit_sound_resources = _bullet_hit_sound_resources

static var brick_wall: TileCell = TileCell.new(
	0,
	1,
	"res://image/tiles/brick_wall_1.png",
	"res://script/tile/BrickWall.gd",
	BULLET_HIT_BRICK_SOUNDS,
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
	BULLET_HIT_STEEL_SOUNDS,
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
