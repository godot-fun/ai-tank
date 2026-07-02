extends Tile
class_name Forest

func start() -> void:
	z_index = 1
	pass


func blocks_tank() -> bool:
	return false


func blocks_bullet() -> bool:
	return false


func take_damage(_amount: int) -> void:
	pass
