extends Tile
class_name SteelWall

func _ready() -> void:
	apply_data(TileConfig.steel_wall)
	pass


func take_damage(_amount: int) -> void:
	pass
