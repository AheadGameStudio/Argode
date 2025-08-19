extends RefCounted
class_name ArgodeVariableResolver

## 変数解決の統一インターフェース
## 変数解決、式評価、テキスト内変数展開を一元化

var variable_manager: ArgodeVariableManager

func _init(var_manager: ArgodeVariableManager = null):
	variable_manager = var_manager

## 変数マネージャーを設定
func set_variable_manager(var_manager: ArgodeVariableManager) -> void:
	variable_manager = var_manager

## テキスト内の変数を解決（[variable]形式の置換）
func resolve_text(text: String) -> String:
	if not variable_manager:
		ArgodeSystem.log("⚠️ VariableResolver: VariableManager not set", 1)
		return text
	
	var resolved_text = text
	var pattern = RegEx.new()
	pattern.compile("\\[([^\\]]+)\\]")  # [variable_name]のパターン
	
	var results = pattern.search_all(resolved_text)
	
	# 後ろから処理して位置のずれを回避
	for i in range(results.size() - 1, -1, -1):
		var result = results[i]
		var variable_name = result.get_string(1)
		var variable_value = _get_variable_value(variable_name)
		
		# 置換実行
		resolved_text = resolved_text.substr(0, result.get_start()) + variable_value + resolved_text.substr(result.get_end())
	
	return resolved_text

## 変数を設定
func set_variable(variable_name: String, value: Variant) -> void:
	if not variable_manager:
		ArgodeSystem.log("⚠️ VariableResolver: VariableManager not set", 1)
		return
	
	variable_manager.set_variable(variable_name, value)

## 式を評価（set playerName = value, player.affection += 10等）
func evaluate_expression(expression: String, target_variable: String = "") -> Variant:
	ArgodeSystem.log("🔍 VariableResolver.evaluate_expression: expression='%s', target='%s'" % [expression, target_variable])
	
	if not variable_manager:
		ArgodeSystem.log("⚠️ VariableResolver: VariableManager not set", 1)
		return null
	
	var cleaned_expr = expression.strip_edges()
	ArgodeSystem.log("🔍 VariableResolver: cleaned expression='%s'" % cleaned_expr)
	
	# 代入演算子を検出
	if "+=" in cleaned_expr:
		return _evaluate_arithmetic_assignment(cleaned_expr, target_variable, "+=")
	elif "-=" in cleaned_expr:
		return _evaluate_arithmetic_assignment(cleaned_expr, target_variable, "-=")
	elif "*=" in cleaned_expr:
		return _evaluate_arithmetic_assignment(cleaned_expr, target_variable, "*=")
	elif "/=" in cleaned_expr:
		return _evaluate_arithmetic_assignment(cleaned_expr, target_variable, "/=")
	elif "=" in cleaned_expr:
		return _evaluate_simple_assignment(cleaned_expr, target_variable)
	else:
		# 単純な値として処理（Expressionクラスは使わない）
		return _process_value(cleaned_expr)

## 変数値を取得（内部処理）
func _get_variable_value(variable_name: String) -> String:
	var value = variable_manager.get_variable(variable_name)
	
	if value != null:
		return str(value)
	else:
		# 未定義変数の処理
		if ArgodeSystem.DebugManager and ArgodeSystem.DebugManager.is_debug_mode():
			return "[UNDEFINED:%s]" % variable_name
		else:
			return ""  # リリース時は空文字

## 単純代入の評価（variable = value）
func _evaluate_simple_assignment(expression: String, target_variable: String) -> Variant:
	ArgodeSystem.log("🔍 VariableResolver._evaluate_simple_assignment: expression='%s', target='%s'" % [expression, target_variable])
	
	var parts = expression.split("=", false, 1)
	ArgodeSystem.log("🔍 VariableResolver: split parts=%s" % str(parts))
	
	if parts.size() != 2:
		ArgodeSystem.log("⚠️ VariableResolver: Invalid assignment expression: %s" % expression, 1)
		return null
	
	var var_name = target_variable if not target_variable.is_empty() else parts[0].strip_edges()
	var value_part = parts[1].strip_edges()
	
	ArgodeSystem.log("🔍 VariableResolver: var_name='%s', value_part='%s'" % [var_name, value_part])
	
	# 値を評価
	var processed_value = _process_value(value_part)
	ArgodeSystem.log("🔍 VariableResolver: processed_value=%s" % str(processed_value))
	
	variable_manager.set_variable(var_name, processed_value)
	
	return processed_value

## 算術代入の評価（variable += value等）
func _evaluate_arithmetic_assignment(expression: String, target_variable: String, operator: String) -> Variant:
	var parts = expression.split(operator, false, 1)
	if parts.size() != 2:
		ArgodeSystem.log("⚠️ VariableResolver: Invalid arithmetic expression: %s" % expression, 1)
		return null
	
	var var_name = target_variable if not target_variable.is_empty() else parts[0].strip_edges()
	var value_part = parts[1].strip_edges()
	
	# 現在の値を取得
	var current_value = variable_manager.get_variable(var_name)
	if current_value == null:
		current_value = 0  # デフォルト値
	
	# 演算値を処理
	var operand = _process_value(value_part)
	
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
	
	variable_manager.set_variable(var_name, result)
	return result

## 式として評価（Expressionクラス使用）
func _evaluate_as_expression(expression: String) -> Variant:
	var expr = Expression.new()
	var error = expr.parse(expression)
	
	if error != OK:
		ArgodeSystem.log("⚠️ VariableResolver: Expression parse error: %s" % expression, 1)
		return null
	
	# selfを明示的に渡して実行
	var result = expr.execute([], self)
	if expr.has_execute_failed():
		ArgodeSystem.log("⚠️ VariableResolver: Expression execution error: %s" % expression, 1)
		return null
	
	return result

## 値を処理（文字列、数値、変数参照等）
func _process_value(value_string: String) -> Variant:
	if value_string.is_empty():
		return ""
	
	var cleaned = value_string.strip_edges()
	
	# 数値の場合
	if cleaned.is_valid_int():
		return cleaned.to_int()
	elif cleaned.is_valid_float():
		return cleaned.to_float()
	
	# boolean の場合
	if cleaned.to_lower() == "true":
		return true
	elif cleaned.to_lower() == "false":
		return false
	
	# 変数参照の場合（[variable]）
	if cleaned.begins_with("[") and cleaned.ends_with("]"):
		var var_name = cleaned.substr(1, cleaned.length() - 2)
		return variable_manager.get_variable(var_name)
	
	# 文字列として扱う
	return cleaned

## 変数が存在するかチェック
func has_variable(variable_name: String) -> bool:
	if not variable_manager:
		return false
	return variable_manager.has_variable(variable_name)

## デバッグ情報出力
func debug_print_variables() -> void:
	if variable_manager:
		variable_manager.debug_print_variables()
	else:
		ArgodeSystem.log("⚠️ VariableResolver: VariableManager not set", 1)
