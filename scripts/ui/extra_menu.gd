# 画廊入口菜单脚本 (ExtraMenu)
# 提供画廊场景、图库、奖励内容等入口
extends Control

@export var back_button: Button
@export var gallery_button: Button
@export var library_button: Button
@export var bonus_button: Button


func _ready() -> void:
	print("[ExtraMenu] 画廊入口菜单初始化")
	_connect_buttons()


func _connect_buttons() -> void:
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	if gallery_button:
		gallery_button.pressed.connect(_on_gallery_pressed)
	if library_button:
		library_button.pressed.connect(_on_library_pressed)
	if bonus_button:
		bonus_button.pressed.connect(_on_bonus_pressed)


# 返回按钮
func _on_back_pressed() -> void:
	print("[ExtraMenu] 返回主菜单")
	UIManager.go_back()


# 画廊场景按钮 - 预留
func _on_gallery_pressed() -> void:
	print("[ExtraMenu] 打开画廊场景（预留）")
	# 当前版本空实现
	# UIManager.open_menu(UIManager.MenuID.GALLERY_SCENES)


# 图库按钮 - 预留
func _on_library_pressed() -> void:
	print("[ExtraMenu] 打开图库（预留）")
	# 当前版本空实现
	# UIManager.open_menu(UIManager.MenuID.LIBRARY_MENU)


# 奖励关卡按钮 - 预留
func _on_bonus_pressed() -> void:
	print("[ExtraMenu] 打开奖励关卡（预留）")
	# 当前版本空实现
	# UIManager.open_menu(UIManager.MenuID.BONUS_MENU)


# 菜单打开回调（UIManager调用）
func on_menu_open(params: Dictionary = {}) -> void:
	print("[ExtraMenu] 菜单已打开")


# 菜单关闭回调（UIManager调用）
func on_menu_close() -> void:
	print("[ExtraMenu] 菜单已关闭")
