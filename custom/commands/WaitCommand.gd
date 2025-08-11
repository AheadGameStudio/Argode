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
	print("⏳ [WaitCommand] execute_internal_async called with params: ", params)
	var duration = get_param_value(params, "duration", 0, 1.0)
	print("⏳ [WaitCommand] Parsed duration: ", duration, " (type: ", typeof(duration), ")")
	
	print("⏳ [WaitCommand] Wait starting: ", duration, " seconds")
	log_command("Wait requested: " + str(duration) + " seconds")
	
	if duration > 0:
		print("⏳ [WaitCommand] Creating timer for ", duration, " seconds...")
		await adv_system.get_tree().create_timer(duration).timeout
		print("✅ [WaitCommand] Wait completed after ", duration, " seconds")
		log_command("Wait completed")
	else:
		print("❌ [WaitCommand] Invalid duration: ", duration)
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