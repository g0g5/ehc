extends CharacterBody2D

var direction : Vector2 = Vector2.ZERO
var speed : float

func _physics_process(delta: float) -> void:
	position += direction * speed * delta



func _on_hitbox_body_entered(body: Node2D) -> void:
	print(body)
	# 检查是否是玩家
	if body.is_in_group('Player'):
		print("玩家被子弹击中！")

		# 使用 PlayerManager 统一处理伤害
		PlayerManager.apply_damage({
			"cloth_damage": 0,
			"stamina_damage": 0,
			"knockback_force": 800.0,
			"knockback_direction": Vector2(-1.0, -0.4)
		})

		# 销毁子弹
		queue_free()
	elif body.is_class('TileMapLayer'):
		print('发现碰撞', body)
		queue_free()
