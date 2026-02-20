# UI 管理器
# 全局单例，负责管理所有 UI 面板和菜单的显示/隐藏和导航
extends Node

# ==================== 菜单ID枚举 ====================
enum MenuID {
	NONE = 0,           # 无菜单/空状态
	MAIN_MENU,          # 主菜单
	SAVES_MENU,         # 存档菜单（弹出面板）
	EXTRA_MENU,         # 额外内容菜单（画廊入口）
	SETTINGS_MENU,      # 设置菜单（弹出面板）
	GALLERY_SCENES,     # 画廊场景选择
	LIBRARY_MENU,       # 图库/收集品菜单
	BONUS_MENU,         # 奖励/隐藏关卡菜单
	LEVEL_SELECTION,    # 关卡选择菜单
	PAUSE_MENU,         # 游戏内暂停菜单
	GALLERY_PAUSE,      # 画廊模式暂停菜单
}

# ==================== 菜单状态枚举 ====================
enum MenuState {
	HIDDEN,     # 不显示，不可交互，不参与渲染
	ACTIVE,     # 显示且可交互，响应输入
	FROZEN,     # 显示但不可交互，不响应输入（用于背景菜单）
}

# ==================== UI 层级枚举（旧版，保留兼容） ====================
enum UILayer { BACKGROUND, GAME, HUD, POPUP, OVERLAY, TOP }

# ==================== 信号定义 ====================
signal panel_opened(panel_name: String)
signal panel_closed(panel_name: String)
signal hud_updated(data_type: String, value: Variant)
signal menu_opened(menu_id: MenuID)
signal menu_closed(menu_id: MenuID)
signal menu_state_changed(menu_id: MenuID, new_state: MenuState, old_state: MenuState)

# ==================== 菜单配置类 ====================
class MenuConfig:
	var menu_id: MenuID
	var scene_path: String
	var default_layer: int
	var is_popup: bool
	var pause_game: bool

	func _init(p_menu_id: MenuID, p_scene_path: String, p_is_popup: bool = false, p_pause_game: bool = false, p_default_layer: int = 100):
		menu_id = p_menu_id
		scene_path = p_scene_path
		is_popup = p_is_popup
		pause_game = p_pause_game
		default_layer = p_default_layer

# ==================== 私有变量 ====================
# 菜单配置字典: menu_id -> MenuConfig
var _menu_configs: Dictionary = {}

# 菜单实例字典: menu_id -> Node实例
var _menu_instances: Dictionary = {}

# 菜单状态字典: menu_id -> MenuState
var _menu_states: Dictionary = {}

# 导航栈: Array[MenuID]
var _menu_stack: Array[MenuID] = []

# 基础层级
var _base_layer: int = 100

# 已打开的面板字典（旧版兼容）
var open_panels: Dictionary = {}

# UI 导航栈（旧版兼容）
var ui_stack: Array[String] = []

# 当前显示的 HUD 数据
var hud_data: Dictionary = {}

# 根节点引用（用于挂载菜单）
var _ui_root: Node = null

# ==================== 初始化 ====================
func _ready() -> void:
	print("[UIManager] UI 管理器已初始化")
	# 延迟初始化根节点
	call_deferred("_initialize_ui_root")
	# 连接玩家状态变化信号
	_connect_player_signals()
	# 注册默认菜单
	_register_default_menus()


func _initialize_ui_root() -> void:
	# 查找或创建UI根节点
	_ui_root = get_tree().root.get_node_or_null("UI_Root")
	if not _ui_root:
		_ui_root = Control.new()
		_ui_root.name = "UI_Root"
		_ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
		_ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		get_tree().root.add_child.call_deferred(_ui_root)


# ==================== 默认菜单注册 ====================
func _register_default_menus() -> void:
	# 主菜单
	register_menu(MenuID.MAIN_MENU, "res://scenes/UI/main_menu.tscn", false, false)
	# 存档菜单（弹出面板）
	register_menu(MenuID.SAVES_MENU, "res://scenes/UI/saves_menu.tscn", true, false)
	# 画廊入口菜单
	register_menu(MenuID.EXTRA_MENU, "res://scenes/UI/extra_menu.tscn", false, false)
	# 设置菜单（弹出面板）
	register_menu(MenuID.SETTINGS_MENU, "res://scenes/UI/settings_menu.tscn", true, false)
	# 暂停菜单（弹出面板，暂停游戏）
	register_menu(MenuID.PAUSE_MENU, "res://scenes/UI/pause_menu.tscn", true, true)
	# 其他菜单预留
	register_menu(MenuID.GALLERY_SCENES, "res://scenes/UI/gallery_scenes_menu.tscn", false, false)
	register_menu(MenuID.LIBRARY_MENU, "res://scenes/UI/library_menu.tscn", false, false)
	register_menu(MenuID.BONUS_MENU, "res://scenes/UI/bonus_menu.tscn", false, false)
	register_menu(MenuID.LEVEL_SELECTION, "res://scenes/UI/level_selection_menu.tscn", false, false)
	register_menu(MenuID.GALLERY_PAUSE, "res://scenes/UI/gallery_pause_menu.tscn", true, true)


