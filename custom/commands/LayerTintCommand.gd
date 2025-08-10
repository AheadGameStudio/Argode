# LayerTintCommand.gd
# レイヤー別色調調整コマンド (シェーダーベース)
class_name LayerTintCommand
extends "res://addons/argode/commands/BaseCustomCommand.gd"

func _init():
	command_name = "layer_tint"
	description = "Apply tint effect to specific layer using shaders"
	help_text = "layer_tint background red 0.3 | layer_tint character blue intensity=0.5 duration=1.0"
	
	# パラメータ情報を設定
	set_parameter_info("layer", "string", true, "background", "Target layer (background, character, ui)")
	set_parameter_info("color", "string", true, "red", "Tint color")
	set_parameter_info("intensity", "float", false, 0.5, "Tint intensity (0.0-1.0)")
	set_parameter_info("duration", "float", false, 0.0, "Effect duration (0=permanent)")
	set_parameter_info("blend_mode", "int", false, 0, "Blend mode (0=Mix, 1=Add, 2=Multiply, 3=Overlay)")

func has_visual_effect() -> bool:
	return true

func execute(params: Dictionary, adv_system: Node) -> void:
	var layer_name = get_param_value(params, "layer", 0, "background") 
	var color_str = get_param_value(params, "color", 1, "red")
	var intensity = get_param_value(params, "intensity", 2, 0.5)
	var duration = get_param_value(params, "duration", 3, 0.0)
	var blend_mode = get_param_value(params, "blend_mode", 4, 0)
	
	var color = parse_color(str(color_str))
	
	log_command("Layer tint: layer=" + str(layer_name) + " color=" + str(color) + " intensity=" + str(intensity))
	
	# LayerManagerを通じてシェーダー効果を適用
	var layer_manager = adv_system.LayerManager
	if layer_manager:
		var params_dict = {
			"tint_color": color,
			"tint_intensity": intensity,
			"blend_mode": blend_mode
		}
		
		var effect_id = layer_manager.apply_layer_shader(str(layer_name), "tint", params_dict, duration)
		
		if effect_id > 0:
			log_command("Tint effect applied to layer: " + str(layer_name) + " (effect_id: " + str(effect_id) + ")")
		else:
			log_error("Failed to apply tint effect to layer: " + str(layer_name))
	else:
		log_error("LayerManager not found")

func validate_parameters(params: Dictionary) -> bool:
	var layer_name = get_param_value(params, "layer", 0, "background")
	var intensity = get_param_value(params, "intensity", 2, 0.5)
	var duration = get_param_value(params, "duration", 3, 0.0)
	var blend_mode = get_param_value(params, "blend_mode", 4, 0)
	
	# レイヤー名チェック
	var valid_layers = ["background", "character", "ui"]
	if str(layer_name) not in valid_layers:
		log_error("Invalid layer name. Must be one of: " + str(valid_layers))
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
	
	# ブレンドモードチェック
	if not (blend_mode is int):
		log_error("Blend mode must be an integer")
		return false
		
	if blend_mode < 0 or blend_mode > 3:
		log_error("Blend mode must be 0-3")
		return false
	
	return true