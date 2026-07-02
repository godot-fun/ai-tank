extends Node2D

const LEVEL_COUNT := 35
const INTERVAL_SEC := 2.0


func _ready() -> void:
	for level_index in range(LEVEL_COUNT):
		LevelConfig.load_level(level_index)
		if level_index < LEVEL_COUNT - 1:
			await get_tree().create_timer(INTERVAL_SEC).timeout
