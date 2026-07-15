class_name GameManager


static func init() -> void:
	RespawnManager.init()
	BuffManager.init()
	TankConfig.init_datas()
	TankConfig.refresh_datas()
	BattleProgress.init()
	pass
