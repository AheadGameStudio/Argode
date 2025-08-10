# AsyncEffectCommand.gd
# 同期処理（await）が必要なコマンド例
class_name AsyncEffectCommand
extends "res://addons/argode/commands/BaseCustomCommand.gd"

func _init():
	command_name = "async_effect"
	description = "Asynchronous effect command that waits"
	help_text = "async_effect duration=2.0"
	
	set_parameter_info("duration", "float", false, 2.0, "Wait duration in seconds")

# 同期処理が必要であることを示す
func is_synchronous() -> bool:
	return true

func execute(params: Dictionary, adv_system: Node) -> void:
	# 同期コマンドでは通常のexecuteは呼ばれない
	log_warning("AsyncEffectCommand: execute() called instead of execute_async()")

func execute_internal_async(params: Dictionary, adv_system: Node) -> void:
	var duration = get_param_value(params, "duration", 0, 2.0)
	
	log_command("AsyncEffect starting: waiting for " + str(duration) + " seconds")
	print("⏳ AsyncEffect: Starting async operation for ", duration, " seconds")
	
	# 実際の非同期処理
	if adv_system and adv_system.has_method("get_tree"):
		var tree = adv_system.get_tree()
		if tree:
			await tree.create_timer(duration).timeout
			print("✅ AsyncEffect: Async operation completed after ", duration, " seconds")
			
			# 完了シグナル発行
			emit_dynamic_signal("async_effect_completed", [duration], adv_system)

func validate_parameters(params: Dictionary) -> bool:
	var duration = get_param_value(params, "duration", 0, 2.0)
	
	if not (duration is float or duration is int):
		log_error("Duration must be a number")
		return false
	
	if duration <= 0:
		log_error("Duration must be positive")
		return false
	
	return true