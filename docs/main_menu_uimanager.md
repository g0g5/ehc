# 主菜单与UI Manager 功能规格文档

## 文档信息
- **版本**: 1.0
- **日期**: 2026-02-20
- **状态**: 设计阶段

---

## 1. 概述

本文档详细描述游戏主菜单系统与UIManager的功能规格，包括菜单导航流程、状态管理、层级系统等核心机制。

---

## 2. 术语定义

| 术语 | 定义 |
|------|------|
| **菜单（Menu）** | 独立的UI场景，如主菜单、设置菜单等 |
| **面板（Panel）** | 可弹出的覆盖层，如存档选择面板 |
| **UI状态** | 菜单的显示状态：隐藏(HIDDEN)、显示活动(ACTIVE)、显示冻结(FROZEN) |
| **导航栈** | 记录菜单打开顺序的栈结构，用于返回导航 |
| **层级（Layer）** | 菜单的Z轴排序，数值越高显示在越上层 |

---

## 3. UI Manager 规格

### 3.1 菜单ID枚举

```gdscript
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
```

### 3.2 菜单状态枚举

```gdscript
enum MenuState {
    HIDDEN,     # 不显示，不可交互，不参与渲染
    ACTIVE,     # 显示且可交互，响应输入
    FROZEN,     # 显示但不可交互，不响应输入（用于背景菜单）
}
```

### 3.3 菜单配置数据

每个菜单注册时包含以下配置：

```gdscript
class MenuConfig:
    var menu_id: MenuID           # 菜单ID
    var scene_path: String        # 场景文件路径
    var default_layer: int        # 默认层级
    var is_popup: bool            # 是否为弹出面板（true则叠加打开，false则切换）
    var pause_game: bool          # 打开时是否暂停游戏
```

### 3.4 UIManager核心接口

#### 3.4.1 菜单注册（初始化时调用）

```gdscript
# 注册所有可用菜单
func register_menu(menu_id: MenuID, scene_path: String, is_popup: bool = false, pause_game: bool = false)

# 示例用法
register_menu(MenuID.MAIN_MENU, "res://scenes/UI/main_menu.tscn", false, false)
register_menu(MenuID.SAVES_MENU, "res://scenes/UI/saves_menu.tscn", true, false)
register_menu(MenuID.SETTINGS_MENU, "res://scenes/UI/settings_menu.tscn", true, false)
```

#### 3.4.2 打开菜单

```gdscript
# 打开指定菜单
# - 如果菜单已打开，则将其置顶并激活
# - 如果是弹出面板：当前菜单变为FROZEN，新菜单ACTIVE
# - 如果不是弹出面板：当前菜单变为HIDDEN，新菜单ACTIVE
func open_menu(menu_id: MenuID, params: Dictionary = {}) -> bool

# 参数说明：
# - menu_id: 要打开的菜单ID
# - params: 传递给菜单的初始化参数（可选）
# - 返回值: 是否成功打开
```

#### 3.4.3 关闭菜单

```gdscript
# 关闭指定菜单
# - 如果该菜单在栈顶，关闭后自动恢复下一层菜单为ACTIVE
# - 如果该菜单不在栈顶，仅将其状态设为HIDDEN
func close_menu(menu_id: MenuID) -> bool

# 关闭当前最上层菜单（等同于按返回键）
func close_top_menu() -> bool
```

#### 3.4.4 返回导航

```gdscript
# 返回上一级菜单
# - 弹出当前栈顶菜单
# - 恢复新的栈顶菜单为ACTIVE状态
# - 如果栈为空，返回false
func go_back() -> bool

# 返回到指定菜单（关闭所有在其之上的菜单）
# - 如果目标菜单不在栈中，返回false
# - 将目标菜单以上的所有菜单关闭，目标菜单设为ACTIVE
func go_back_to(target_menu_id: MenuID) -> bool

# 返回到主菜单（清空栈并打开主菜单）
func return_to_main_menu() -> void
```

#### 3.4.5 状态查询