# ==================== 菜单注册接口 ====================
# 注册菜单（初始化时调用）
func register_menu(menu_id: MenuID, scene_path: String, is_popup: bool = false, pause_game: bool = false, default_layer: int = 100) -> void:
	if menu_id == MenuID.NONE:
		push_error("[UIManager] 不能注册 NONE 菜单")
		return
	_menu_configs[menu_id] = MenuConfig.new(menu_id, scene_path, is_popup, pause_game, default_layer)
	print("[UIManager] 注册菜单: %d -> %s" % [menu_id, scene_path])


# ==================== 菜单打开接口 ====================
# 打开指定菜单
# - 如果菜单已打开，则将其置顶并激活
# - 如果是弹出面板：当前菜单变为FROZEN，新菜单ACTIVE
# - 如果不是弹出面板：当前菜单变为HIDDEN，新菜单ACTIVE
func open_menu(menu_id: MenuID, params: Dictionary = {}) -> bool:
	if menu_id == MenuID.NONE:
		push_error("[UIManager] 不能打开 NONE 菜单")
		return false

	var config = _menu_configs.get(menu_id)
	if not config:
		push_error("[UIManager] 未注册的菜单: " + str(menu_id))
		return false

	# 获取或创建菜单实例
	var instance = _get_or_create_menu(menu_id)
	if not instance:
		return false

	# 如果菜单已经在栈顶且是激活状态，只需刷新参数
	if not _menu_stack.is_empty() and _menu_stack[-1] == menu_id:
		if instance.has_method("on_menu_open"):
			instance.on_menu_open(params)
		return true

	# 处理当前菜单状态
	if not _menu_stack.is_empty():
		var current_id = _menu_stack[-1]
		if config.is_popup:
			# 弹出面板：当前菜单变为FROZEN（仍可见但不可交互）
			_set_menu_state(current_id, MenuState.FROZEN)
		else:
			# 非弹出菜单：当前菜单变为HIDDEN（隐藏但保留在栈中用于返回）
			_set_menu_state(current_id, MenuState.HIDDEN)

	# 添加到栈并激活
	_menu_stack.append(menu_id)
	_set_menu_state(menu_id, MenuState.ACTIVE)
	_update_menu_layer(menu_id)

	# 暂停游戏（如果需要）
	if config.pause_game and not get_tree().paused:
		get_tree().paused = true

	# 初始化菜单（如果支持）
	if instance.has_method("on_menu_open"):
		instance.on_menu_open(params)

	menu_opened.emit(menu_id)
	print("[UIManager] 打开菜单: %d, 栈深度: %d" % [menu_id, _menu_stack.size()])
	return true


# ==================== 菜单关闭接口 ====================
# 关闭指定菜单
# - 如果该菜单在栈顶，关闭后自动恢复下一层菜单为ACTIVE
# - 如果该菜单不在栈顶，仅将其状态设为HIDDEN
func close_menu(menu_id: MenuID) -> bool:
	if menu_id == MenuID.NONE:
		return false

	if not _menu_instances.has(menu_id):
		return false

	var stack_index = _menu_stack.find(menu_id)
	if stack_index == -1:
		# 菜单不在栈中，仅设置为HIDDEN
		_set_menu_state(menu_id, MenuState.HIDDEN)
		return true

	# 关闭菜单
	_set_menu_state(menu_id, MenuState.HIDDEN)

	# 如果在栈顶，需要恢复下层菜单
	if stack_index == _menu_stack.size() - 1:
		_menu_stack.pop_back()
		if not _menu_stack.is_empty():
			var new_top = _menu_stack[-1]
			_set_menu_state(new_top, MenuState.ACTIVE)
			# 检查是否需要恢复游戏暂停状态
			_check_pause_state()
	else:
		# 不在栈顶，仅从栈中移除
		_menu_stack.remove_at(stack_index)

	menu_closed.emit(menu_id)
	print("[UIManager] 关闭菜单: %d, 栈深度: %d" % [menu_id, _menu_stack.size()])
	return true


# 关闭当前最上层菜单（等同于按返回键）
func close_top_menu() -> bool:
	if _menu_stack.is_empty():
		return false
	return close_menu(_menu_stack[-1])


# ==================== 返回导航接口 ====================
# 返回上一级菜单
# - 关闭当前栈顶菜单
# - 恢复新的栈顶菜单为ACTIVE状态
# - 如果栈为空，返回false
func go_back() -> bool:
	if _menu_stack.is_empty():
		print("[UIManager] 导航栈为空，无法返回")
		return false

	var current_id = _menu_stack[-1]

	# 关闭当前菜单（会自动恢复下层菜单）
	return close_menu(current_id)


