extends CharacterBody2D

var h_speed := 120
var v_speed := 100
var direction := Vector2.RIGHT
var time_elapsed := 0.0  # 添加时间追踪变量
var bullet_scene: PackedScene = preload("res://scenes/entities/wc_bullets.tscn")
var bullet_speed = 300.0

func set_H_direction():
	if direction.x < 0:
		direction.x = 1
	else:
		direction.x = -1


func set_V_direction(v_dir: float):
	direction.y = v_dir
	print(direction.y)


func _ready() -> void:
	# 初始化方向
	direction = Vector2(-1, 0)


func _physics_process(delta: float) -> void:
	# 使用时间来控制y轴方向的循环变化
	time_elapsed += delta
	# 使用正弦函数创建平滑的上下循环，周期为4秒
	direction.y = sin(time_elapsed * PI / 2)
	
	# 应用速度
	velocity.x = move_toward(velocity.x, direction.x * h_speed, h_speed * delta)
	velocity.y = move_toward(velocity.y, direction.y * v_speed, v_speed * delta)
	
	move_and_slide()


func _on_hitbox_body_entered(body) -> void:
	print(body)
	# 检查是否是玩家
	if body.is_in_group('Player'):
		print("玩家被击飞！")

		# 获取玩家状态管理器
		var player_state = body.get_node('state')
		if player_state and player_state.has_method('take_damage'):
			# 调用状态机处理伤害，获得击飞力度
			var force = player_state.take_damage(1, 20, 1000)
			# 应用击飞效果
			if body.has_method("apply_knockback"):
				body.apply_knockback(force)
	else:
		pass

	if body.is_class('TileMapLayer'):
		print('发现碰撞', body)
		set_H_direction()



func _on_fire_cooldown_timeout() -> void:
	var directions = [
		Vector2.RIGHT,                    # 0°
		Vector2.LEFT,                   # 180°
		Vector2.DOWN,                  # 270°
	]

	for dir in directions:
		var bullet = bullet_scene.instantiate()
		bullet.global_position = global_position
		bullet.direction = dir
		bullet.speed = bullet_speed
		get_tree().current_scene.add_child(bullet)
