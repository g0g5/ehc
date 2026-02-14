# 全局设置脚本
# 管理游戏中全局性的参数和配置
extends Node2D


# 基础物理参数
@export var base_gravity := 3000  # 基础重力值


# 重力获取函数
# 返回标准化的重力向量乘以基础重力值
func gravity() -> Vector2:
	return Vector2.DOWN.normalized() * base_gravity