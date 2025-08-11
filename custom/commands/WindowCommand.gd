# WindowCommand.gd
# window コマンド実装 - ウィンドウ操作コマンド
class_name WindowCommand
extends BaseCustomCommand

func _init():
	command_name = "window"
	description = "Window operations including shake, fullscreen, minimize"
	help_text = "window shake intensity=5.0 duration=0.5 | window fullscreen true | window minimize"
	
	# パラメータ情報を設定
	set_parameter_info("action", "string", false, "shake", "Window action: shake, fullscreen, minimize")
	set_parameter_info("intensity", "float", false, 5.0, "Shake intensity (for shake action)")
	set_parameter_info("duration", "float", false, 0.5, "Shake duration (for shake action)")
	set_parameter_info("enable", "bool", false, true, "Enable/disable fullscreen")

func has_visual_effect() -> bool:
	return true  # このコマンドは視覚効果を持つ

func execute(params: Dictionary, adv_system: Node) -> void:
	# アクション判定：位置パラメータまたはキーワードパラメータから推定
	var action = get_param_value(params, "action", 0, "")
	
	# key=value形式でアクションが明示されていない場合は、パラメータから推定
	if action.is_empty():
		if params.has("intensity") or params.has("duration"):
			action = "shake"  # shake特有のパラメータがある場合
		elif params.has("enable") or params.has("fullscreen"):
			action = "fullscreen"  # fullscreen特有のパラメータがある場合
	
	log_command("Window action determined: '" + action + "'")
	
	match action:
		"shake":
			_handle_shake(params, adv_system)
		"minimize":
			_handle_minimize(params, adv_system)
		"fullscreen":
			_handle_fullscreen(params, adv_system)
		_:
			log_warning("Unknown window action: " + action)

func execute_visual_effect(params: Dictionary, ui_node: Node) -> void:
	"""視覚効果の実行（AdvGameUIから呼び出される）"""
	var action = get_param_value(params, "action", 0, "")
	
	# パラメータから推定
	if action.is_empty():
		if params.has("intensity") or params.has("duration"):
			action = "shake"
	
	match action:
		"shake":
			_execute_window_shake_visual(params, ui_node)
		_:
			log_command("No visual effect for action: " + action)

func _handle_shake(params: Dictionary, adv_system: Node):
	"""ウィンドウシェイク処理"""
	var intensity = get_param_value(params, "intensity", 1, 5.0)
	var duration = get_param_value(params, "duration", 2, 0.5)
	
	log_command("Window shake requested: intensity=" + str(intensity) + " duration=" + str(duration))
	
	# 動的シグナル発行
	emit_window_shake(intensity, duration, adv_system)

func _handle_minimize(_params: Dictionary, _adv_system: Node):
	"""ウィンドウ最小化処理"""
	log_command("Window minimize requested")
	
	# Godot 4.x での正しいAPI使用
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)

func _handle_fullscreen(params: Dictionary, _adv_system: Node):
	"""フルスクリーン切り替え処理"""
	var enable = get_param_value(params, "enable", 1, true)
	
	log_command("Fullscreen toggle requested: " + str(enable))
	
	if enable:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func validate_parameters(params: Dictionary) -> bool:
	var action = get_param_value(params, "action", 0, "shake")
	
	match action:
		"shake":
			var intensity = get_param_value(params, "intensity", 1, 5.0)
			var duration = get_param_value(params, "duration", 2, 0.5)
			
			if not (intensity is float or intensity is int) or intensity < 0:
				log_error("Intensity must be a positive number")
				return false
			
			if not (duration is float or duration is int) or duration <= 0:
				log_error("Duration must be a positive number")
				return false
		
		"fullscreen":
			var enable = get_param_value(params, "enable", 1, true)
			if not enable is bool:
				log_error("Enable parameter must be a boolean")
				return false
	
	return true

func _execute_window_shake_visual(params: Dictionary, ui_node: Node):
	"""ウィンドウシェイクの視覚効果実装"""
	var intensity = get_param_value(params, "intensity", 1, 5.0)
	var duration = get_param_value(params, "duration", 2, 0.5)
	
	log_command("Executing window shake visual effect: intensity=" + str(intensity) + " duration=" + str(duration))
	
	var window = get_window_from_ui(ui_node)
	if not window:
		log_warning("Cannot get window for shake effect")
		return
	
	var original_pos = window.position
	var tween = create_tween_for_node(ui_node)
	if not tween:
		return
	
	var shake_steps = int(duration * 30)  # 30fps相当
	
	for i in range(shake_steps):
		var shake_offset = Vector2i(
			randi_range(-int(intensity), int(intensity)),
			randi_range(-int(intensity), int(intensity))
		)
		var target_pos = original_pos + shake_offset
		tween.tween_method(
			func(pos): window.position = pos,
			window.position, target_pos, 
			duration / shake_steps
		)
	
	# 元の位置に戻す
	tween.tween_method(
		func(pos): window.position = pos,
		window.position, original_pos,
		0.1
	)