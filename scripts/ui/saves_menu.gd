# 存档菜单脚本
# 弹出面板，显示存档槽位供玩家选择
extends Control

@export var close_button: Button
@export var save_slot_1: Control
@export var save_slot_2: Control
@export var save_slot_3: Control


func _ready() -> void:
	print("[SavesMenu] 存档菜单初始化")
	_connect_buttons()
	_setup_save_slots()


func _connect_buttons() -> void:
	if close_button:
		close_button.pressed.connect(_on_close_pressed)


# 设置存档槽位显示
func _setup_save_slots() -> void:
	# 存档槽1 - 显示角色立绘和最后关卡
	if save_slot_1:
		_setup_slot(save_slot_1, 1, true)

	# 存档槽2/3 - 显示"+"号表示新建
	if save_slot_2:
		_setup_slot(save_slot_2, 2, false)
	if save_slot_3:
		_setup_slot(save_slot_3, 3, false)


# 配置单个存档槽
func _setup_slot(slot: Control, slot_number: int, has_data: bool) -> void:
	# 查找槽位内的交互元素
	var button = slot.get_node_or_null("Button")
	var icon = slot.get_node_or_null("Icon")
	var label = slot.get_node_or_null("Label")

	if button:
		button.pressed.connect(func(): _on_slot_pressed(slot_number))

	if has_data:
		# 有存档数据的显示
		if label:
			label.text = "#LAST LEVEL"
		if icon:
			# 显示角色立绘（预留）
			pass
	else:
		# 空存档槽显示"+"
		if label:
			label.text = "+"


# 关闭按钮
func _on_close_pressed() -> void:
	print("[SavesMenu] 关闭存档菜单")
	UIManager.go_back()


# 存档槽点击
func _on_slot_pressed(slot_number: int) -> void:
	print("[SavesMenu] 点击存档槽: %d" % slot_number)
	# 当前版本无实际功能，预留
	# 后续实现：加载对应存档或开始新游戏


# 菜单打开回调（UIManager调用）
func on_menu_open(params: Dictionary = {}) -> void:
	print("[SavesMenu] 菜单已打开")
	# 刷新存档数据
	_refresh_save_data()


# 刷新存档数据显示
func _refresh_save_data() -> void:
	# 检查SaveManager获取存档信息
	if SaveManager.has_save():
		print("[SavesMenu] 检测到存档数据")
		# 可以在这里更新槽位显示
	else:
		print("[SavesMenu] 无存档数据")
