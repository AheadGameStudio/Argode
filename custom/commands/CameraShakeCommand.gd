# CameraShakeCommand.gd
# camera_shake コマンド実装 - カメラシェイク効果
class_name CameraShakeCommand
extends "res://addons/argode/commands/BaseCustomCommand.gd"

func _init():
	command_name = "camera_shake"
	description = "Camera shake effect with customizable intensity and type"
	help_text = "camera_shake intensity=2.0 duration=0.5 type=both | camera_shake 3.0 1.0 horizontal"
	
	# パラメータ情報を設定
	set_parameter_info("intensity", "float", false, 1.0, "Shake intensity (0.0-10.0)")
	set_parameter_info("duration", "float", false, 0.5, "Shake duration in seconds")
	set_parameter_info("type", "string", false, "both", "Shake type: both, horizontal, vertical")

func has_visual_effect() -> bool:
	return true  # このコマンドは視覚効果を持つ

func execute(params: Dictionary, adv_system: Node) -> void:
	var intensity = get_param_value(params, "intensity", 0, 1.0)
	var duration = get_param_value(params, "duration", 1, 0.5)
	var shake_type = get_param_value(params, "type", 2, "both")
	
	log_command("Camera shake requested: intensity=" + str(intensity) + " duration=" + str(duration) + " type=" + shake_type)
	
	var effect_params = {
		"intensity": intensity,
		"duration": duration,
		"type": shake_type
	}
	
	# 動的シグナル発行
	emit_camera_effect("shake", effect_params, adv_system)

func execute_visual_effect(params: Dictionary, ui_node: Node) -> void:
	"""視覚効果の実行（AdvGameUIから呼び出される）"""
	var intensity = get_param_value(params, "intensity", 0, 1.0)
	var duration = get_param_value(params, "duration", 1, 0.5)
	var shake_type = get_param_value(params, "type", 2, "both")
	
	log_command("Executing camera shake visual effect: intensity=" + str(intensity) + " duration=" + str(duration) + " type=" + shake_type)
	
	# BaseCustomCommandのヘルパーメソッドを使用してUIノード全体を振動
	shake_node(ui_node, intensity, duration, shake_type)

func validate_parameters(params: Dictionary) -> bool:
	var intensity = get_param_value(params, "intensity", 0, 1.0)
	var duration = get_param_value(params, "duration", 1, 0.5)
	var shake_type = get_param_value(params, "type", 2, "both")
	
	if not (intensity is float or intensity is int):
		log_error("Intensity must be a number")
		return false
	
	if intensity < 0.0:
		log_error("Intensity cannot be negative")
		return false
	
	if not (duration is float or duration is int):
		log_error("Duration must be a number")
		return false
	
	if duration <= 0:
		log_error("Duration must be positive")
		return false
	
	if not shake_type in ["both", "horizontal", "vertical"]:
		log_error("Type must be 'both', 'horizontal', or 'vertical'")
		return false
	
	return true