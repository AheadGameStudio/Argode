# ArgodeVariableManager.gd (Service Layer Pattern統合版)
extends RefCounted

class_name ArgodeVariableManager

## 変数管理・引数処理統合マネージャー
## ゲーム内の変数（player.name, player.affection等）を保存・取得する
## Service Layer Pattern: 引数処理、型変換、式評価を統合

# 変数ストレージ
var variables: Dictionary = {}

# 型変換とバリデーション
var type_validators: Dictionary = {}
var default_values: Dictionary = {}

# 引数処理統合（StatementManager支援）
var argument_cache: Dictionary = {}

func _init():
	_setup_default_validators()
	ArgodeSystem.log_workflow("VariableManager initialized with Service Layer integration")

## デフォルトの型バリデーターを設定
func _setup_default_validators():
	type_validators = {
		"int": _validate_int,
		"float": _validate_float,
		"string": _validate_string,
		"bool": _validate_bool,
		"array": _validate_array,
		"dictionary": _validate_dictionary
	}

## === 変数管理API（公開インターフェース）===

## 変数を設定（型チェック・バリデーション付き）
func set_variable(variable_name: String, value: Variant, expected_type: String = "") -> bool:
	# 型チェック実行
	if expected_type != "" and not _validate_type(value, expected_type):
		ArgodeSystem.log_critical("Variable type validation failed: %s expected %s, got %s" % [variable_name, expected_type, typeof(value)])
		return false
	
	# 変数を保存
	variables[variable_name] = value
	ArgodeSystem.log_workflow("Variable set: %s = %s" % [variable_name, str(value)])
	return true

## 変数を取得（デフォルト値サポート）
func get_variable(variable_name: String, default_value: Variant = null) -> Variant:
	if variables.has(variable_name):
		return variables[variable_name]
	
	# デフォルト値が設定されている場合
	if default_values.has(variable_name):
		var default_val = default_values[variable_name]
		ArgodeSystem.log_debug_detail("Using default value for %s: %s" % [variable_name, str(default_val)])
		return default_val
	
	# 引数で指定されたデフォルト値
	if default_value != null:
		ArgodeSystem.log_debug_detail("Using provided default for %s: %s" % [variable_name, str(default_value)])
		return default_value
	
	# 変数が見つからない場合
	ArgodeSystem.log_critical("Variable not found: %s" % variable_name)
	return null

## 変数が存在するかチェック
func has_variable(variable_name: String) -> bool:
	return variables.has(variable_name)

## 変数を削除
func remove_variable(variable_name: String) -> bool:
	if variables.has(variable_name):
		variables.erase(variable_name)
		ArgodeSystem.log_workflow("Variable removed: %s" % variable_name)
		return true
	return false

## 全ての変数をクリア
func clear_all_variables() -> void:
	variables.clear()
	argument_cache.clear()
	ArgodeSystem.log_workflow("All variables cleared")

## === 引数処理統合API（StatementManager支援）===

## 引数配列を処理してDictionary形式に変換（StatementManager用）
func process_arguments(args: Array) -> Dictionary:
	var processed_args = {}
	var positional_index = 0
	
	for arg in args:
		var arg_str = str(arg)
		
		# Argode型指定形式の場合 (name:Type:value)
		if _is_typed_argument(arg_str):
			var typed_pair = _parse_typed_argument(arg_str)
			if not typed_pair.is_empty():
				processed_args[typed_pair.key] = typed_pair.value
		# キーワード引数の場合 (key=value)
		elif _is_keyword_argument(arg_str):
			var kv_pair = _parse_keyword_argument(arg_str)
			if not kv_pair.is_empty():
				processed_args[kv_pair.key] = kv_pair.value
		else:
			# 位置引数の場合
			processed_args[str(positional_index)] = _process_argument_value(arg_str)
			positional_index += 1
	
	# キャッシュに保存（デバッグ用）
	argument_cache["last_processed"] = processed_args
	ArgodeSystem.log_debug_detail("Processed %d arguments" % args.size())
	
	return processed_args