```gdscript
# 获取当前最上层菜单ID
func get_current_menu() -> MenuID

# 获取指定菜单的当前状态
func get_menu_state(menu_id: MenuID) -> MenuState

# 检查指定菜单是否已打开（ACTIVE或FROZEN）
func is_menu_open(menu_id: MenuID) -> bool

# 获取菜单在栈中的层级（0表示栈底，越大越靠上）
func get_menu_stack_index(menu_id: MenuID) -> int

# 获取当前栈深度
func get_stack_depth() -> int
```

#### 3.4.6 层级管理

```gdscript
# 设置菜单的显示层级（动态调整Z-Index或CanvasLayer）
func set_menu_layer(menu_id: MenuID, layer: int)

# 将菜单置顶（设为当前最高层级）
func bring_to_front(menu_id: MenuID)
```

### 3.5 导航栈行为规则

| 操作 | 栈行为 | 状态变化 |
|------|--------|----------|
| 打开弹出面板 | 压栈 | 原菜单→FROZEN，新菜单→ACTIVE |
| 打开非弹出菜单 | 清空栈后压栈 | 原菜单→HIDDEN，新菜单→ACTIVE |
| 关闭菜单 | 弹栈 | 被关菜单→HIDDEN，新栈顶→ACTIVE |
| 返回 | 弹栈 | 被弹菜单→HIDDEN，新栈顶→ACTIVE |

### 3.6 层级分配规则

| 菜单类型 | 基础层级 | 动态偏移 |
|----------|----------|----------|
| 主菜单 | 100 | +栈深度×10 |
| 非弹出菜单 | 100 | +栈深度×10 |
| 弹出面板 | 200 | +栈深度×10 |
| 模态对话框 | 300 | +栈深度×10 |

---

## 4. 主菜单系统规格

### 4.1 主菜单（MainMenu）

**场景**: `scenes/UI/main_menu.tscn`

#### 4.1.1 按钮绑定

| 按钮 | 点击行为 | 说明 |
|------|----------|------|
| 开始按钮 | `open_menu(MenuID.SAVES_MENU)` | 弹出存档菜单（弹出面板） |
| 画廊按钮 | `open_menu(MenuID.EXTRA_MENU)` | 切换到画廊菜单（非弹出，切换） |
| 设置按钮 | `open_menu(MenuID.SETTINGS_MENU)` | 弹出设置菜单（弹出面板） |
| 退出按钮 | `GameManager.quit_game()` | 退出游戏进程 |

#### 4.1.2 状态处理

- 打开时：自动设置为ACTIVE状态
- 被覆盖时：变为FROZEN状态（仍可见但不可交互）
- 返回时：如果是栈底菜单，显示退出确认对话框

### 4.2 存档菜单（SavesMenu）- 弹出面板

**场景**: `scenes/UI/saves_menu.tscn`
**类型**: 弹出面板 (is_popup = true)

#### 4.2.1 功能规格

| 功能 | 实现 | 备注 |
|------|------|------|
| 存档槽1显示 | 占位显示 | 显示角色立绘和"#LAST LEVEL"文本 |
| 存档槽2/3 | 占位显示 | 显示"+"号表示新建 |
| 关闭按钮 | `go_back()` 或 `close_menu(MenuID.SAVES_MENU)` | 返回主菜单 |
| 点击存档槽 | 空实现（预留） | 当前版本无实际功能 |

#### 4.2.2 层级关系

- 打开时覆盖在主菜单之上
- 主菜单变为FROZEN状态（可见但不可交互）
- 关闭后主菜单恢复ACTIVE状态

### 4.3 画廊入口菜单（ExtraMenu）

**场景**: `scenes/UI/extra_menu.tscn`
**类型**: 非弹出菜单 (is_popup = false)

#### 4.3.1 功能规格

| 按钮 | 点击行为 | 说明 |
|------|----------|------|
| 返回按钮 | `go_back()` | 返回主菜单 |
| GALLERY按钮 | 预留 | 当前版本空实现 |
| LIBRARY按钮 | 预留 | 当前版本空实现 |

#### 4.3.2 导航行为

- 打开时主菜单变为HIDDEN（不显示）
- 返回时重新打开主菜单

### 4.4 设置菜单（SettingsMenu）- 弹出面板

**场景**: `scenes/UI/settings_menu.tscn`
**类型**: 弹出面板 (is_popup = true)

#### 4.4.1 功能规格

