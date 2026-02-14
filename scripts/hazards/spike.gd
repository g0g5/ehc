# 尖刺陷阱脚本
# 处理玩家触碰尖刺时的伤害和击飞逻辑
extends Area2D

# 当物体进入碰撞区域时触发
func _on_body_entered(body: Node2D) -> void:
    print(body)
    # 检查是否是玩家
    if body.is_in_group('Player'):
        print("玩家被尖刺击中！")

        # 使用 PlayerManager 统一处理伤害
        PlayerManager.apply_damage({
            "cloth_damage": 1,
            "stamina_damage": 20,
            "knockback_force": 1500.0,
            "knockback_direction": Vector2(-1.0, -0.4)  # 向左上方击飞
        })