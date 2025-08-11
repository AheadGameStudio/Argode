# HelloWorldCommand.gd
# Callable形式での登録例：シンプルなコマンド
class_name HelloWorldCommand
extends BaseCustomCommand

func _init():
	command_name = "hello_world"
	description = "Simple hello world command example"
	help_text = "hello_world message='Hello, World!'"
	
	set_parameter_info("message", "string", false, "Hello, World!", "Message to display")

func execute(params: Dictionary, adv_system: Node) -> void:
	var message = get_param_value(params, "message", 0, "Hello, World!")
	
	log_command("HelloWorld command executed with message: " + message)
	print("📢 HelloWorld Command: ", message)
	
	# 動的シグナル発行例
	emit_dynamic_signal("hello_world_executed", [message], adv_system)

func validate_parameters(params: Dictionary) -> bool:
	var message = get_param_value(params, "message", 0, "Hello, World!")
	if not message is String:
		log_error("Message parameter must be a string")
		return false
	return true