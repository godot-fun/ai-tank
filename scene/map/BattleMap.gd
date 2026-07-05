extends Node2D

@onready var battle_hud: BattleHud = $BattleHud


func _ready() -> void:
	LevelConfig.load_level(BattleProgress.level)
	Eagle.create_base()
	battle_hud.update_enemies_remaining(BattleProgress.get_enemy_count())
	battle_hud.update_timer(BattleProgress.get_time_limit())
	
	if Audio.musics.is_empty():
		Audio.play_musics([BgmConfig.BGM_STAGE_1, BgmConfig.BGM_STAGE_2, BgmConfig.BGM_STAGE_3, BgmConfig.BGM_STAGE_4, 
			BgmConfig.BGM_STAGE_5, BgmConfig.BGM_STAGE_6])
	else:
		Audio.resume_musics()
	pass
