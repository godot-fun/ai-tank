extends Tile
class_name SteelWall

const METAL_SHADER := "res://shader/steel_metal.gdshader"

static var metal_material: ShaderMaterial


func start() -> void:
	setup_metal_material()
	pass


func setup_metal_material() -> void:
	if metal_material == null:
		metal_material = ShaderMaterial.new()
		metal_material.shader = load(METAL_SHADER)
	sprite.material = metal_material
	pass


func take_damage(_amount: int) -> void:
	pass
