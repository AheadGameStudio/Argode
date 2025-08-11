# ScreenFlashShaderCommand.gd
# シェーダーベース screen_flash コマンド実装 (v2)
class_name ScreenFlashShaderCommand
extends BaseCustomCommand

func _init():
	command_name = "screen_flash"
	description = "Shader-based screen flash effect with high performance"
	help_text = "screen_flash white 0.2 | screen_flash color=red duration=0.5 intensity=0.8"
	
	# パラメータ情報を設定
	set_parameter_info("color", "string", false, "white", "Flash color (white, red, blue, etc.)")
	set_parameter_info("duration", "float", false, 0.3, "Flash duration in seconds")
	set_parameter_info("intensity", "float", false, 1.0, "Flash intensity (0.0-1.0)")

func has_visual_effect() -> bool:
	return true  # シェーダーベース視覚効果を持つ

func execute(params: Dictionary, adv_system: Node) -> void:
	var color_str = get_param_value(params, "color", 0, "white")
	var duration = get_param_value(params, "duration", 1, 0.3)
	var intensity = get_param_value(params, "intensity", 2, 1.0)
	
	var color = parse_color(str(color_str))
	
	log_command("Shader-based screen flash: color=" + str(color) + " duration=" + str(duration) + " intensity=" + str(intensity))
	
	# LayerManagerを通じてシェーダー効果を適用
	var layer_manager = adv_system.LayerManager
	if layer_manager:
		layer_manager.flash_screen(color, intensity, duration)
	else:
		log_error("LayerManager not found - falling back to legacy flash")
		# 動的シグナル発行（フォールバック）
		emit_screen_flash(color, duration, adv_system)

func execute_visual_effect(params: Dictionary, ui_node: Node) -> void:
	"""視覚効果の実行（UI統合モード）"""
	var color_str = get_param_value(params, "color", 0, "white") 
	var duration = get_param_value(params, "duration", 1, 0.3)
	var intensity = get_param_value(params, "intensity", 2, 1.0)
	
	var color = parse_color(str(color_str))
	
	log_command("Executing shader-based flash visual effect: color=" + str(color) + " duration=" + str(duration))
	
	# ArgodeSystemからLayerManagerを取得
	var tree = Engine.get_main_loop() as SceneTree
	var adv_system = tree.get_nodes_in_group("argode_system").front() if tree else null
	if not adv_system:
		adv_system = tree.get_first_node_in_group("argode_system") if tree else null
	if not adv_system:
		# フォールバック: 直接パスで取得
		if tree and tree.current_scene:
			adv_system = tree.current_scene.get_node("/root/ArgodeSystem")
	
	if adv_system and adv_system.LayerManager:
		# シェーダーベース実装を使用
		adv_system.LayerManager.flash_screen(color, intensity, duration)
	else:
		log_warning("LayerManager not available - using legacy ColorRect method")
		# フォールバック: 旧来のColorRectベース 
		flash_screen(ui_node, color, duration)

func validate_parameters(params: Dictionary) -> bool:
	var duration = get_param_value(params, "duration", 1, 0.3)
	var intensity = get_param_value(params, "intensity", 2, 1.0)
	
	if not (duration is float or duration is int):
		log_error("Duration must be a number")
		return false
	
	if duration <= 0:
		log_error("Duration must be positive")
		return false
	
	if not (intensity is float or intensity is int):
		log_error("Intensity must be a number")
		return false
		
	if intensity < 0.0 or intensity > 1.0:
		log_error("Intensity must be between 0.0 and 1.0")
		return false
	
	return true

# === シェーダーベース拡張メソッド ===

func flash_with_layer_targeting(target_layer: String, color: Color, intensity: float, duration: float, adv_system: Node):
	"""特定レイヤーにのみフラッシュを適用"""
	var layer_manager = adv_system.LayerManager
	if not layer_manager:
		log_error("LayerManager not available for layer targeting")
		return
	
	var params = {
		"flash_color": color,
		"flash_intensity": intensity,
		"flash_time": 1.0
	}
	
	var effect_id = layer_manager.apply_layer_shader(target_layer, "flash", params, duration)
	if effect_id > 0:
		log_command("Layer-targeted flash applied to: " + target_layer)