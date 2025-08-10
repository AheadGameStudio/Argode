# ParticleEffectCommand.gd
# particles コマンド実装 - パーティクル効果
class_name ParticleEffectCommand
extends "res://addons/argode/commands/BaseCustomCommand.gd"

func _init():
	command_name = "particles"
	description = "Particle effects with various types and parameters"
	help_text = "particles rain intensity=high duration=5.0 | particles explosion position=center"
	
	# パラメータ情報を設定
	set_parameter_info("type", "string", false, "sparkle", "Particle type: sparkle, rain, explosion, snow, etc.")
	set_parameter_info("intensity", "string", false, "medium", "Effect intensity: low, medium, high")
	set_parameter_info("duration", "float", false, 3.0, "Effect duration in seconds")
	set_parameter_info("position", "string", false, "center", "Effect position: center, left, right, top, bottom")

func execute(params: Dictionary, adv_system: Node) -> void:
	var particle_type = get_param_value(params, "type", 0, "sparkle")
	
	var effect_params = {}
	
	# パラメータを収集
	for key in params.keys():
		var key_str = str(key)
		if not key_str.begins_with("arg") and not key_str.is_valid_int() and key != "_count" and key != "_raw":
			effect_params[key] = params[key]
	
	# typeが位置パラメータで指定された場合
	if particle_type != "sparkle":  # デフォルト値と異なる場合
		effect_params["type"] = particle_type
	
	log_command("Particle effect requested: " + particle_type + " params: " + str(effect_params))
	
	# 動的シグナル発行
	emit_particle_effect(particle_type, effect_params, adv_system)

func validate_parameters(params: Dictionary) -> bool:
	var duration = get_param_value(params, "duration", -1, 3.0)
	
	if duration != 3.0:  # デフォルト値と異なる場合のみチェック
		if not (duration is float or duration is int):
			log_error("Duration must be a number")
			return false
		
		if duration <= 0:
			log_error("Duration must be positive")
			return false
	
	var intensity = get_param_value(params, "intensity", -1, "medium")
	if intensity != "medium" and not intensity in ["low", "medium", "high"]:
		log_error("Intensity must be 'low', 'medium', or 'high'")
		return false
	
	return true