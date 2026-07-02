extends Tile
class_name Water

func blocks_tank() -> bool:
	return true


func blocks_bullet() -> bool:
	return false


func take_damage(_amount: int) -> void:
	pass
