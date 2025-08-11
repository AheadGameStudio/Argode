# WaitCommand.gd
# wait コマンド実装 - 指定時間待機する同期コマンド
class_name WaitCommand
extends BaseCustomCommand

func _init():
	command_name = "wait"
	description = "Wait for specified duration before continuing script execution"
	help_text = "wait duration=2.0 | wait 1.5"
	
	# パラメータ情報を設定
	set_parameter_info("duration", "float", true, 1.0, "Duration to wait in seconds")

func is_synchronous() -> bool:
	return true  # 同期処理が必要

func execute_internal_async(params: Dictionary, adv_system: Node) -> void:
	var duration = get_param_value(params, "duration", 0, 1.0)
	
	log_command("Wait requested: " + str(duration) + " seconds")
	
	if duration > 0:
		await adv_system.get_tree().create_timer(duration).timeout
		log_command("Wait completed")
	else:
		log_warning("Invalid duration: " + str(duration) + ", skipping wait")

func validate_parameters(params: Dictionary) -> bool:
	var duration = get_param_value(params, "duration", 0, 1.0)
	
	if not (duration is float or duration is int):
		log_error("Duration must be a number")
		return false
	
	if duration < 0:
		log_error("Duration cannot be negative")
		return false
	
	return true