# 游戏常量定义
# 纯静态数据类，用于替代 Global_settings 提供重力等常量

class_name GameConstants
extends RefCounted

# 重力设置（常量，不需要每帧计算）
const GRAVITY_VECTOR: Vector2 = Vector2(0, 3000)  # 直接使用 Vector2(0, 1) * base_gravity

# 玩家相关常量
const PLAYER_MAX_CLOTH: int = 2
const PLAYER_MAX_STAMINA: float = 100.0

# 异常状态持续时间（秒）
const WEAK_DURATION: float = 3.0
const STICKY_DURATION: float = 5.0

# 存档文件路径
const SAVE_PATH: String = "user://save.json"

# 关卡场景映射（用于 GameManager 注册）
const LEVEL_SCENES: Dictionary = {
	"test_level": "res://scenes/Levels/testlevel_playermovement.tscn"
}
