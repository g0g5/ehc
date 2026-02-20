# 设置菜单脚本
# 弹出面板，提供游戏设置选项
extends Control

@export var close_button: Button
@export var back_label: Label

# 设置选项引用（预留）
@export var language_option: OptionButton
@export var fullscreen_check: CheckBox
@export var resolution_option: OptionButton
@export var bgm_slider: HSlider
@export var se_slider: HSlider
@export var input_tab: TabContainer


func _ready() -> void:
	print("[SettingsMenu] 设置菜单初始化")
	_connect_buttons()
	_setup_settings()


func _connect_buttons() -> void:
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

	# 返回文本点击（如果存在）
	if back_label:
		back_label.gui_input.connect(_on_back_label_input)


# 设置选项初始化
func _setup_settings() -> void:
	# 语言选择 - 预留
	if language_option:
		language_option.clear()
		language_option.add_item("简体中文")
		language_option.add_item("English")
		language_option.disabled = true  # 当前版本禁用

	# 全屏选项 - 预留
	if fullscreen_check:
		fullscreen_check.disabled = true  # 当前版本禁用

	# 分辨率选项 - 预留
	if resolution_option:
		resolution_option.clear()
		resolution_option.add_item("1920x1080")
		resolution_option.add_item("1280x720")
		resolution_option.disabled = true  # 当前版本禁用

	# BGM滑块 - 预留
	if bgm_slider:
		bgm_slider.value = 100  # 默认值
		bgm_slider.editable = false  # 当前版本禁用

	# SE滑块 - 预留
	if se_slider:
		se_slider.value = 100  # 默认值
		se_slider.editable = false  # 当前版本禁用

	# 输入切换 - 预留
	if input_tab:
		input_tab.set_tab_disabled(1, true)  # 禁用游戏手柄选项卡


# 关闭按钮
func _on_close_pressed() -> void:
	print("[SettingsMenu] 关闭设置菜单")
	UIManager.go_back()


# 返回文本输入处理
func _on_back_label_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_close_pressed()


# 菜单打开回调（UIManager调用）
func on_menu_open(params: Dictionary = {}) -> void:
	print("[SettingsMenu] 菜单已打开")
	# 可以在这里刷新设置状态


# 菜单关闭回调（UIManager调用）
func on_menu_close() -> void:
	print("[SettingsMenu] 菜单已关闭")
	# 可以在这里保存设置


# ========== 设置功能预留接口 ==========

# 应用语言设置 - 预留
func _apply_language(lang: String) -> void:
	print("[SettingsMenu] 切换语言: %s（预留）" % lang)
	# 后续实现语言切换


# 应用全屏设置 - 预留
func _apply_fullscreen(enabled: bool) -> void:
	print("[SettingsMenu] 全屏: %s（预留）" % enabled)
	# 后续实现全屏切换
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


# 应用分辨率设置 - 预留
func _apply_resolution(width: int, height: int) -> void:
	print("[SettingsMenu] 分辨率: %dx%d（预留）" % [width, height])
	# 后续实现分辨率切换


# 应用音量设置 - 预留
func _apply_volume(bgm_volume: float, se_volume: float) -> void:
	print("[SettingsMenu] 音量 BGM:%.2f SE:%.2f（预留）" % [bgm_volume, se_volume])
	# 后续实现音量控制
