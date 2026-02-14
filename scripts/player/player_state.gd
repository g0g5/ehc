# 玩家状态管理脚本
# 负责管理玩家的生命值、体力、异常状态等核心游戏机制
extends Node
class_name PlayerState

# 信号定义 - 用于通知UI和其他系统状态变化**只和ui，统计，敌人等其他系统状态变化**
signal cloth_broked(new_cloth, max_cloth)    # 衣服破损信号
signal stamina_changed(new_stamina, max_stamina)  # 体力变化信号
signal became_weak()      # 进入虚弱状态信号
signal became_sticky()    # 进入粘液状态信号
signal gameover()         # 游戏结束信号

# 核心属性配置
@export var max_cloth := 2       # 最大衣服层数
@export var max_stamina := 100.0 # 最大体力值

# 当前状态变量（供外部读取）
var current_cloth: int           # 当前剩余衣服层数
var current_stamina: int         # 当前体力值
var is_weak: bool = false        # 是否处于虚弱状态
var is_sticky: bool = false      # 是否处于粘液状态

# 虚弱状态相关参数
var weak_knockback_factor: float = 0.95  # 虚弱状态下的击飞衰减系数

# 粘液状态相关参数
var sticky_friction_factor: float = 1    # 粘液状态下的摩擦力系数

# 状态恢复计时器
var sticky_recover_timer: Timer  # 粘液状态恢复计时器
var weak_recover_timer: Timer    # 虚弱状态恢复计时器

# 初始化函数
func _ready() -> void:
    reset_states()
    
    # 创建虚弱状态恢复计时器
    weak_recover_timer = Timer.new()
    add_child(weak_recover_timer)
    weak_recover_timer.one_shot = true  # 单次触发
    weak_recover_timer.timeout.connect(recover_from_weak)
    weak_recover_timer.stop()
    
    # 创建粘液状态恢复计时器
    sticky_recover_timer = Timer.new()
    add_child(sticky_recover_timer)
    sticky_recover_timer.one_shot = true  # 单次触发
    sticky_recover_timer.timeout.connect(recover_from_sticky)
    sticky_recover_timer.stop()

# 状态重置函数
func reset_states():
    current_cloth = max_cloth
    current_stamina = max_stamina
    is_weak = false
    weak_knockback_factor = 0.95
    sticky_friction_factor = 1.0
    cloth_broked.emit(current_cloth, max_cloth)
    stamina_changed.emit(current_stamina, max_stamina)

# 受伤处理函数
# 参数：cloth_damage-衣服损伤, stamina_damage-体力损伤, knockback_force-击飞力度
# 返回：最终的击飞力度（可能受状态影响）
func take_damage(cloth_damage: int, stamina_damage: int, knockback_force: float) -> float:
    var final_knockback = knockback_force  # 基础击飞力

    # 处理衣服损伤
    if current_cloth > 0:
        current_cloth = max(current_cloth - cloth_damage, 0)
        cloth_broked.emit(current_cloth, max_cloth)
        
        # 衣服完全破损时进入虚弱状态
        if current_cloth == 0:
            _add_weak_state()
            final_knockback *= weak_knockback_factor

    else:
        # 已经没有衣服时扣除体力
        _add_weak_state()
        current_stamina = max(current_stamina - stamina_damage, 0)
        stamina_changed.emit(current_stamina, max_stamina)

        # 虚弱状态下进一步削弱击飞效果
        if is_weak:
            final_knockback *= weak_knockback_factor
            weak_knockback_factor *= 0.90  # 逐次递减
            print("[状态机] 虚弱状态击飞衰减系数更新为: ", weak_knockback_factor)

        # 体力耗尽则游戏结束
        if current_stamina <= 0.0:
            gameover.emit()
            
    print("[状态机] 生命: %d/%d, 体力: %d/%d, 虚弱: %s" % 
          [current_cloth, max_cloth, current_stamina, max_stamina, is_weak])
    return final_knockback

# 应用粘液效果
func apply_sticky_effect():
    _add_sticky_state()
    print("[状态机] 粘液造成的摩擦力衰减系数更新为: ", sticky_friction_factor)

# 进入虚弱状态的内部函数
func _add_weak_state():
    if is_weak:
        # 已在虚弱状态，仅重置计时器
        weak_recover_timer.start(3.0)
        return
    
    is_weak = true
    weak_knockback_factor = 0.95  # 初始衰减系数
    became_weak.emit()
    print("进入虚弱！")
    weak_recover_timer.start(3.0)  # 3秒后自动恢复

# 进入粘液状态的内部函数
func _add_sticky_state():
    if is_sticky:
        # 已在粘液状态，仅重置计时器
        sticky_recover_timer.start(5.0)
        print("粘液状态刷新")
        return
        
    is_sticky = true
    sticky_friction_factor = 0.2  # 摩擦力大幅降低
    became_sticky.emit()
    print("变得黏糊糊了！")
    sticky_recover_timer.start(5.0)  # 5秒后自动恢复

# 从虚弱状态恢复
func recover_from_weak():
    is_weak = false
    weak_knockback_factor = 0.95  # 恢复时重置衰减系数
    print("不再虚弱")

# 从粘液状态恢复
func recover_from_sticky():
    is_sticky = false
    sticky_friction_factor = 1.0  # 恢复正常摩擦力
    print("不再黏糊糊")