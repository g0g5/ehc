# 玩家角色控制脚本
# 继承自CharacterBody2D，提供物理运动功能
extends CharacterBody2D


# 引用玩家状态管理节点
@onready var state: PlayerState = $state


# 移动和跳跃参数配置
@export var MAX_SPEED := 600.0          # 最大移动速度
@export var JUMP_STRENGTH := -1300.0     # 跳跃力度（负值表示向上）
@export var DOUBLE_JUMP_STRENGTH := -1100.0  # 二段跳力度
@export var BOOST_STRENGTH := 1800.0      # BOOST水平推进力度
@export var ALPHA := 1000.0             # 加速度
@export var FRICTION := 1500            # 地面摩擦力
@export var JUMP_CANCEL_FORCE := 20000.0 # 跳跃中断时的下压力


# BOOST控制变量
@export var able_to_boost := true         # 是否允许BOOST
var has_boosted := false                  # 是否已经BOOST过
var current_input_direction := 0.0        # 当前帧的方向键输入（-1=左, 0=无, 1=右）


# 游戏状态变量
var game_over := false                   # 游戏是否结束


# 初始化函数
func _ready() -> void:
	# 注册玩家到 PlayerManager
	PlayerManager.register_player(self)

	# 连接游戏结束信号
	if state:
		state.gameover.connect(_on_state_gameover)


# 退出时注销
func _exit_tree() -> void:
	PlayerManager.unregister_player()


# 物理处理函数，每帧调用
func _physics_process(delta: float) -> void:
	# 如果游戏结束，禁用所有控制，等待重启输入
	if game_over:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		velocity.y += (JUMP_CANCEL_FORCE * 0.25) * delta
		move_and_slide()

		# 检测重启输入（持续检测）
		if Input.is_action_just_pressed("MOVE_JUMP"):
			GameManager.return_to_title()
		return
	
	# 处理重力效果
	if not is_on_floor():
		velocity += GameConstants.GRAVITY_VECTOR * delta
	else:
		has_boosted = false # 落地后重置BOOST状态

	# 处理跳跃输入
	var is_jump_pressed = Input.is_action_just_pressed("MOVE_JUMP")
	if is_jump_pressed:
		if is_on_floor(): # 一段跳逻辑
			velocity.y += JUMP_STRENGTH
		elif able_to_boost == true and not has_boosted: # BOOST逻辑
			# 根据当前输入方向进行水平BOOST
			if current_input_direction != 0:
				velocity.x += current_input_direction * BOOST_STRENGTH
				print("horizontal boost!")
			else:
				velocity.y = DOUBLE_JUMP_STRENGTH
				print("vertical boost!")
			has_boosted = true
	
	# 跳跃中断机制 - 松开跳跃键时施加向下的力
	if Input.is_action_just_released("MOVE_JUMP") and velocity.y < 0:
		velocity.y += JUMP_CANCEL_FORCE * delta

	# 记录当前方向键输入（用于BOOST方向判定）
	current_input_direction = Input.get_axis("MOVE_LEFT", "MOVE_RIGHT")

	# 处理水平移动
	var direction := current_input_direction
	
	# 根据状态调整摩擦力（粘液状态下摩擦力降低）
	var current_friction = FRICTION
	if state and state.is_sticky:
		current_friction *= 0.2
	
	# 应用移动逻辑
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * MAX_SPEED, ALPHA * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, current_friction * delta)
		
	# 执行移动
	move_and_slide()


# 击飞效果函数
# direction: 击飞方向向量，默认为 Vector2(-1, -0.4)（向左上方）
func apply_knockback(force: float, direction: Vector2 = Vector2(-1.0, -0.4)):
	# 直接设置速度实现击飞效果
	velocity = direction.normalized() * force
	print("玩家被击飞！力度：", force, " 方向：", direction)


# 游戏结束处理函数
func _on_state_gameover() -> void:
	game_over = true
	GameManager.game_over()
	print("游戏结束，玩家控制已禁用")
