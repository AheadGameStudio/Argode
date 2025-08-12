@tool
extends BaseCustomCommand

func _init():
	super._init()
	command_name = "set_array"
	description = "配列リテラルから変数に配列を設定"
	help_text = "set_array <variable_name> <array_literal>\n配列リテラルから変数に配列を設定します。\n例: set_array inventory [\"sword\", \"potion\", \"key\"]"

# コマンドを実行
func execute(parameters: Dictionary, adv_system: Node) -> void:
	var args = parameters.get("args", [])
	
	# argsが空の場合、_rawから解析
	if args.size() == 0:
		var raw_command = parameters.get("_raw", "")
		var parts = raw_command.split(" ", false, 2)  # 最大3つに分割
		if parts.size() >= 3:
			args = [parts[1], parts[2]]  # "set_array"を除く
	
	# arg0, arg1からも取得を試す
	if args.size() < 2:
		var arg0 = parameters.get("arg0", "")
		var arg1 = parameters.get("arg1", "")
		if not arg0.is_empty() and not arg1.is_empty():
			args = [arg0, arg1]
	
	print("🎯 [set_array] パラメータ: ", parameters)
	print("🎯 [set_array] 解析後args: ", args)
	
	if args.size() < 2:
		log_error("引数が不足しています。使用法: set_array <variable_name> <array_literal>")
		return
	
	var var_name = args[0]
	var array_literal = args[1]
	
	# VariableManagerの配列設定メソッドを使用
	if adv_system and adv_system.VariableManager:
		adv_system.VariableManager.set_array(var_name, array_literal)
		log_command("Array set: " + var_name + " = " + array_literal)
	else:
		log_error("VariableManagerが利用できません")
