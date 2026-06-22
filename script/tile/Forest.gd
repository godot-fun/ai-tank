extends Tile
class_name Forest

func _ready() -> void:
	apply_data(TileConfig.forest)
	z_index = 1
	pass


func blocks_tank() -> bool:
	return false


func blocks_bullet() -> bool:
	return false


func take_damage(_amount: int) -> void:
	pass
