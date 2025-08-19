extends ArgodeCommandBase
class_name SetCommand

var variable_resolver: ArgodeVariableResolver

func _ready():
	command_class_name = "SetCommand"
	command_execute_name = "set"
	is_define_command = false  # 通常のコマンドとして実行する
	command_description = "変数に値を設定します"
	command_help = "set variable_name = value または set variable_name += value"
	
	# VariableResolverを初期化
	if ArgodeSystem and ArgodeSystem.VariableManager:
		variable_resolver = ArgodeVariableResolver.new(ArgodeSystem.VariableManager)

func execute(args: Dictionary) -> void:
	# デバッグ：引数の詳細をログ出力
	ArgodeSystem.log("🔍 SetCommand execute called with args: %s" % str(args))
	
	# VariableResolverが初期化されていない場合の保険
	if not variable_resolver and ArgodeSystem and ArgodeSystem.VariableManager:
		variable_resolver = ArgodeVariableResolver.new(ArgodeSystem.VariableManager)
		ArgodeSystem.log("🔧 SetCommand: VariableResolver initialized")
	
	if not variable_resolver:
		ArgodeSystem.log("❌ SetCommand: VariableResolver not available", 2)
		return
	
	# 引数を解析
	var target = args.get("arg0", "")
	var value_expression = args.get("arg1", "")
	
	ArgodeSystem.log("🔍 SetCommand: target='%s', expression='%s'" % [target, value_expression])
	
	if target.is_empty():
		ArgodeSystem.log("❌ SetCommand: No target variable specified", 2)
		return
	
	# 値を直接処理して設定（SetCommandでは変数名と値が既に分離されている）
	var processed_value = variable_resolver._process_value(value_expression)
	variable_resolver.set_variable(target, processed_value)
	
	ArgodeSystem.log("✅ Variable set: %s = %s" % [target, str(processed_value)])


