extends Tile
class_name Ice

func _ready() -> void:
	z_index = -5
	apply_data(TileConfig.ice)
	pass


func blocks_tank() -> bool:
	return false


func blocks_bullet() -> bool:
	return false


func is_ice() -> bool:
	return true


func take_damage(_amount: int) -> void:
	pass
