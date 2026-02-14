# 存档管理器
# 全局单例，负责游戏存档的读写和版本管理
extends Node

const SAVE_PATH = "user://save.json"
const SAVE_VERSION = 1

var current_save: Dictionary = {}
var is_loaded: bool = false

func _ready() -> void:
    print("[SaveManager] 存档管理器已初始化")
    # 尝试加载现有存档
    load_game()

# 保存游戏
func save_game() -> void:
    var save_data = _create_save_data()
    var json_string = JSON.stringify(save_data, "\t")

    var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file:
        file.store_string(json_string)
        file.close()
        print("[SaveManager] 游戏已保存到: " + SAVE_PATH)
    else:
        print("[SaveManager] 保存失败: " + str(FileAccess.get_open_error()))

# 加载游戏
func load_game() -> bool:
    if not FileAccess.file_exists(SAVE_PATH):
        print("[SaveManager] 没有找到存档文件")
        is_loaded = false
        return false

    var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
    if not file:
        print("[SaveManager] 读取存档失败: " + str(FileAccess.get_open_error()))
        is_loaded = false
        return false

    var json_string = file.get_as_text()
    file.close()

    var json = JSON.new()
    var error = json.parse(json_string)
    if error != OK:
        print("[SaveManager] JSON解析失败: " + json.get_error_message())
        is_loaded = false
        return false

    var loaded_data = json.data

    # 版本检查
    if not loaded_data.has("version"):
        print("[SaveManager] 存档版本不兼容")
        is_loaded = false
        return false

    if loaded_data.version != SAVE_VERSION:
        print("[SaveManager] 存档版本不匹配: " + str(loaded_data.version) + " vs " + str(SAVE_VERSION))
        # 可以在这里添加版本迁移逻辑
        is_loaded = false
        return false

    current_save = loaded_data
    is_loaded = true
    print("[SaveManager] 存档已加载")
    return true

# 删除存档
func delete_save() -> void:
    if FileAccess.file_exists(SAVE_PATH):
        DirAccess.remove_absolute(SAVE_PATH)
        current_save = {}
        is_loaded = false
        print("[SaveManager] 存档已删除")

# 检查是否有存档
func has_save() -> bool:
    return FileAccess.file_exists(SAVE_PATH)

# 获取最后游玩的关卡
func get_last_level() -> String:
    if is_loaded and current_save.has("current_level"):
        return current_save.current_level
    return ""

# 设置最后游玩的关卡
func set_last_level(level_id: String) -> void:
    if not is_loaded:
        _init_new_save()
    current_save.current_level = level_id
    current_save.timestamp = Time.get_datetime_string_from_system()

# 设置最后存档点
func set_last_checkpoint(pos: Vector2) -> void:
    if not is_loaded:
        _init_new_save()
    current_save.last_checkpoint = {"x": pos.x, "y": pos.y}

# 获取最后存档点
func get_last_checkpoint() -> Vector2:
    if is_loaded and current_save.has("last_checkpoint"):
        var cp = current_save.last_checkpoint
        return Vector2(cp.x, cp.y)
    return Vector2.ZERO

# 保存玩家状态
func set_player_state(cloth: int, stamina: float, status_effects: Array = []) -> void:
    if not is_loaded:
        _init_new_save()
    current_save.player = {
        "cloth": cloth,
        "stamina": stamina,
        "status_effects": status_effects
    }

# 获取玩家状态
func get_player_state() -> Dictionary:
    if is_loaded and current_save.has("player"):
        return current_save.player
    return {}

# 创建存档数据字典
func _create_save_data() -> Dictionary:
    if not is_loaded:
        _init_new_save()

    return current_save

# 初始化新存档
func _init_new_save() -> void:
    current_save = {
        "version": SAVE_VERSION,
        "timestamp": Time.get_datetime_string_from_system(),
        "current_level": "",
        "last_checkpoint": {"x": 0, "y": 0},
        "player": {
            "cloth": 2,
            "stamina": 100,
            "status_effects": []
        },
        "level_state": {
            "defeated_enemies": [],
            "collected_items": []
        }
    }
    is_loaded = true
