extends Node

var global_vars: Dictionary = {}
var character_defs: Dictionary = {}

func _ready():
	print("🧮 VariableManager initialized")

func set_character_def(id: String, resource_path: String):
	character_defs[id] = resource_path
	print("👤 Character defined: ", id, " -> ", resource_path)

func get_character_data(id: String):
	if character_defs.has(id):
		var resource_path = character_defs[id]
		print("🔍 Loading character resource: ", id, " from ", resource_path)
		var resource = load(resource_path)
		if resource:
			print("✅ Character resource loaded: ", id)
			return resource
		else:
			push_error("🚫 Invalid character resource: " + resource_path)
			print("❌ Available character definitions: ", character_defs.keys())
	else:
		push_error("🚫 Character not defined: " + id)
		print("❌ Available character definitions: ", character_defs.keys())
	return null

func set_variable(var_name: String, expression_str: String):
	print("🔧 set_variable called: ", var_name, " = '", expression_str, "' (", typeof(expression_str), ")")
	var expression = Expression.new()
	var error = expression.parse(expression_str, _get_available_variable_names())
	if error != OK:
		push_error("🚫 Expression parse error: " + expression.get_error_text())
		return
	
	var result = expression.execute(global_vars.values())
	if not expression.has_execute_failed():
		global_vars[var_name] = result
		print("📊 Var set: ", var_name, " = ", result)
	else:
		push_error("🚫 Expression execute error.")

func set_variable_direct(var_name: String, value: Variant):
	"""直接値を設定（定義ファイル用）"""
	global_vars[var_name] = value
	print("📊 Var set (direct): ", var_name, " = ", value, " (", typeof(value), ")")

func get_variable(var_name: String) -> Variant:
	"""変数の値を取得"""
	if global_vars.has(var_name):
		return global_vars[var_name]
	else:
		push_warning("⚠️ Undefined variable: " + var_name)
		return null

func evaluate_condition(expression_str: String) -> bool:
	var expression = Expression.new()
	var error = expression.parse(expression_str, _get_available_variable_names())
	if error != OK:
		push_error("🚫 Expression parse error: " + expression.get_error_text())
		return false
	
	var result = expression.execute(global_vars.values())
	if not expression.has_execute_failed():
		return bool(result)
	else:
		push_error("🚫 Expression execute error.")
		return false

func expand_variables(text: String) -> String:
	var result = text
	
	# v2新構文: [variable] 形式の変数展開をサポート
	var regex_v2 = RegEx.new()
	regex_v2.compile("\\[([^\\]]+)\\]")
	var matches_v2 = regex_v2.search_all(text)
	
	for match in matches_v2:
		var var_name = match.get_string(1)
		if global_vars.has(var_name):
			var value = str(global_vars[var_name])
			result = result.replace("[" + var_name + "]", value)
			print("🔄 Variable expanded: [", var_name, "] -> ", value)
		else:
			push_warning("⚠️ Undefined variable in text: " + var_name)
	
	# v2設計: {} 形式はインラインタグ専用のため、変数展開では処理しない
	# v1互換が必要な場合は、明示的に enable_legacy_variable_syntax フラグで制御
	
	# 注意: v2では {} はインラインタグ（{shake}, {color=red}等）に使用
	# 変数展開は [] 形式のみ（[variable_name]）をサポート
	
	return result

func _get_available_variable_names() -> PackedStringArray:
	return PackedStringArray(global_vars.keys())

func handle_set_from_definition(line: String, file_path: String, line_number: int):
	"""定義ファイルからのset文を処理"""
	print("📊 Processing variable definition: ", line.strip_edges())
	
	# 既存の_handle_set_statementを利用
	var set_regex = RegEx.new()
	set_regex.compile("^set\\s+(\\w+)\\s*=\\s*(.+)")
	
	var match_result = set_regex.search(line)
	if match_result:
		var var_name = match_result.get_string(1)
		var expression = match_result.get_string(2).strip_edges()
		
		# 値を解析・設定
		var value = _parse_expression(expression)
		set_variable_direct(var_name, value)  # 直接値設定メソッドを使用
		
		print("   ✅ Set variable: ", var_name, " = ", value, " (", typeof(value), ")")
	else:
		print("   ❌ Invalid set statement at ", file_path, ":", line_number)

func _parse_expression(expression: String) -> Variant:
	"""式を解析してGodot値に変換"""
	expression = expression.strip_edges()
	
	# 文字列リテラル
	if expression.begins_with('"') and expression.ends_with('"'):
		return expression.substr(1, expression.length() - 2)
	
	# 真偽値
	if expression.to_lower() == "true":
		return true
	if expression.to_lower() == "false":
		return false
	
	# 数値（整数）
	if expression.is_valid_int():
		return expression.to_int()
	
	# 数値（浮動小数点）
	if expression.is_valid_float():
		return expression.to_float()
	
	# その他は文字列として処理
	return expression