# 粘液池脚本
# 处理玩家进入粘液区域的效果
extends Area2D


# 当物体进入粘液池时触发
func _on_body_entered(body: Node2D) -> void:
	# 检查是否是玩家
	if body.is_in_group('Player'):
		print("玩家进入粘液池！")

		# 使用 PlayerManager 统一处理伤害（仅击飞，无伤害）
		PlayerManager.apply_damage({
			"cloth_damage": 0,
			"stamina_damage": 0,
			"knockback_force": 800.0,
			"knockback_direction": Vector2(-1.0, -0.4)
		})

		# 应用粘液特殊效果
		PlayerManager.apply_status("sticky")