## 単一引数値を処理（型変換・変数展開）
func _process_argument_value(arg_str: String) -> Variant:
	# 変数参照の場合 ($variable_name)
	if arg_str.begins_with("$"):
		var var_name = arg_str.substr(1)
		return get_variable(var_name, arg_str)  # 見つからない場合は元の文字列を返す
	
	# 文字列リテラルの場合 ("text" または 'text')
	if (arg_str.begins_with('"') and arg_str.ends_with('"')) or (arg_str.begins_with("'") and arg_str.ends_with("'")):
		return arg_str.substr(1, arg_str.length() - 2)
	
	# 数値の場合
	if arg_str.is_valid_int():
		return arg_str.to_int()
	
	if arg_str.is_valid_float():
		return arg_str.to_float()
	
	# 真偽値の場合
	var lower_arg = arg_str.to_lower()
	if lower_arg == "true":
		return true
	elif lower_arg == "false":
		return false
	
	# その他の場合は文字列として返す
	return arg_str

## キーワード引数かどうかを判定
func _is_keyword_argument(arg: String) -> bool:
	return arg.contains("=") and not arg.begins_with("=") and not arg.ends_with("=")

## キーワード引数をパース (key=value → {key: key, value: value})
func _parse_keyword_argument(arg: String) -> Dictionary:
	var parts = arg.split("=", false, 1)
	if parts.size() != 2:
		ArgodeSystem.log_critical("Invalid keyword argument format: %s" % arg)
		return {}
	
	var key = parts[0].strip_edges()
	var value = _process_argument_value(parts[1].strip_edges())
	
	return {"key": key, "value": value}

## === 型バリデーション機能 ===

## 値の型をバリデート
func _validate_type(value: Variant, type_name: String) -> bool:
	if not type_validators.has(type_name):
		ArgodeSystem.log_critical("Unknown type validator: %s" % type_name)
		return false
	
	var validator = type_validators[type_name]
	return validator.call(value)

## 各型のバリデーター
func _validate_int(value: Variant) -> bool:
	return typeof(value) == TYPE_INT

func _validate_float(value: Variant) -> bool:
	return typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT

func _validate_string(value: Variant) -> bool:
	return typeof(value) == TYPE_STRING

func _validate_bool(value: Variant) -> bool:
	return typeof(value) == TYPE_BOOL

func _validate_array(value: Variant) -> bool:
	return typeof(value) == TYPE_ARRAY

func _validate_dictionary(value: Variant) -> bool:
	return typeof(value) == TYPE_DICTIONARY

## === 式評価機能 ===

## 簡単な数式を評価 (例: "player.level + 5")
func evaluate_expression(expression: String) -> Variant:
	# Godotの Expression クラスを使用
	var expr = Expression.new()
	
	# 式で使用される変数名を抽出
	var used_variables = _extract_variable_names(expression)
	var input_names = []
	var input_values = []
	
	# 使用される変数のみコンテキストに追加
	for var_name in used_variables:
		if variables.has(var_name):
			input_names.append(var_name)
			input_values.append(variables[var_name])
		else:
			ArgodeSystem.log_critical("Variable '%s' not found in expression: %s" % [var_name, expression])
			return null
	
	# 式を解析（変数名をそのまま使用）
	var error = expr.parse(expression, input_names)
	
	if error != OK:
		ArgodeSystem.log_critical("Expression parse error: %s in '%s'" % [expr.get_error_text(), expression])
		return null
	
	# 実行
	var result = expr.execute(input_values)
	if expr.has_execute_failed():
		ArgodeSystem.log_critical("Expression execution failed: %s" % expression)
		return null
	
	ArgodeSystem.log_debug_detail("Expression evaluated: %s = %s" % [expression, str(result)])
	return result

## 式内の変数を展開
func _expand_variables_in_expression(expression: String) -> String:
	var expanded = expression
	
	# $variable_name パターンを実際の値に置換
	var regex = RegEx.new()
	regex.compile("\\$([a-zA-Z_][a-zA-Z0-9_]*)")
	
	var results = regex.search_all(expanded)
	for result in results:
		var var_name = result.get_string(1)
		var var_value = get_variable(var_name, 0)  # デフォルト値として0を使用
		expanded = expanded.replace("$" + var_name, str(var_value))
	
	return expanded

