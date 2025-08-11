# TestAutoDiscoveryCommand.gd
# 自動検出テスト用のカスタムコマンド
class_name TestAutoDiscoveryCommand
extends BaseCustomCommand

func _init():
	command_name = "test_auto_discovery"
	description = "Test command for automatic discovery system"
	help_text = "test_auto_discovery message='Auto discovery works!'"
	
	set_parameter_info("message", "string", false, "Auto discovery works!", "Test message")

func execute(params: Dictionary, adv_system: Node) -> void:
	var message = get_param_value(params, "message", 0, "Auto discovery works!")
	
	log_command("TestAutoDiscovery executed: " + message)
	print("🎉 TestAutoDiscovery: ", message)
	
	emit_dynamic_signal("test_auto_discovery_executed", [message], adv_system)