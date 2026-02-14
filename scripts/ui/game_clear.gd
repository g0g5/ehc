extends Area2D



func _on_body_entered(body: CharacterBody2D):
	if body.is_in_group("Player"):
		print("[GameClear] 玩家到达通关区域")
		GameManager.level_complete()
		GameManager.return_to_title()