## 式から変数名を抽出
func _extract_variable_names(expression: String) -> Array:
	var variable_names = []
	var regex = RegEx.new()
	regex.compile("\\b([a-zA-Z_][a-zA-Z0-9_]*)\\b")
	
	var results = regex.search_all(expression)
	for result in results:
		var potential_var = result.get_string(1)
		# 既知の変数のみを抽出
		if variables.has(potential_var) and potential_var not in variable_names:
			variable_names.append(potential_var)
	
	return variable_names

## === デフォルト値管理 ===

## 変数のデフォルト値を設定
func set_default_value(variable_name: String, default_value: Variant):
	default_values[variable_name] = default_value
	ArgodeSystem.log_debug_detail("Default value set: %s = %s" % [variable_name, str(default_value)])

## デフォルト値を削除
func remove_default_value(variable_name: String):
	if default_values.has(variable_name):
		default_values.erase(variable_name)
		ArgodeSystem.log_debug_detail("Default value removed: %s" % variable_name)

## === デバッグ・管理機能 ===

## 変数一覧を取得（デバッグ用）
func get_all_variables() -> Dictionary:
	return variables.duplicate()

## 引数処理履歴を取得
func get_argument_cache() -> Dictionary:
	return argument_cache.duplicate()

## 変数をデバッグログに出力
func debug_print_variables() -> void:
	ArgodeSystem.log_debug_detail("=== Current Variables ===")
	for key in variables.keys():
		ArgodeSystem.log_debug_detail("  %s = %s (%s)" % [key, str(variables[key]), typeof(variables[key])])
	
	if not default_values.is_empty():
		ArgodeSystem.log_debug_detail("=== Default Values ===")
		for key in default_values.keys():
			ArgodeSystem.log_debug_detail("  %s = %s" % [key, str(default_values[key])])
	
	ArgodeSystem.log_debug_detail("========================")

## 型情報付きで変数を一括設定
func set_variables_with_types(variable_data: Dictionary) -> bool:
	var all_success = true
	
	for var_name in variable_data:
		var data = variable_data[var_name]
		var value = data.get("value")
		var type_constraint = data.get("type", "")
		
		if not set_variable(var_name, value, type_constraint):
			all_success = false
	
	return all_success

## JSON形式での変数エクスポート
func export_variables_to_json() -> String:
	var export_data = {
		"variables": variables,
		"defaults": default_values
	}
	return JSON.stringify(export_data)

## JSON形式から変数をインポート
func import_variables_from_json(json_string: String) -> bool:
	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error != OK:
		ArgodeSystem.log_critical("JSON parse error: %s" % json.get_error_message())
		return false
	
	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		ArgodeSystem.log_critical("Invalid JSON format for variable import")
		return false
	
	if data.has("variables"):
		variables = data.variables
	
	if data.has("defaults"):
		default_values = data.defaults
	
	ArgodeSystem.log_workflow("Variables imported from JSON successfully")
	return true

# ===========================
# 引数解析ヘルパーメソッド
# ===========================

## Argode型指定形式かどうかを判定 (name:Type:value)
func _is_typed_argument(arg_str: String) -> bool:
	var parts = arg_str.split(":")
	return parts.size() == 3

## Argode型指定形式を解析 (name:Type:value)
func _parse_typed_argument(arg_str: String) -> Dictionary:
	var parts = arg_str.split(":")
	if parts.size() != 3:
		return {}
	
	var key = parts[0].strip_edges()
	var type_str = parts[1].strip_edges()
	var value_str = parts[2].strip_edges()
	
	var processed_value = validate_value(value_str, type_str)
	
	return {
		"key": key,
		"value": processed_value
	}

## 型指定に基づく値検証・変換
func validate_value(value_str: String, type_str: String) -> Variant:
	match type_str.to_upper():
		"STRING", "STR":
			return value_str
		"INT", "INTEGER":
			if value_str.is_valid_int():
				return value_str.to_int()
			else:
				ArgodeSystem.log_critical("Invalid integer: %s" % value_str)
				return 0
		"FLOAT", "REAL":
			if value_str.is_valid_float():
				return value_str.to_float()
			else:
				ArgodeSystem.log_critical("Invalid float: %s" % value_str)
				return 0.0
		"BOOL", "BOOLEAN":
			return value_str.to_lower() in ["true", "1", "yes", "on"]
		_:
			ArgodeSystem.log_critical("Unknown type: %s" % type_str)
			return value_str
