extends CanvasLayer
class_name BattleHud

@onready var enemy_label: Label = $MarginContainer/VBox/EnemyLabel
@onready var timer_label: Label = $MarginContainer/VBox/TimerLabel


func update_enemies_remaining(count: int) -> void:
	enemy_label.text = "剩余敌人: %d" % count
	pass


func update_timer(seconds: float) -> void:
	var sec := maxi(ceili(seconds), 0)
	timer_label.text = "%02d:%02d" % [sec / 60, sec % 60]
	pass
