@tool
extends BaseCustomCommand

func _init():
	super._init()
	command_name = "set_dict"
	description = "辞書リテラルから変数に辞書を設定"
	help_text = "set_dict <variable_name> <dictionary_literal>\n辞書リテラルから変数に辞書を設定します。\n例: set_dict player {\"name\": \"主人公\", \"level\": 1}"

# コマンドを実行
func execute(parameters: Dictionary, adv_system: Node) -> void:
	var args = parameters.get("args", [])
	
	# argsが空の場合、_rawから解析
	if args.size() == 0:
		var raw_command = parameters.get("_raw", "")
		var parts = raw_command.split(" ", false, 2)  # 最大3つに分割
		if parts.size() >= 3:
			args = [parts[1], parts[2]]  # "set_dict"を除く
	
	# arg0, arg1からも取得を試す
	if args.size() < 2:
		var arg0 = parameters.get("arg0", "")
		var arg1 = parameters.get("arg1", "")
		if not arg0.is_empty() and not arg1.is_empty():
			args = [arg0, arg1]
	
	print("🎯 [set_dict] パラメータ: ", parameters)
	print("🎯 [set_dict] 解析後args: ", args)
	
	if args.size() < 2:
		log_error("引数が不足しています。使用法: set_dict <variable_name> <dictionary_literal>")
		return
	
	var var_name = args[0]
	var dict_literal = args[1]
	
	# VariableManagerの辞書設定メソッドを使用
	if adv_system and adv_system.VariableManager:
		adv_system.VariableManager.set_dictionary(var_name, dict_literal)
		log_command("Dictionary set: " + var_name + " = " + dict_literal)
	else:
		log_error("VariableManagerが利用できません")