# 返回到指定菜单（关闭所有在其之上的菜单）
# - 如果目标菜单不在栈中，返回false
# - 将目标菜单以上的所有菜单关闭，目标菜单设为ACTIVE
func go_back_to(target_menu_id: MenuID) -> bool:
	if target_menu_id == MenuID.NONE:
		return false

	var target_index = _menu_stack.find(target_menu_id)
	if target_index == -1:
		push_error("[UIManager] 目标菜单不在栈中: " + str(target_menu_id))
		return false

	# 关闭所有在目标之上的菜单
	while _menu_stack.size() > target_index + 1:
		var menu_id = _menu_stack.pop_back()
		_set_menu_state(menu_id, MenuState.HIDDEN)
		menu_closed.emit(menu_id)

	# 激活目标菜单
	_set_menu_state(target_menu_id, MenuState.ACTIVE)
	_check_pause_state()

	print("[UIManager] 返回到菜单: %d, 栈深度: %d" % [target_menu_id, _menu_stack.size()])
	return true


# 返回到主菜单（清空栈并打开主菜单）
func return_to_main_menu() -> void:
	# 隐藏所有菜单
	_for_hide_all_menus_in_stack()
	_menu_stack.clear()
	# 打开主菜单
	open_menu(MenuID.MAIN_MENU)
	print("[UIManager] 返回主菜单")


# ==================== 状态查询接口 ====================
# 获取当前最上层菜单ID
func get_current_menu() -> MenuID:
	if _menu_stack.is_empty():
		return MenuID.NONE
	return _menu_stack[-1]


# 获取指定菜单的当前状态
func get_menu_state(menu_id: MenuID) -> MenuState:
	return _menu_states.get(menu_id, MenuState.HIDDEN)


# 检查指定菜单是否已打开（ACTIVE或FROZEN）
func is_menu_open(menu_id: MenuID) -> bool:
	var state = _menu_states.get(menu_id, MenuState.HIDDEN)
	return state == MenuState.ACTIVE or state == MenuState.FROZEN


# 获取菜单在栈中的层级（0表示栈底，越大越靠上）
func get_menu_stack_index(menu_id: MenuID) -> int:
	return _menu_stack.find(menu_id)


# 获取当前栈深度
func get_stack_depth() -> int:
	return _menu_stack.size()


# ==================== 层级管理接口 ====================
# 设置菜单的显示层级（动态调整Z-Index或CanvasLayer）
func set_menu_layer(menu_id: MenuID, layer: int) -> void:
	var instance = _menu_instances.get(menu_id)
	if not instance:
		return

	# 尝试设置CanvasLayer的layer属性
	var canvas_layer = instance.get_parent()
	if canvas_layer is CanvasLayer:
		canvas_layer.layer = layer


# 将菜单置顶（设为当前最高层级）
func bring_to_front(menu_id: MenuID) -> void:
	var stack_index = _menu_stack.find(menu_id)
	if stack_index == -1:
		return

	# 从当前位置移除并添加到栈顶
	_menu_stack.remove_at(stack_index)
	_menu_stack.append(menu_id)

	# 更新所有菜单的层级
	for i in range(_menu_stack.size()):
		var id = _menu_stack[i]
		var base_layer = _menu_configs[id].default_layer if _menu_configs.has(id) else _base_layer
		set_menu_layer(id, base_layer + i * 10)


# ==================== 内部辅助方法 ====================
# 获取或创建菜单实例
func _get_or_create_menu(menu_id: MenuID) -> Node:
	# 如果已存在实例，直接返回
	if _menu_instances.has(menu_id) and is_instance_valid(_menu_instances[menu_id]):
		return _menu_instances[menu_id]

	var config = _menu_configs.get(menu_id)
	if not config:
		push_error("[UIManager] 未找到菜单配置: " + str(menu_id))
		return null

	# 加载场景
	var scene = load(config.scene_path)
	if not scene:
		push_error("[UIManager] 无法加载菜单场景: " + config.scene_path)
		return null

	# 创建CanvasLayer用于层级管理
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "CanvasLayer_" + str(menu_id)
	canvas_layer.layer = config.default_layer

	# 实例化菜单
	var instance = scene.instantiate()
	instance.name = "Menu_" + str(menu_id)

	# 添加到CanvasLayer
	canvas_layer.add_child(instance)

	# 添加到UI根节点
	if _ui_root:
		_ui_root.add_child(canvas_layer)
	else:
		get_tree().root.add_child(canvas_layer)

	# 初始状态为隐藏
	instance.hide()
	instance.process_mode = Node.PROCESS_MODE_DISABLED

	_menu_instances[menu_id] = instance
	_menu_states[menu_id] = MenuState.HIDDEN

	return instance


