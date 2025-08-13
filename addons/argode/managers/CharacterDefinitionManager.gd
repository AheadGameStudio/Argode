# CharacterDefinitionManager.gd
# v2新機能: `character` ステートメント解析・管理
extends Node
class_name CharacterDefinitionManager

# === シグナル ===
signal character_defined(id: String, definition: Dictionary)
signal definition_error(message: String)

# === 定義ストレージ ===
var character_definitions: Dictionary = {}

# === マネージャー参照 ===
var character_manager  # CharacterManager - ArgodeSystemから設定される
var variable_manager   # VariableManager - ArgodeSystemから設定される

# === 正規表現パターン ===
var regex_character_define: RegEx  # character y = Character(...) 形式
var regex_character_shorthand: RegEx  # character y "name" attr=value 短縮形式

func _ready():
	_compile_regex()
	print("👤 CharacterDefinitionManager initialized (v2)")

func _compile_regex():
	"""character ステートメント解析用の正規表現をコンパイル"""
	# フル形式: character y = Character("優子", name_color="#c8ffc8")
	regex_character_define = RegEx.new()
	regex_character_define.compile("^character\\s+(?<id>\\w+)\\s*=\\s*Character\\((?<args>.*)\\)")
	
	# 短縮形式: character y "Yuko" color=#ffaa88
	regex_character_shorthand = RegEx.new()
	regex_character_shorthand.compile("^character\\s+(?<id>\\w+)\\s+\"(?<display_name>[^\"]+)\"(?<attributes>.*)")

func parse_character_statement(line: String) -> bool:
	"""
	character ステートメントを解析して定義を登録
	@param line: 解析する行
	@return: 解析成功時 true
	"""
	var stripped_line = line.strip_edges()
	
	# まず短縮形式を試行
	var shorthand_match = regex_character_shorthand.search(stripped_line)
	if shorthand_match:
		var char_id = shorthand_match.get_string("id")
		var display_name = shorthand_match.get_string("display_name")
		var attributes_str = shorthand_match.get_string("attributes").strip_edges()
		
		print("👤 Parsing character shorthand: ", char_id, " name: '", display_name, "' attributes: '", attributes_str, "'")
		
		var definition = {"display_name": display_name}
		
		# 属性を解析（color=#ffaa88 形式）
		if not attributes_str.is_empty():
			definition.merge(_parse_shorthand_attributes(attributes_str))
		
		character_definitions[char_id] = definition
		character_defined.emit(char_id, definition)
		
		# CharacterManagerに登録
		if character_manager:
			character_manager.register_character(char_id, definition)
		
		# VariableManagerにもキャラクター定義を同期
		if variable_manager:
			# リソースパスを生成（実際のキャラクターリソースがある場合の処理）
			var resource_path = "res://definitions/characters/" + char_id + ".tres"
			variable_manager.set_character_def(char_id, resource_path)
		
		print("👤 Character defined (shorthand): ", char_id, " -> ", definition)
		return true
	
	# 次にフル形式を試行
	var full_match = regex_character_define.search(stripped_line)
	if full_match:
		var char_id = full_match.get_string("id")
		var args_str = full_match.get_string("args")
		
		var definition = _parse_character_arguments(args_str)
		if definition.is_empty():
			definition_error.emit("Failed to parse character arguments: " + args_str)
			return false
		
		character_definitions[char_id] = definition
		character_defined.emit(char_id, definition)
		
		# CharacterManagerに登録
		if character_manager:
			character_manager.register_character(char_id, definition)
		
		# VariableManagerにもキャラクター定義を同期
		if variable_manager:
			# リソースパスを生成（実際のキャラクターリソースがある場合の処理）
			var resource_path = "res://definitions/characters/" + char_id + ".tres"
			variable_manager.set_character_def(char_id, resource_path)
		
		print("👤 Character defined (full): ", char_id, " -> ", definition)
		return true
	
	# どの形式にもマッチしない
	return false