| 元素 | 行为 | 说明 |
|------|------|------|
| 关闭按钮(X) | `go_back()` | 返回上一级 |
| 返回主菜单文本 | `go_back()` | 同上 |
| 语言选择 | 空实现 | 预留 |
| 全屏选项 | 空实现 | 预留 |
| 屏幕尺寸 | 空实现 | 预留 |
| BGM/SE滑块 | 空实现 | 预留 |
| 键盘/手柄切换 | 空实现 | 预留 |

#### 4.4.2 层级关系

- 可从主菜单或其他菜单打开
- 关闭时返回打开它的菜单

### 4.5 GameManager.quit_game() 规格

```gdscript
# GameManager 需提供的方法
func quit_game() -> void:
    # 显示退出确认对话框（可选）
    # 调用 get_tree().quit()
```

---

## 5. 状态流转图

### 5.1 主菜单流程

```
[MAIN_MENU - ACTIVE]
        |
    +---+---+-----------+
    |       |           |
    v       v           v
[SAVES_MENU] [EXTRA_MENU] [SETTINGS_MENU]
 (弹出,FROZEN  切换,HIDDEN   弹出,FROZEN
  主菜单)      主菜单)      主菜单)
    |           |           |
    v           v           v
  go_back()   go_back()   go_back()
    |           |           |
    +-----+-----+-----------+
          |
          v
   [回到MAIN_MENU - ACTIVE]
```

### 5.2 菜单状态转换

```
HIDDEN <------+----------+----------+
   ^          |          |          |
   |          v          v          v
   |    [打开新菜单] -------------+
   |          |
   |          v
   |   +---------------------+
   |   |                     |
   +---+ ACTIVE <--------> FROZEN
   |   [被弹出覆盖]    [弹出关闭]
   +-------------------------------+
```

---

## 6. 实现清单

### 6.1 UIManager修改

- [ ] 添加MenuID枚举
- [ ] 添加MenuState枚举
- [ ] 添加菜单注册系统
- [ ] 实现open_menu()方法
- [ ] 实现close_menu()方法
- [ ] 实现go_back()方法
- [ ] 实现go_back_to()方法
- [ ] 实现层级自动分配
- [ ] 实现状态管理逻辑

### 6.2 主菜单脚本

- [ ] 创建 `scripts/ui/main_menu.gd`
- [ ] 绑定开始按钮 -> open_menu(MenuID.SAVES_MENU)
- [ ] 绑定画廊按钮 -> open_menu(MenuID.EXTRA_MENU)
- [ ] 绑定设置按钮 -> open_menu(MenuID.SETTINGS_MENU)
- [ ] 绑定退出按钮 -> GameManager.quit_game()

### 6.3 存档菜单脚本

- [ ] 创建 `scripts/ui/saves_menu.gd`
- [ ] 绑定关闭按钮 -> go_back()
- [ ] 存档槽位占位显示

### 6.4 画廊菜单脚本

- [ ] 创建 `scripts/ui/extra_menu.gd`
- [ ] 绑定返回按钮 -> go_back()

### 6.5 设置菜单脚本

- [ ] 创建 `scripts/ui/settings_menu.gd`
- [ ] 绑定关闭按钮 -> go_back()
- [ ] 绑定返回文本 -> go_back()

### 6.6 GameManager扩展

- [ ] 添加quit_game()方法

---

## 7. 代码示例

### 7.1 UIManager核心逻辑

