# 关卡管理器
# 全局单例，负责管理当前关卡内的敌人、存档点和关卡完成逻辑
extends Node

# 信号定义
signal level_completed
signal checkpoint_reached(position: Vector2)
signal enemy_registered(enemy: Node)
signal enemy_unregistered(enemy: Node)

# 关卡内对象列表
var enemies: Array[Node] = []
var collectibles: Array[Node] = []

# 当前存档点位置
var current_checkpoint: Vector2 = Vector2.ZERO

# 是否已通关
var is_level_complete: bool = false


func _ready() -> void:
	print("[LevelManager] 关卡管理器已初始化")


# 注册敌人
func register_enemy(enemy: Node) -> void:
	if enemy not in enemies:
		enemies.append(enemy)
		enemy_registered.emit(enemy)


# 注销敌人
func unregister_enemy(enemy: Node) -> void:
	if enemy in enemies:
		enemies.erase(enemy)
		enemy_unregistered.emit(enemy)


# 获取所有敌人
func get_all_enemies() -> Array[Node]:
	return enemies.duplicate()


# 获取存活的敌人数量
func get_alive_enemy_count() -> int:
	return enemies.size()


# 设置存档点
func set_checkpoint(pos: Vector2) -> void:
	current_checkpoint = pos
	checkpoint_reached.emit(pos)
	print("[LevelManager] 存档点已设置: ", pos)


# 获取当前存档点
func get_checkpoint() -> Vector2:
	return current_checkpoint


# 完成关卡
func complete_level() -> void:
	if is_level_complete:
		return
	is_level_complete = true
	level_completed.emit()
	print("[LevelManager] 关卡完成")


# 重置关卡状态（切换关卡时调用）
func reset_level_state() -> void:
	enemies.clear()
	collectibles.clear()
	current_checkpoint = Vector2.ZERO
	is_level_complete = false
	print("[LevelManager] 关卡状态已重置")


# 注册可收集物
func register_collectible(item: Node) -> void:
	if item not in collectibles:
		collectibles.append(item)


# 注销可收集物
func unregister_collectible(item: Node) -> void:
	if item in collectibles:
		collectibles.erase(item)


# 获取剩余可收集物数量
func get_remaining_collectibles() -> int:
	return collectibles.size()
