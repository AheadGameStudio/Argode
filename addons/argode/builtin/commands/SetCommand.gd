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

## 引数検証（Stage 3共通基盤）
func validate_args(args: Dictionary) -> bool:
	var target = get_optional_arg(args, "arg0", "")
	if target.is_empty():
		log_error("変数名が指定されていません")
		return false
	return true

## コマンド中核処理（Stage 3共通基盤）
func execute_core(args: Dictionary) -> void:
	# VariableResolverが初期化されていない場合の保険
	if not variable_resolver and ArgodeSystem and ArgodeSystem.VariableManager:
		variable_resolver = ArgodeVariableResolver.new(ArgodeSystem.VariableManager)
		log_info("VariableResolver initialized")
	
	if not variable_resolver:
		log_error("VariableResolver not available")
		return
	
	# 引数を解析
	var target = get_required_arg(args, "arg0", "変数名")
	var value_expression = get_optional_arg(args, "arg1", "")
	
	if target == null:
		return  # エラーは既にログ出力済み
	
	log_debug("target='%s', expression='%s'" % [target, value_expression])
	
	# 値を直接処理して設定（SetCommandでは変数名と値が既に分離されている）
	var processed_value = variable_resolver._process_value(value_expression)
	variable_resolver.set_variable(target, processed_value)
	
	log_info("変数設定完了: %s = %s" % [target, str(processed_value)])