```gdscript
# UIManager.gd 关键实现示意

var _menu_configs: Dictionary = {}      # menu_id -> MenuConfig
var _menu_instances: Dictionary = {}    # menu_id -> Node实例
var _menu_states: Dictionary = {}       # menu_id -> MenuState
var _menu_stack: Array[MenuID] = []     # 导航栈
var _base_layer: int = 100              # 基础层级

func open_menu(menu_id: MenuID, params: Dictionary = {}) -> bool:
    var config = _menu_configs.get(menu_id)
    if not config:
        push_error("未注册的菜单: " + str(menu_id))
        return false

    # 获取或创建菜单实例
    var instance = _get_or_create_menu(menu_id)
    if not instance:
        return false

    # 处理当前菜单
    if not _menu_stack.is_empty():
        var current_id = _menu_stack[-1]
        if config.is_popup:
            _set_menu_state(current_id, MenuState.FROZEN)
        else:
            _set_menu_state(current_id, MenuState.HIDDEN)

    # 添加到栈并激活
    _menu_stack.append(menu_id)
    _set_menu_state(menu_id, MenuState.ACTIVE)
    _update_menu_layer(menu_id)

    # 初始化菜单（如果支持）
    if instance.has_method("on_menu_open"):
        instance.on_menu_open(params)

    return true

func go_back() -> bool:
    if _menu_stack.size() <= 1:
        return false

    var current_id = _menu_stack.pop_back()
    _set_menu_state(current_id, MenuState.HIDDEN)

    var new_top = _menu_stack[-1]
    _set_menu_state(new_top, MenuState.ACTIVE)

    return true

func _set_menu_state(menu_id: MenuID, state: MenuState):
    _menu_states[menu_id] = state
    var instance = _menu_instances.get(menu_id)
    if instance:
        match state:
            MenuState.HIDDEN:
                instance.hide()
                instance.process_mode = Node.PROCESS_MODE_DISABLED
            MenuState.ACTIVE:
                instance.show()
                instance.process_mode = Node.PROCESS_MODE_INHERIT
            MenuState.FROZEN:
                instance.show()
                instance.process_mode = Node.PROCESS_MODE_DISABLED
```

### 7.2 菜单脚本基类

```gdscript
# BaseMenu.gd - 菜单基类（可选）
extends Control

@export var menu_id: UIManager.MenuID

func _ready():
    # 自动注册到UIManager
    pass

func on_menu_open(params: Dictionary):
    # 子类重写此方法处理打开逻辑
    pass

func on_menu_close():
    # 子类重写此方法处理关闭逻辑
    pass

func close_self():
    UIManager.close_menu(menu_id)
```

---

## 8. 注意事项

1. **层级渲染**: 使用CanvasLayer或Z-Index确保层级正确
2. **输入处理**: FROZEN状态必须禁用_process和_input处理
3. **内存管理**: 考虑菜单实例的预加载/懒加载策略
4. **过渡动画**: 预留动画接口，后续可添加打开/关闭动画
5. **返回键处理**: 需要监听物理返回键（如ESC键、手柄B键）

---

## 9. 附录

### 9.1 菜单配置表

| 菜单ID | 场景路径 | 类型 | pause_game |
|--------|----------|------|------------|
| MAIN_MENU | res://scenes/UI/main_menu.tscn | 非弹出 | false |
| SAVES_MENU | res://scenes/UI/saves_menu.tscn | 弹出 | false |
| EXTRA_MENU | res://scenes/UI/extra_menu.tscn | 非弹出 | false |
| SETTINGS_MENU | res://scenes/UI/settings_menu.tscn | 弹出 | false |
| GALLERY_SCENES | res://scenes/UI/gallery_scenes_menu.tscn | 非弹出 | false |
| LIBRARY_MENU | res://scenes/UI/library_menu.tscn | 非弹出 | false |
| BONUS_MENU | res://scenes/UI/bonus_menu.tscn | 非弹出 | false |
| LEVEL_SELECTION | res://scenes/UI/level_selection_menu.tscn | 非弹出 | false |
| PAUSE_MENU | res://scenes/UI/pause_menu.tscn | 弹出 | true |
| GALLERY_PAUSE | res://scenes/UI/gallery_pause_menu.tscn | 弹出 | true |

### 9.2 相关文件列表

- `scripts/autoload/ui_manager.gd` - UIManager核心脚本
- `scripts/ui/main_menu.gd` - 主菜单脚本（需创建）
- `scripts/ui/saves_menu.gd` - 存档菜单脚本（需创建）
- `scripts/ui/extra_menu.gd` - 画廊入口脚本（需创建）
- `scripts/ui/settings_menu.gd` - 设置菜单脚本（需创建）
- `scenes/UI/main_menu.tscn` - 主菜单场景
- `scenes/UI/saves_menu.tscn` - 存档菜单场景
- `scenes/UI/extra_menu.tscn` - 画廊入口场景
- `scenes/UI/settings_menu.tscn` - 设置菜单场景
