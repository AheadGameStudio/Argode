# UISlideCommand.gd
# UI要素スライドアニメーションコマンド
class_name UISlideCommand
extends "res://addons/argode/commands/BaseCustomCommand.gd"

func _init():
	command_name = "ui_slide"
	description = "Slide UI elements in/out with various directions"
	help_text = "ui_slide in direction=up duration=0.7 | ui_slide out direction=left duration=1.0"
	
	# パラメータ情報を設定
	set_parameter_info("action", "string", true, "in", "Slide action (in, out)")
	set_parameter_info("direction", "string", false, "up", "Slide direction (up, down, left, right)")
	set_parameter_info("duration", "float", false, 0.7, "Animation duration")
	set_parameter_info("distance", "float", false, 100.0, "Slide distance in pixels")

func has_visual_effect() -> bool:
	return true

func execute(params: Dictionary, adv_system: Node) -> void:
	var action = get_param_value(params, "action", 0, "in")
	var direction = get_param_value(params, "direction", 1, "up")
	var duration = get_param_value(params, "duration", 2, 0.7)
	
	log_command("UI slide: action=" + str(action) + " direction=" + str(direction) + " duration=" + str(duration))
	
	# 動的シグナル発行
	emit_dynamic_signal("ui_slide_requested", [action, direction, duration], adv_system)

func execute_visual_effect(params: Dictionary, ui_node: Node) -> void:
	"""UIスライドアニメーション効果の実行"""
	var action = get_param_value(params, "action", 0, "in")
	var direction = get_param_value(params, "direction", 1, "up")
	var duration = get_param_value(params, "duration", 2, 0.7)
	var distance = get_param_value(params, "distance", 3, 100.0)
	
	log_command("Executing UI slide: " + str(action) + " " + str(direction))
	
	# メッセージボックスを見つける
	var message_box = _find_ui_element(ui_node, "MessageBox")
	if not message_box:
		log_error("MessageBox not found for UI slide animation")
		return
	
	# スライドアニメーション実行
	match str(action).to_lower():
		"in":
			_slide_in(message_box, str(direction), duration, distance)
		"out":
			_slide_out(message_box, str(direction), duration, distance)
		_:
			log_error("Unknown slide action: " + str(action))

func _find_ui_element(ui_node: Node, element_name: String) -> Node:
	"""UI要素を名前で検索"""
	# 直接の子から探す
	var direct_child = ui_node.get_node_or_null(element_name)
	if direct_child:
		return direct_child
	
	# 再帰的に探す
	return _find_ui_element_recursive(ui_node, element_name)

func _find_ui_element_recursive(node: Node, element_name: String) -> Node:
	"""再帰的にUI要素を探す"""
	if node.name == element_name:
		return node
	
	for child in node.get_children():
		var found = _find_ui_element_recursive(child, element_name)
		if found:
			return found
	
	return null

func _slide_in(ui_element: Node, direction: String, duration: float, distance: float):
	"""スライドイン効果"""
	if not ui_element:
		return
	
	var original_position = ui_element.position
	var start_offset = _get_direction_offset(direction, distance)
	
	# 開始位置を設定（画面外）
	ui_element.position = original_position + start_offset
	ui_element.modulate.a = 0.0
	
	# スライドインアニメーション
	var tween = ui_element.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ui_element, "position", original_position, duration)
	tween.tween_property(ui_element, "modulate:a", 1.0, duration * 0.8)
	
	print("🎬 UI slide in (", direction, ") started for ", duration, "s")

func _slide_out(ui_element: Node, direction: String, duration: float, distance: float):
	"""スライドアウト効果"""
	if not ui_element:
		return
	
	var original_position = ui_element.position
	var end_offset = _get_direction_offset(direction, distance)
	
	# スライドアウトアニメーション
	var tween = ui_element.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ui_element, "position", original_position + end_offset, duration)
	tween.tween_property(ui_element, "modulate:a", 0.0, duration * 0.8)
	
	# アニメーション完了後に元の位置に戻す
	tween.tween_callback(func():
		ui_element.position = original_position
		ui_element.modulate.a = 1.0
	)
	
	print("🎬 UI slide out (", direction, ") started for ", duration, "s")

func _get_direction_offset(direction: String, distance: float) -> Vector2:
	"""方向に応じたオフセットベクトルを取得"""
	match direction.to_lower():
		"up":
			return Vector2(0, -distance)
		"down":
			return Vector2(0, distance)
		"left":
			return Vector2(-distance, 0)
		"right":
			return Vector2(distance, 0)
		_:
			push_warning("Unknown slide direction: " + direction + ", using 'up'")
			return Vector2(0, -distance)

func validate_parameters(params: Dictionary) -> bool:
	var action = get_param_value(params, "action", 0, "in")
	var direction = get_param_value(params, "direction", 1, "up")
	var duration = get_param_value(params, "duration", 2, 0.7)
	var distance = get_param_value(params, "distance", 3, 100.0)
	
	# アクションチェック
	var valid_actions = ["in", "out"]
	if str(action).to_lower() not in valid_actions:
		log_error("Invalid action. Must be one of: " + str(valid_actions))
		return false
	
	# 方向チェック
	var valid_directions = ["up", "down", "left", "right"]
	if str(direction).to_lower() not in valid_directions:
		log_error("Invalid direction. Must be one of: " + str(valid_directions))
		return false
	
	# 数値チェック
	if not (duration is float or duration is int) or duration <= 0:
		log_error("Duration must be a positive number")
		return false
		
	if not (distance is float or distance is int) or distance < 0:
		log_error("Distance must be a non-negative number")
		return false
	
	return true