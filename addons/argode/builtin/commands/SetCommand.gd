@tool
extends BaseCustomCommand

func _init():
	super._init()
	command_name = "set"
	description = "変数に値を設定（ドット記法サポート）"
	help_text = "set <variable_name> = <value>\n変数に値を設定します。ドット記法で辞書の個別キーも設定可能。\n例: set player_name = \"主人公\"\n例: set player.level = 5"

# コマンドを実行
func execute(parameters: Dictionary, adv_system: Node) -> void:
	var raw_command = parameters.get("_raw", "")
	
	# "set variable_name = value" の形式をパース
	var set_regex = RegEx.new()
	set_regex.compile("^set\\s+([\\w\\.]+)\\s*=\\s*(.+)")
	
	var match_result = set_regex.search(raw_command)
	if not match_result:
		log_error("構文エラー: set <変数名> = <値> の形式で記述してください")
		return
	
	var var_path = match_result.get_string(1)
	var expression = match_result.get_string(2).strip_edges()
	
	print("🎯 [set] 変数パス: ", var_path, " = ", expression)
	
	if not adv_system or not adv_system.VariableManager:
		log_error("VariableManagerが利用できません")
		return
	
	var variable_manager = adv_system.VariableManager
	
	# ドット記法かどうかを判定
	if "." in var_path:
		# ネストした変数として設定
		var value = _parse_value(expression)
		variable_manager.set_nested_variable(var_path, value)
		log_command("Nested variable set: " + var_path + " = " + str(value))
	else:
		# 通常の変数として設定（Expression使用）
		variable_manager.set_variable(var_path, expression)
		log_command("Variable set: " + var_path + " = " + expression)

func _parse_value(expression: String) -> Variant:
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
	
	# 辞書リテラル
	if expression.begins_with("{") and expression.ends_with("}"):
		return _parse_dict_literal(expression)
	
	# 配列リテラル
	if expression.begins_with("[") and expression.ends_with("]"):
		return _parse_array_literal(expression)
	
	# その他は文字列として処理
	return expression

func _parse_dict_literal(dict_str: String) -> Dictionary:
	"""簡易辞書リテラルパーサー"""
	var result = {}
	var content = dict_str.substr(1, dict_str.length() - 2).strip_edges()
	if content.is_empty():
		return result
	
	# 簡易パース（完全ではないがテスト用）
	var items = content.split(",")
	for item in items:
		var kv = item.split(":")
		if kv.size() == 2:
			var key = kv[0].strip_edges().strip_edges().replace('"', '')
			var value = _parse_value(kv[1].strip_edges())
			result[key] = value
	
	return result

func _parse_array_literal(array_str: String) -> Array:
	"""簡易配列リテラルパーサー"""
	var result = []
	var content = array_str.substr(1, array_str.length() - 2).strip_edges()
	if content.is_empty():
		return result
	
	var items = content.split(",")
	for item in items:
		var value = _parse_value(item.strip_edges())
		result.append(value)
	
	return result