func _parse_character_arguments(args_str: String) -> Dictionary:
	"""
	Character()の引数文字列をパースしてDictionaryに変換
	例: "\"優子\", name_color=\"#c8ffc8\", show_callback=\"yuko_mouth_start\""
	"""
	var definition = {}
	
	# 簡易的な引数パーサー（改良の余地あり）
	var args = args_str.split(",")
	var first_arg_processed = false
	
	for arg in args:
		arg = arg.strip_edges()
		
		if not first_arg_processed:
			# 最初の引数は表示名
			var display_name = arg.substr(1, arg.length() - 2) # Remove quotes
			definition["display_name"] = display_name
			first_arg_processed = true
		else:
			# キーワード引数を解析
			if "=" in arg:
				var parts = arg.split("=", false, 1)
				if parts.size() == 2:
					var key = parts[0].strip_edges()
					var value = parts[1].strip_edges()
					
					# 値の型変換
					definition[key] = _parse_argument_value(value)
	
	return definition

func _parse_argument_value(value_str: String) -> Variant:
	"""引数値を適切な型に変換"""
	value_str = value_str.strip_edges()
	
	# 文字列（クォートあり）
	if value_str.begins_with("\"") and value_str.ends_with("\""):
		return value_str.substr(1, value_str.length() - 2) # Remove quotes
	
	# 数値
	if value_str.is_valid_float():
		return value_str.to_float()
	
	# 色（#rrggbb形式）
	if value_str.begins_with("\"#") and value_str.ends_with("\""):
		var color_str = value_str.substr(1, value_str.length() - 2) # Remove quotes
		return Color(color_str)
	
	# ブール値
	if value_str.to_lower() in ["true", "false"]:
		return value_str.to_lower() == "true"
	
	# その他は文字列として扱う
	return value_str

func get_character_definition(char_id: String) -> Dictionary:
	"""キャラクター定義を取得"""
	return character_definitions.get(char_id, {})

func has_character(char_id: String) -> bool:
	"""キャラクターが定義済みかチェック"""
	return char_id in character_definitions

func get_all_character_ids() -> Array[String]:
	"""定義済みキャラクターIDのリストを取得"""
	var ids: Array[String] = []
	for id in character_definitions.keys():
		ids.append(id)
	return ids

func build_definitions():
	"""v2設計: 定義をビルド（現在は何もしない）"""
	print("👤 Character definitions built: ", character_definitions.size(), " characters")

# === v2新機能: 短縮形式の属性解析 ===

func _parse_shorthand_attributes(attributes_str: String) -> Dictionary:
	"""
	短縮形式の属性文字列を解析
	例: " color=#ffaa88 type_speed_cps=25.0" 
	"""
	var attributes = {}
	
	# 属性をスペースで分割
	var tokens = attributes_str.split(" ")
	
	for token in tokens:
		token = token.strip_edges()
		if token.is_empty():
			continue
			
		if "=" in token:
			var parts = token.split("=", false, 1)
			if parts.size() == 2:
				var key = parts[0].strip_edges()
				var value_str = parts[1].strip_edges()
				
				# 値を適切な型に変換
				attributes[key] = _parse_shorthand_value(value_str)
				print("   Parsed attribute: ", key, " = ", attributes[key])
	
	return attributes

func _parse_shorthand_value(value_str: String) -> Variant:
	"""短縮形式の属性値を適切な型に変換"""
	# 色（#rrggbb形式、クォートなし）
	if value_str.begins_with("#"):
		return Color(value_str)
	
	# 数値
	if value_str.is_valid_float():
		if "." in value_str:
			return value_str.to_float()
		else:
			return value_str.to_int()
	
	# ブール値
	if value_str.to_lower() in ["true", "false"]:
		return value_str.to_lower() == "true"
	
	# クォート付き文字列
	if value_str.begins_with("\"") and value_str.ends_with("\""):
		return value_str.substr(1, value_str.length() - 2)
	
	# その他は文字列として扱う
	return value_str

func _handle_character_statement(line: String, file_path: String, line_number: int):
	"""
	DefinitionLoaderから呼び出されるキャラクター定義処理エントリーポイント
	"""
	if not parse_character_statement(line):
		print("❌ Failed to process character definition: ", line, " at ", file_path, ":", line_number)

func clear_definitions():
	"""全定義をクリア"""
	character_definitions.clear()
	print("👤 Character definitions cleared")