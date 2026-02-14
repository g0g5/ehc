extends Control

func _ready() -> void:
	# 确保游戏状态为标题
	if GameManager.get_current_state() != GameManager.GameState.TITLE:
		GameManager.return_to_title()

func _on_quit_pressed() -> void:
	print('[Title] 退出游戏')
	get_tree().quit()

func _on_start_pressed() -> void:
	print('[Title] 开始游戏')
	GameManager.start_game()
