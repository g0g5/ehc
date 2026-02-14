# UI 管理器
# 全局单例，负责管理所有 UI 面板的显示/隐藏和数据同步
extends Node

# UI 层级枚举
enum UILayer { BACKGROUND, GAME, HUD, POPUP, OVERLAY, TOP }

# 信号定义
signal panel_opened(panel_name: String)
signal panel_closed(panel_name: String)
signal hud_updated(data_type: String, value: Variant)

# 已打开的面板字典
var open_panels: Dictionary = {}

# UI 导航栈
var ui_stack: Array[String] = []

# 当前显示的 HUD 数据
var hud_data: Dictionary = {}


func _ready() -> void:
	print("[UIManager] UI 管理器已初始化")
	# 连接玩家状态变化信号
	_connect_player_signals()


# 连接玩家信号
func _connect_player_signals() -> void:
	# 等待 PlayerManager 准备好
	await get_tree().process_frame
	var player_state = PlayerManager.get_player_state()
	if player_state:
		player_state.cloth_broked.connect(_on_cloth_changed)
		player_state.stamina_changed.connect(_on_stamina_changed)
		player_state.became_weak.connect(_on_status_changed)
		player_state.became_sticky.connect(_on_status_changed)


# 打开面板
func open_panel(panel_name: String, params: Dictionary = {}) -> void:
	open_panels[panel_name] = params
	panel_opened.emit(panel_name)
	print("[UIManager] 打开面板: ", panel_name)


# 关闭面板
func close_panel(panel_name: String) -> void:
	if open_panels.has(panel_name):
		open_panels.erase(panel_name)
		panel_closed.emit(panel_name)
		print("[UIManager] 关闭面板: ", panel_name)


# 关闭所有面板
func close_all_panels() -> void:
	var panels = open_panels.keys()
	for panel_name in panels:
		close_panel(panel_name)


# 检查面板是否打开
func is_panel_open(panel_name: String) -> bool:
	return open_panels.has(panel_name)


# 推入 UI 状态（用于导航）
func push_ui_state(panel_name: String) -> void:
	ui_stack.append(panel_name)


# 弹出 UI 状态
func pop_ui_state() -> String:
	if ui_stack.is_empty():
		return ""
	return ui_stack.pop_back()


# 更新 HUD
func update_hud(data_type: String, value: Variant) -> void:
	hud_data[data_type] = value
	hud_updated.emit(data_type, value)


# 刷新 UI
func refresh_ui() -> void:
	print("[UIManager] 刷新 UI")
	# 触发所有 HUD 更新信号
	for key in hud_data:
		hud_updated.emit(key, hud_data[key])


# 显示消息提示
func show_message(text: String, duration: float = 2.0) -> void:
	print("[UIManager] 消息: ", text)
	# 实际项目中这里会实例化一个消息提示控件


# 显示确认对话框
func show_confirm(title: String, message: String, callback: Callable) -> void:
	print("[UIManager] 确认对话框: ", title, " - ", message)
	# 实际项目中这里会实例化一个确认对话框


# 显示加载界面
func show_loading(text: String = "Loading...") -> void:
	print("[UIManager] 加载中: ", text)
	# 实际项目中这里会显示加载遮罩


# 隐藏加载界面
func hide_loading() -> void:
	print("[UIManager] 加载完成")
	# 实际项目中这里会隐藏加载遮罩


# ===== 信号回调 =====

func _on_cloth_changed(current: int, maximum: int) -> void:
	update_hud("cloth", {"current": current, "max": maximum})

func _on_stamina_changed(current: float, maximum: float) -> void:
	update_hud("stamina", {"current": current, "max": maximum})

func _on_status_changed() -> void:
	var player_state = PlayerManager.get_player_state()
	if player_state:
		update_hud("status", {
			"weak": player_state.is_weak,
			"sticky": player_state.is_sticky
		})
