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

func get_nested_variable(path: String, separator: String = ".") -> Variant:
	"""ネストした変数の値を取得 (例: "player.stats.level")"""
	var keys = path.split(separator)
	var current = global_vars
	
	for key in keys:
		if current is Dictionary and current.has(key):
			current = current[key]
		else:
			push_warning("⚠️ Undefined nested variable: " + path)
			return null
	
	return current

func set_nested_variable(path: String, value: Variant, separator: String = "."):
	"""ネストした変数に値を設定 (例: "player.stats.level", 10)"""
	var keys = path.split(separator)
	var current = global_vars
	
	# 最後のキーを除いて辞書を作成/取得
	for i in range(keys.size() - 1):
		var key = keys[i]
		if not current.has(key) or not (current[key] is Dictionary):
			current[key] = {}
		current = current[key]
	
	# 最後のキーに値を設定
	var final_key = keys[-1]
	current[final_key] = value
	print("📊 Nested var set: ", path, " = ", value, " (", typeof(value), ")")

func get_flag(flag_name: String) -> bool:
	"""フラグの状態を取得（フラグ専用メソッド）"""
	var flags = global_vars.get("_flags", {})
	return flags.get(flag_name, false)

func set_flag(flag_name: String, value: bool):
	"""フラグを設定（フラグ専用メソッド）"""
	if not global_vars.has("_flags"):
		global_vars["_flags"] = {}
	global_vars["_flags"][flag_name] = value
	print("🏷️ Flag set: ", flag_name, " = ", value)

func toggle_flag(flag_name: String) -> bool:
	"""フラグを切り替えて新しい値を返す"""
	var new_value = not get_flag(flag_name)
	set_flag(flag_name, new_value)
	return new_value

func set_dictionary(var_name: String, dict_literal: String):
	"""辞書リテラル文字列から辞書を設定"""
	var parsed_dict = _parse_dictionary_literal(dict_literal)
	if parsed_dict != null:
		set_variable_direct(var_name, parsed_dict)
		print("📚 Dictionary set: ", var_name, " = ", parsed_dict)
	else:
		push_error("Failed to parse dictionary literal: " + dict_literal)

func set_array(var_name: String, array_literal: String):
	"""配列リテラル文字列から配列を設定"""
	var parsed_array = _parse_array_literal(array_literal)
	if parsed_array != null:
		set_variable_direct(var_name, parsed_array)
		print("📋 Array set: ", var_name, " = ", parsed_array)
	else:
		push_error("Failed to parse array literal: " + array_literal)

func create_variable_group(group_name: String, initial_data: Dictionary = {}):
	"""変数グループを作成"""
	global_vars[group_name] = initial_data
	print("📦 Variable group created: ", group_name, " with ", initial_data.size(), " items")

func get_variable_group(group_name: String) -> Dictionary:
	"""変数グループを取得"""
	if global_vars.has(group_name) and global_vars[group_name] is Dictionary:
		return global_vars[group_name]
	else:
		push_warning("⚠️ Variable group not found: " + group_name)
		return {}

func add_to_variable_group(group_name: String, key: String, value: Variant):
	"""変数グループに項目を追加"""
	if not global_vars.has(group_name):
		global_vars[group_name] = {}
	elif not (global_vars[group_name] is Dictionary):
		push_warning("⚠️ " + group_name + " is not a dictionary group")
		return
	
	global_vars[group_name][key] = value
	print("📦 Added to group ", group_name, ": ", key, " = ", value)

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
	
	# v2新構文: [variable] または [group.key] 形式の変数展開をサポート
	var regex_v2 = RegEx.new()
	regex_v2.compile("\\[([^\\]]+)\\]")
	var matches_v2 = regex_v2.search_all(text)
	
	for match in matches_v2:
		var var_path = match.get_string(1)
		var value = null
		
		# ドット記法の場合はネスト変数として取得
		if "." in var_path:
			value = get_nested_variable(var_path)
		else:
			# 通常の変数として取得
			value = global_vars.get(var_path, null)
		
		if value != null:
			var value_str = str(value)
			result = result.replace("[" + var_path + "]", value_str)
			print("🔄 Variable expanded: [", var_path, "] -> ", value_str)
		else:
			push_warning("⚠️ Undefined variable in text: " + var_path)
	
	# v2拡張: {} 形式の変数展開もサポート（配列アクセス等との互換性のため）
	var regex_curly = RegEx.new()
	regex_curly.compile("\\{([^\\}]+)\\}")
	var matches_curly = regex_curly.search_all(result)
	
	for match in matches_curly:
		var var_expression = match.get_string(1)
		var value = null
		
		# 配列アクセス（例: inventory[0]）を処理
		if "[" in var_expression and "]" in var_expression:
			value = _evaluate_array_access(var_expression)
		# ドット記法（例: player.name）を処理
		elif "." in var_expression:
			value = get_nested_variable(var_expression)
		# 通常の変数を処理
		else:
			value = global_vars.get(var_expression, null)
		
		if value != null:
			var value_str = str(value)
			result = result.replace("{" + var_expression + "}", value_str)
			print("🔄 Variable expanded: {", var_expression, "} -> ", value_str)
		else:
			push_warning("⚠️ Undefined variable in text: " + var_expression)
	
	return result

