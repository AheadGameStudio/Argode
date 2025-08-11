# ScreenTintCommand.gd
# スクリーン全体の色調調整コマンド (シェーダーベース)
class_name ScreenTintCommand
extends BaseCustomCommand

func _init():
	command_name = "tint"
	description = "Apply tint effect to entire screen using shaders"
	help_text = "tint red intensity=0.5 duration=1.0 | tint reset | tint blue intensity=0.3"
	
	# パラメータ情報を設定
	set_parameter_info("color", "string", true, "red", "Tint color (red, blue, green, yellow, reset)")
	set_parameter_info("intensity", "float", false, 0.5, "Tint intensity (0.0-1.0)")
	set_parameter_info("duration", "float", false, 0.0, "Transition duration (0=instant)")
	set_parameter_info("blend_mode", "int", false, 0, "Blend mode (0=Mix, 1=Add, 2=Multiply)")

func has_visual_effect() -> bool:
	return true

func execute(params: Dictionary, adv_system: Node) -> void:
	var color_str = get_param_value(params, "color", 0, "red")
	var intensity = get_param_value(params, "intensity", 1, 0.5)
	var duration = get_param_value(params, "duration", 2, 0.0)
	
	log_command("Screen tint: color=" + str(color_str) + " intensity=" + str(intensity) + " duration=" + str(duration))
	
	# LayerManagerを通じてシェーダー効果を適用
	var layer_manager = adv_system.LayerManager
	if layer_manager:
		if str(color_str).to_lower() == "reset":
			# 全効果をクリア
			layer_manager.clear_all_shader_effects()
			log_command("Screen tint reset")
		else:
			_apply_screen_tint(layer_manager, color_str, intensity, duration)
	else:
		log_error("LayerManager not found")

func execute_visual_effect(params: Dictionary, _ui_node: Node) -> void:
	"""色調調整視覚効果の実行"""
	var color_str = get_param_value(params, "color", 0, "red")
	var intensity = get_param_value(params, "intensity", 1, 0.5)
	var duration = get_param_value(params, "duration", 2, 0.0)
	
	log_command("Executing screen tint effect: " + str(color_str))
	
	# ArgodeSystemからLayerManagerを取得
	var tree = Engine.get_main_loop() as SceneTree
	var adv_system = tree.get_nodes_in_group("argode_system").front() if tree else null
	if not adv_system:
		adv_system = tree.get_first_node_in_group("argode_system") if tree else null
	if not adv_system:
		if tree and tree.current_scene:
			adv_system = tree.current_scene.get_node("/root/ArgodeSystem")
	
	if adv_system and adv_system.LayerManager:
		if str(color_str).to_lower() == "reset":
			adv_system.LayerManager.clear_all_shader_effects()
			log_command("Screen tint reset via visual effect")
		else:
			_apply_screen_tint(adv_system.LayerManager, color_str, intensity, duration)
	else:
		log_error("LayerManager not available for screen tint")

func _apply_screen_tint(layer_manager: Node, color_str: String, intensity: float, duration: float):
	"""スクリーン色調調整を適用"""
	var color = parse_color(str(color_str))
	var blend_mode = 0  # Mix mode
	
	var params = {
		"tint_color": color,
		"tint_intensity": intensity,
		"blend_mode": blend_mode
	}
	
	var effect_id = layer_manager.apply_screen_shader("tint", params, duration)
	
	if effect_id > 0:
		log_command("Screen tint applied: " + str(color) + " intensity=" + str(intensity))
		
		# グラデーション効果（0から目標値へ）
		if duration > 0.0:
			var effects = layer_manager.shader_effect_manager.active_effects
			var overlay = layer_manager.shader_effect_manager._get_or_create_screen_overlay()
			if overlay and overlay in effects:
				for controller in effects[overlay]:
					if controller.effect_id == effect_id:
						controller.animate_parameter("tint_intensity", 0.0, intensity, duration)
						break
	else:
		log_error("Failed to apply screen tint effect")

func validate_parameters(params: Dictionary) -> bool:
	var color_str = get_param_value(params, "color", 0, "red")
	var intensity = get_param_value(params, "intensity", 1, 0.5)
	var duration = get_param_value(params, "duration", 2, 0.0)
	
	# "reset"は特別なキーワード
	if str(color_str).to_lower() == "reset":
		return true
	
	# 色名チェック
	var valid_colors = ["red", "green", "blue", "yellow", "cyan", "magenta", "white", "black", "orange", "purple"]
	if str(color_str).to_lower() not in valid_colors:
		# 16進数カラーかチェック（#RRGGBB形式）
		if not str(color_str).begins_with("#") or str(color_str).length() != 7:
			log_error("Invalid color. Must be one of: " + str(valid_colors) + " or #RRGGBB format")
			return false
	
	# 強度チェック
	if not (intensity is float or intensity is int):
		log_error("Intensity must be a number")
		return false
		
	if intensity < 0.0 or intensity > 1.0:
		log_error("Intensity must be between 0.0 and 1.0")
		return false
	
	# 持続時間チェック
	if not (duration is float or duration is int):
		log_error("Duration must be a number")
		return false
		
	if duration < 0:
		log_error("Duration must be non-negative")
		return false
	
	return true