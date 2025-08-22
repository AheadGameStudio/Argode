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
	var target = get_optional_arg(args, "0", "")
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
	var target = get_required_arg(args, "0", "変数名")
	var value_expression = get_optional_arg(args, "1", "")
	
	if target == null:
		return  # エラーは既にログ出力済み
	
	log_debug("target='%s', expression='%s'" % [target, value_expression])
	
	# value_expressionを文字列として扱う
	var value_expr_str = str(value_expression)
	
	# 複合演算子の処理（+= 10, -= 5等）
	if value_expr_str.begins_with("+=") or value_expr_str.begins_with("-=") or value_expr_str.begins_with("*=") or value_expr_str.begins_with("/="):
		# 演算子と値を分離
		var operator = value_expr_str.substr(0, 2)  # +=, -=, *=, /=
		var operand_str = value_expr_str.substr(2).strip_edges()
		
		# 現在の値を取得
		var current_value = variable_resolver.variable_manager.get_variable(target)
		if current_value == null:
			current_value = 0  # デフォルト値
		
		# 演算値を処理
		var operand = variable_resolver._process_value(operand_str)
		
		# 算術演算実行
		var result
		match operator:
			"+=":
				result = current_value + operand
			"-=":
				result = current_value - operand
			"*=":
				result = current_value * operand
			"/=":
				result = current_value / operand if operand != 0 else current_value
			_:
				result = current_value
		
		variable_resolver.set_variable(target, result)
		log_info("変数設定完了: %s = %s" % [target, str(result)])
	else:
		# 通常の代入処理
		var processed_value = variable_resolver._process_value(value_expr_str)
		variable_resolver.set_variable(target, processed_value)
		log_info("変数設定完了: %s = %s" % [target, str(processed_value)])