func _evaluate_array_access(expression: String) -> Variant:
	"""配列アクセス式を評価（例: inventory[0], data.items[1]）"""
	var bracket_start = expression.find("[")
	var bracket_end = expression.find("]")
	
	if bracket_start == -1 or bracket_end == -1:
		push_warning("⚠️ Invalid array access syntax: " + expression)
		return null
	
	var var_name = expression.substr(0, bracket_start)
	var index_str = expression.substr(bracket_start + 1, bracket_end - bracket_start - 1)
	
	# インデックスを数値に変換
	var index = -1
	if index_str.is_valid_int():
		index = index_str.to_int()
	else:
		push_warning("⚠️ Non-integer array index: " + index_str)
		return null
	
	# 変数を取得
	var array_value = null
	if "." in var_name:
		array_value = get_nested_variable(var_name)
	else:
		array_value = global_vars.get(var_name, null)
	
	# 配列の有効性をチェック
	if array_value == null:
		push_warning("⚠️ Undefined array variable: " + var_name)
		return null
	
	if not (array_value is Array):
		push_warning("⚠️ Variable is not an array: " + var_name)
		return null
	
	if index < 0 or index >= array_value.size():
		push_warning("⚠️ Array index out of bounds: " + str(index) + " for array size " + str(array_value.size()))
		return null
	
	return array_value[index]

func _get_available_variable_names() -> PackedStringArray:
	return PackedStringArray(global_vars.keys())

func handle_set_from_definition(line: String, file_path: String, line_number: int):
	"""定義ファイルからのset文を処理（ドット記法サポート追加）"""
	print("📊 Processing variable definition: ", line.strip_edges())
	
	# ドット記法を含む拡張set文の正規表現
	var set_regex = RegEx.new()
	set_regex.compile("^set\\s+([\\w\\.]+)\\s*=\\s*(.+)")
	
	var match_result = set_regex.search(line)
	if match_result:
		var var_path = match_result.get_string(1)
		var expression = match_result.get_string(2).strip_edges()
		
		# 値を解析
		var value = _parse_expression(expression)
		
		# ドット記法かどうかを判定
		if "." in var_path:
			# ネストした変数として設定
			set_nested_variable(var_path, value)
			print("   ✅ Set nested variable: ", var_path, " = ", value, " (", typeof(value), ")")
		else:
			# 通常の変数として設定
			set_variable_direct(var_path, value)
			print("   ✅ Set variable: ", var_path, " = ", value, " (", typeof(value), ")")
	else:
		print("   ❌ Invalid set statement at ", file_path, ":", line_number)

func _parse_expression(expression: String) -> Variant:
	"""式を解析してGodot値に変換（辞書・配列サポート追加）"""
	expression = expression.strip_edges()
	
	# 辞書リテラル {"key": "value", "key2": 123}
	if expression.begins_with("{") and expression.ends_with("}"):
		return _parse_dictionary_literal(expression)
	
	# 配列リテラル ["item1", "item2", 123]
	if expression.begins_with("[") and expression.ends_with("]"):
		return _parse_array_literal(expression)
	
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

func _parse_dictionary_literal(dict_str: String) -> Dictionary:
	"""辞書リテラルをパース"""
	var result = {}
	
	# {} の中身を取得
	var content = dict_str.substr(1, dict_str.length() - 2).strip_edges()
	if content.is_empty():
		return result
	
	# カンマで分割（簡易実装）
	var pairs = content.split(",")
	
	for pair in pairs:
		var kv = pair.split(":", false, 1)  # 最大2つに分割
		if kv.size() == 2:
			var key = kv[0].strip_edges()
			var value_str = kv[1].strip_edges()
			
			# キーの引用符を除去
			if key.begins_with('"') and key.ends_with('"'):
				key = key.substr(1, key.length() - 2)
			
			# 値を再帰的にパース
			var value = _parse_expression(value_str)
			result[key] = value
	
	return result

func _parse_array_literal(array_str: String) -> Array:
	"""配列リテラルをパース"""
	var result = []
	
	# [] の中身を取得
	var content = array_str.substr(1, array_str.length() - 2).strip_edges()
	if content.is_empty():
		return result
	
	# カンマで分割
	var items = content.split(",")
	
	for item in items:
		var value = _parse_expression(item.strip_edges())
		result.append(value)
	
	return result

func get_all_variables() -> Dictionary:
	"""すべての変数を取得（セーブ・ロード用）"""
	return global_vars.duplicate()