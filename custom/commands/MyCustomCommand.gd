# MyCustomCommand.gd
# プロジェクト側でのカスタムコマンド実装例
class_name MyCustomCommand
extends BaseCustomCommand

func _init():
	command_name = "my_effect"
	description = "Custom visual effect command example"
	help_text = "my_effect type=sparkle intensity=5.0 duration=2.0"
	
	# パラメータ情報を設定
	set_parameter_info("type", "string", false, "sparkle", "Effect type: sparkle, glow, pulse")
	set_parameter_info("intensity", "float", false, 5.0, "Effect intensity (0.0-10.0)")
	set_parameter_info("duration", "float", false, 2.0, "Effect duration in seconds")

func execute(params: Dictionary, adv_system: Node) -> void:
	var effect_type = get_param_value(params, "type", 0, "sparkle")
	var intensity = get_param_value(params, "intensity", 1, 5.0)
	var duration = get_param_value(params, "duration", 2, 2.0)
	
	log_command("Custom effect requested: " + effect_type + " intensity=" + str(intensity) + " duration=" + str(duration))
	
	match effect_type:
		"sparkle":
			_create_sparkle_effect(intensity, duration, adv_system)
		"glow":
			_create_glow_effect(intensity, duration, adv_system)
		"pulse":
			_create_pulse_effect(intensity, duration, adv_system)
		_:
			log_warning("Unknown effect type: " + effect_type)

func _create_sparkle_effect(intensity: float, duration: float, adv_system: Node):
	"""キラキラエフェクト作成"""
	log_command("Creating sparkle effect...")
	
	# 実際のエフェクト処理をここに実装
	# 例：パーティクルシステムの操作、シェーダーパラメータの変更など
	
	# AdvGameUIにシグナルを送って視覚効果を実装
	if adv_system and adv_system.has_method("get_tree"):
		var main_scene = adv_system.get_tree().current_scene
		if main_scene and main_scene.has_method("show_sparkle_effect"):
			main_scene.show_sparkle_effect(intensity, duration)
		else:
			log_warning("Main scene does not have show_sparkle_effect method")

func _create_glow_effect(intensity: float, duration: float, adv_system: Node):
	"""グローエフェクト作成"""
	log_command("Creating glow effect...")
	
	# グローエフェクト実装例
	if adv_system and adv_system.has_method("get_tree"):
		var main_scene = adv_system.get_tree().current_scene
		if main_scene and main_scene.has_method("show_glow_effect"):
			main_scene.show_glow_effect(intensity, duration)

func _create_pulse_effect(intensity: float, duration: float, adv_system: Node):
	"""パルスエフェクト作成"""
	log_command("Creating pulse effect...")
	
	# パルスエフェクト実装例
	if adv_system and adv_system.has_method("get_tree"):
		var main_scene = adv_system.get_tree().current_scene
		if main_scene and main_scene.has_method("show_pulse_effect"):
			main_scene.show_pulse_effect(intensity, duration)

func validate_parameters(params: Dictionary) -> bool:
	var intensity = get_param_value(params, "intensity", 1, 5.0)
	var duration = get_param_value(params, "duration", 2, 2.0)
	
	if not (intensity is float or intensity is int):
		log_error("Intensity must be a number")
		return false
	
	if intensity < 0.0 or intensity > 10.0:
		log_error("Intensity must be between 0.0 and 10.0")
		return false
	
	if not (duration is float or duration is int):
		log_error("Duration must be a number")
		return false
	
	if duration <= 0:
		log_error("Duration must be positive")
		return false
	
	return true