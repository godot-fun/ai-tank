extends Tile
class_name Ice

const SHIMMER_SHADER := "res://shader/ice_shimmer.gdshader"

static var shimmer_material: ShaderMaterial


func start() -> void:
	z_index = -5
	setup_shimmer_material()
	pass


func setup_shimmer_material() -> void:
	if shimmer_material == null:
		shimmer_material = ShaderMaterial.new()
		shimmer_material.shader = load(SHIMMER_SHADER)
	sprite.material = shimmer_material
	pass


func blocks_tank() -> bool:
	return false


func blocks_bullet() -> bool:
	return false

func take_damage(_amount: int) -> void:
	pass
