extends Tile
class_name Ice

func start() -> void:
	z_index = -5
	pass


func blocks_tank() -> bool:
	return false


func blocks_bullet() -> bool:
	return false


func is_ice() -> bool:
	return true


func take_damage(_amount: int) -> void:
	pass
