extends Tile
class_name Water

func _ready() -> void:
	apply_data(TileConfig.water)
	pass


func blocks_tank() -> bool:
	return true


func take_damage(_amount: int) -> void:
	pass
