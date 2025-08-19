extends ArgodeCommandBase
class_name SetCommand

func _ready():
	command_class_name = "SetCommand"
	command_execute_name = "set"
	is_define_command = false  # 通常のコマンドとして実行する
	command_description = "変数に値を設定します"
	command_help = "set variable_name = value または set variable_name += value"

func execute(args: Dictionary) -> void:
	# setコマンドの引数解析
	# 例: set player.name = "テスト" または set player.affection += 10
	
	# デバッグ：引数の内容を詳細にログ出力
	ArgodeSystem.log("🔍 SetCommand args: %s" % str(args))
	
	var target = args.get("target", "")
	var value_arg = ""
	
	# 引数からターゲット変数と値を抽出
	if args.has("arg0"):
		target = args["arg0"]
	if args.has("arg1"):
		value_arg = args["arg1"]
	
	# RGDパーサーからの形式： set player.name "テストキャラクター"
	# arg0 = "player.name", arg1 = "テストキャラクター"
	
	ArgodeSystem.log("🔍 SetCommand target: '%s', value_arg: '%s'" % [target, value_arg])
		
	if target.is_empty():
		ArgodeSystem.log("❌ SetCommand: No target variable specified", 2)
		return
		
	# ArgodeVariableManagerに値を設定
	if ArgodeSystem and ArgodeSystem.has_method("get") and ArgodeSystem.get("VariableManager"):
		var variable_manager = ArgodeSystem.get("VariableManager")
		
		# 値の解析（"value"、数値、式など）
		var processed_value = _process_value(value_arg, target, variable_manager)
		variable_manager.set_variable(target, processed_value)
		ArgodeSystem.log("✅ Variable set: %s = %s" % [target, str(processed_value)])
	else:
		ArgodeSystem.log("❌ VariableManager not available", 2)

## 値を処理（文字列、数値、式の評価）
func _process_value(value_string: String, target: String, variable_manager) -> Variant:
	if value_string.is_empty():
		return ""
	
	ArgodeSystem.log("🔍 Processing value: '%s'" % value_string)
	
	# 値がすでに純粋な値として渡されている場合（RGDパーサーから）
	# 例："テストキャラクター" -> テストキャラクター (quotesが除去済み)
	
	# 演算式の場合（+=, -=, *=, /=）
	if "+=" in value_string or "-=" in value_string or "*=" in value_string or "/=" in value_string:
		return _process_arithmetic_expression(value_string, target, variable_manager)
	
	# 数値の場合
	if value_string.is_valid_int():
		return value_string.to_int()
	elif value_string.is_valid_float():
		return value_string.to_float()
	
	# そのまま文字列として扱う（最も一般的なケース）
	return value_string

## 算術式を処理
func _process_arithmetic_expression(expression: String, target: String, variable_manager) -> Variant:
	var current_value = variable_manager.get_variable(target)
	if current_value == null:
		current_value = 0  # デフォルト値
	
	# 演算子と値を分離
	var operator = ""
	var value_part = ""
	
	if "+=" in expression:
		var parts = expression.split("+=")
		operator = "+="
		value_part = parts[1].strip_edges() if parts.size() > 1 else ""
	elif "-=" in expression:
		var parts = expression.split("-=")
		operator = "-="
		value_part = parts[1].strip_edges() if parts.size() > 1 else ""
	elif "*=" in expression:
		var parts = expression.split("*=")
		operator = "*="
		value_part = parts[1].strip_edges() if parts.size() > 1 else ""
	elif "/=" in expression:
		var parts = expression.split("/=")
		operator = "/="
		value_part = parts[1].strip_edges() if parts.size() > 1 else ""
	
	# 値を数値に変換
	var operand = 0
	if value_part.is_valid_int():
		operand = value_part.to_int()
	elif value_part.is_valid_float():
		operand = value_part.to_float()
	
	# 演算実行
	match operator:
		"+=":
			return current_value + operand
		"-=":
			return current_value - operand
		"*=":
			return current_value * operand
		"/=":
			return current_value / operand if operand != 0 else current_value
	
	return current_value
