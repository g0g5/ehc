# 游戏管理器
# 全局单例，负责管理游戏流程、关卡切换和游戏状态
extends Node

# 游戏状态枚举
enum GameState { TITLE, PLAYING, PAUSED, GAME_OVER, VICTORY }

# 当前游戏状态
var current_state: GameState = GameState.TITLE

# 当前关卡信息
var current_level_id: String = ""
var current_level: int = 1

# 关卡场景路径映射
var level_scenes: Dictionary = {
	"test_level": "res://scenes/Levels/testlevel_playermovement.tscn"
}

# 标题场景路径
const TITLE_SCENE = "res://scenes/title.tscn"

# 信号定义
signal state_changed(new_state: GameState, old_state: GameState)
signal level_loaded(level_id: String)
signal level_restarted(level_id: String)


func _ready() -> void:
	print("[GameManager] 游戏管理器已初始化")


# 获取当前游戏状态
func get_current_state() -> GameState:
	return current_state


# 获取当前关卡ID
func get_current_level() -> String:
	return current_level_id


# 切换状态内部函数
func _change_state(new_state: GameState) -> void:
	var old_state = current_state
	current_state = new_state
	state_changed.emit(new_state, old_state)
	print("[GameManager] 游戏状态切换: %d -> %d" % [old_state, new_state])


# 开始游戏（从标题界面进入第一关）
func start_game() -> void:
	print("[GameManager] 开始游戏")
	_load_level_by_id("test_level")


# 暂停游戏
func pause_game() -> void:
	if current_state == GameState.PLAYING:
		_change_state(GameState.PAUSED)
		get_tree().paused = true


# 恢复游戏
func resume_game() -> void:
	if current_state == GameState.PAUSED:
		_change_state(GameState.PLAYING)
		get_tree().paused = false


# 游戏结束
func game_over() -> void:
	print("[GameManager] 游戏结束")
	_change_state(GameState.GAME_OVER)
	# 游戏结束处理由 PlayerManager 和 UIManager 协调


# 关卡胜利/完成
func level_complete() -> void:
	print("[GameManager] 关卡完成")
	_change_state(GameState.VICTORY)


# 返回标题界面
func return_to_title() -> void:
	print("[GameManager] 返回标题界面")
	_change_state(GameState.TITLE)
	current_level_id = ""
	get_tree().paused = false
	_safe_change_scene(TITLE_SCENE)


# 加载指定关卡
func load_level(level_id: String) -> void:
	_load_level_by_id(level_id)


# 重载当前关卡
func reload_current_level() -> void:
	if current_level_id.is_empty():
		print("[GameManager] 错误：没有当前关卡可以重载")
		return
	print("[GameManager] 重载关卡: %s" % current_level_id)
	level_restarted.emit(current_level_id)
	_load_level_by_id(current_level_id)


# 注册关卡场景路径
func register_level(level_id: String, scene_path: String) -> void:
	level_scenes[level_id] = scene_path
	print("[GameManager] 注册关卡: %s -> %s" % [level_id, scene_path])


# 内部关卡加载逻辑
func _load_level_by_id(level_id: String) -> void:
	if not level_scenes.has(level_id):
		print("[GameManager] 错误：未找到关卡 '%s'" % level_id)
		return

	var scene_path = level_scenes[level_id]
	current_level_id = level_id
	_change_state(GameState.PLAYING)
	get_tree().paused = false

	print("[GameManager] 加载关卡: %s" % level_id)
	level_loaded.emit(level_id)
	_safe_change_scene(scene_path)


# 安全切换场景（处理可能的错误）
func _safe_change_scene(scene_path: String) -> void:
	var result = get_tree().change_scene_to_file(scene_path)
	if result != OK:
		print("[GameManager] 场景切换失败: %s" % scene_path)


# 检查是否处于游戏进行中状态
func is_playing() -> bool:
	return current_state == GameState.PLAYING


# 检查是否暂停
func is_paused() -> bool:
	return current_state == GameState.PAUSED


# 检查是否游戏结束
func is_game_over() -> bool:
	return current_state == GameState.GAME_OVER
