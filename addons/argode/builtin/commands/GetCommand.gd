extends ArgodeCommandBase
class_name GetCommand

func _ready():
	command_class_name = "GetCommand"
	command_execute_name = "get"
	is_also_tag = true
	tag_name = "get"  # 変数表示用のタグとしても使用
	command_description = "変数の値を取得して表示します"
	command_help = "get variable_name"

func execute(args: Dictionary) -> void:
	var variable_name = args.get("arg0", "")
	
	if variable_name.is_empty():
		ArgodeSystem.log("❌ GetCommand: No variable name specified", 2)
		return
	
	# ArgodeVariableManagerから値を取得
	if ArgodeSystem and ArgodeSystem.has_method("get") and ArgodeSystem.get("VariableManager"):
		var variable_manager = ArgodeSystem.get("VariableManager")
		var value = variable_manager.get_variable(variable_name)
		
		if value != null:
			ArgodeSystem.log("📖 Variable retrieved: %s = %s" % [variable_name, str(value)])
		else:
			ArgodeSystem.log("⚠️ Variable not found: %s" % variable_name, 1)
	else:
		ArgodeSystem.log("❌ VariableManager not available", 2)