# 主菜单脚本
# 游戏入口主菜单，提供开始游戏、画廊、设置、退出等功能
extends Control

@export var start_button: Button
@export var gallery_button: Button
@export var settings_button: Button
@export var quit_button: Button


func _ready() -> void:
	print("[MainMenu] 主菜单初始化")
	_connect_buttons()
	# 确保游戏状态为标题
	if GameManager.get_current_state() != GameManager.GameState.TITLE:
		GameManager.return_to_title()


func _connect_buttons() -> void:
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
	if gallery_button:
		gallery_button.pressed.connect(_on_gallery_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)


# 开始按钮 - 打开存档菜单
func _on_start_pressed() -> void:
	print("[MainMenu] 开始游戏 - 打开存档菜单")
	UIManager.open_menu(UIManager.MenuID.SAVES_MENU)


# 画廊按钮 - 打开画廊入口菜单
func _on_gallery_pressed() -> void:
	print("[MainMenu] 打开画廊入口")
	UIManager.open_menu(UIManager.MenuID.EXTRA_MENU)


# 设置按钮 - 打开设置菜单
func _on_settings_pressed() -> void:
	print("[MainMenu] 打开设置菜单")
	UIManager.open_menu(UIManager.MenuID.SETTINGS_MENU)


# 退出按钮 - 退出游戏
func _on_quit_pressed() -> void:
	print("[MainMenu] 退出游戏")
	GameManager.quit_game()


# 菜单打开回调（UIManager调用）
func on_menu_open(params: Dictionary = {}) -> void:
	print("[MainMenu] 菜单已打开")
	# 可以在这里处理打开动画或参数


# 菜单关闭回调（UIManager调用）
func on_menu_close() -> void:
	print("[MainMenu] 菜单已关闭")
	# 可以在这里处理关闭动画