# 设置菜单状态
func _set_menu_state(menu_id: MenuID, state: MenuState) -> void:
	var old_state = _menu_states.get(menu_id, MenuState.HIDDEN)
	if old_state == state:
		return

	_menu_states[menu_id] = state
	var instance = _menu_instances.get(menu_id)
	if not instance:
		return

	match state:
		MenuState.HIDDEN:
			instance.hide()
			instance.process_mode = Node.PROCESS_MODE_DISABLED
			# 同时隐藏父级CanvasLayer
			var parent = instance.get_parent()
			if parent is CanvasLayer:
				parent.hide()
		MenuState.ACTIVE:
			instance.show()
			instance.process_mode = Node.PROCESS_MODE_INHERIT
			var parent = instance.get_parent()
			if parent is CanvasLayer:
				parent.show()
		MenuState.FROZEN:
			instance.show()
			instance.process_mode = Node.PROCESS_MODE_DISABLED
			var parent = instance.get_parent()
			if parent is CanvasLayer:
				parent.show()

	menu_state_changed.emit(menu_id, state, old_state)


# 更新菜单层级
func _update_menu_layer(menu_id: MenuID) -> void:
	var stack_index = _menu_stack.find(menu_id)
	if stack_index == -1:
		return

	var config = _menu_configs.get(menu_id)
	var base_layer = config.default_layer if config else _base_layer
	var is_popup = config.is_popup if config else false

	# 弹出面板使用更高的基础层级
	if is_popup:
		base_layer = 200

	var final_layer = base_layer + stack_index * 10
	set_menu_layer(menu_id, final_layer)


# 隐藏栈中所有菜单
func _for_hide_all_menus_in_stack() -> void:
	for menu_id in _menu_stack:
		_set_menu_state(menu_id, MenuState.HIDDEN)


# 检查并更新游戏暂停状态
func _check_pause_state() -> void:
	var should_pause = false
	for menu_id in _menu_stack:
		var config = _menu_configs.get(menu_id)
		if config and config.pause_game:
			should_pause = true
			break

	get_tree().paused = should_pause


# ==================== 连接玩家信号 ====================
func _connect_player_signals() -> void:
	# 等待 PlayerManager 准备好
	await get_tree().process_frame
	var player_state = PlayerManager.get_player_state()
	if player_state:
		player_state.cloth_broked.connect(_on_cloth_changed)
		player_state.stamina_changed.connect(_on_stamina_changed)
		player_state.became_weak.connect(_on_status_changed)
		player_state.became_sticky.connect(_on_status_changed)


# ==================== 旧版面板系统（保留兼容） ====================
func open_panel(panel_name: String, params: Dictionary = {}) -> void:
	open_panels[panel_name] = params
	panel_opened.emit(panel_name)
	print("[UIManager] 打开面板: ", panel_name)


func close_panel(panel_name: String) -> void:
	if open_panels.has(panel_name):
		open_panels.erase(panel_name)
		panel_closed.emit(panel_name)
		print("[UIManager] 关闭面板: ", panel_name)


func close_all_panels() -> void:
	var panels = open_panels.keys()
	for panel_name in panels:
		close_panel(panel_name)


func is_panel_open(panel_name: String) -> bool:
	return open_panels.has(panel_name)


func push_ui_state(panel_name: String) -> void:
	ui_stack.append(panel_name)


func pop_ui_state() -> String:
	if ui_stack.is_empty():
		return ""
	return ui_stack.pop_back()


# ==================== HUD 更新接口 ====================
func update_hud(data_type: String, value: Variant) -> void:
	hud_data[data_type] = value
	hud_updated.emit(data_type, value)


func refresh_ui() -> void:
	print("[UIManager] 刷新 UI")
	for key in hud_data:
		hud_updated.emit(key, hud_data[key])


func show_message(text: String, duration: float = 2.0) -> void:
	print("[UIManager] 消息: ", text)


func show_confirm(title: String, message: String, callback: Callable) -> void:
	print("[UIManager] 确认对话框: ", title, " - ", message)


func show_loading(text: String = "Loading...") -> void:
	print("[UIManager] 加载中: ", text)


func hide_loading() -> void:
	print("[UIManager] 加载完成")


# ==================== 信号回调 ====================
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


# ==================== 输入处理 ====================
func _input(event: InputEvent) -> void:
	# 处理ESC键返回
	if event.is_action_pressed("ui_cancel"):
		# 如果有打开的菜单，执行返回操作
		if not _menu_stack.is_empty():
			var current_menu = _menu_stack[-1]
			var config = _menu_configs.get(current_menu)
			# 弹出面板可以ESC关闭，非弹出菜单不处理
			if config and config.is_popup:
				go_back()
			get_viewport().set_input_as_handled()
