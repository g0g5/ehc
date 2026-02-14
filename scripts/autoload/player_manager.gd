# 玩家管理器
# 全局单例，负责管理玩家实体、伤害处理和重生逻辑
extends Node

# 信号定义
signal player_spawned(player: CharacterBody2D)
signal player_died

# 玩家实例引用
var player_instance: CharacterBody2D = null
var spawn_point: Vector2 = Vector2.ZERO

# 获取当前玩家实例
func get_player() -> CharacterBody2D:
	return player_instance

# 获取玩家状态
func get_player_state() -> Node:
	if player_instance and player_instance.has_node('state'):
		return player_instance.get_node('state')
	return null

# 注册玩家实例（由玩家节点在 _ready 中调用）
func register_player(player: CharacterBody2D) -> void:
	player_instance = player
	player_spawned.emit(player)
	print("[PlayerManager] 玩家已注册")

# 注销玩家实例
func unregister_player() -> void:
	if player_instance:
		player_instance = null
		print("[PlayerManager] 玩家已注销")

# 设置重生点
func set_spawn_point(pos: Vector2) -> void:
	spawn_point = pos

# 统一伤害处理接口
# damage_data: {
#   "cloth_damage": int,           # 衣服损伤（默认0）
#   "stamina_damage": int,         # 体力损伤（默认0）
#   "knockback_force": float,      # 基础击飞力度（默认0）
#   "knockback_direction": Vector2 # 击飞方向（可选，默认根据玩家朝向计算）
# }
func apply_damage(damage_data: Dictionary) -> void:
	if not player_instance:
		print("[PlayerManager] 错误：没有注册的玩家实例")
		return

	var player_state = get_player_state()
	if not player_state or not player_state.has_method('take_damage'):
		print("[PlayerManager] 错误：玩家状态节点不可用")
		return

	# 提取伤害参数
	var cloth_damage = damage_data.get("cloth_damage", 0)
	var stamina_damage = damage_data.get("stamina_damage", 0)
	var knockback_force = damage_data.get("knockback_force", 0.0)
	var knockback_direction: Vector2 = damage_data.get("knockback_direction", Vector2.ZERO)

	# 调用状态机处理伤害，获取最终击飞力度
	var final_knockback = player_state.take_damage(cloth_damage, stamina_damage, knockback_force)

	# 应用击飞效果（如果有）
	if final_knockback > 0 and player_instance.has_method('apply_knockback'):
		# 如果没有指定方向，使用默认方向（向左上方）
		if knockback_direction == Vector2.ZERO:
			knockback_direction = Vector2(-1.0, -0.4)
		player_instance.apply_knockback(final_knockback, knockback_direction)

	print("[PlayerManager] 伤害已处理: cloth=%d, stamina=%d, knockback=%.1f" %
		  [cloth_damage, stamina_damage, final_knockback])

# 应用异常状态
# status_type: "sticky" | "weak"
func apply_status(status_type: String) -> void:
	var player_state = get_player_state()
	if not player_state:
		return

	match status_type:
		"sticky":
			if player_state.has_method('apply_sticky_effect'):
				player_state.apply_sticky_effect()
		"weak":
			# 虚弱状态通常在 take_damage 中自动应用
			pass

# 重生玩家
func respawn_player() -> void:
	if not player_instance:
		return

	# 重置玩家状态
	var player_state = get_player_state()
	if player_state and player_state.has_method('reset_states'):
		player_state.reset_states()

	# 重置玩家位置
	player_instance.global_position = spawn_point
	player_instance.velocity = Vector2.ZERO

	# 重置游戏结束状态（如果有）
	if player_instance.has_method('set_game_over'):
		player_instance.set_game_over(false)
	elif 'game_over' in player_instance:
		player_instance.game_over = false

	print("[PlayerManager] 玩家已重生到: ", spawn_point)
