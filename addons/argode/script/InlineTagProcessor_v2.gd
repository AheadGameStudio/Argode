# InlineTagProcessor.gd
# v2新機能: 統合タグ解析エンジン
# カスタムコマンドシステムと統合したタグ処理システム
extends RefCounted
class_name InlineTagProcessor

# タグの種類
enum TagType {
	IMMEDIATE,       # 即座実行 ({w=0.5}, {shake}, {pause} etc.)
	DECORATION,      # 装飾タグ ({color=red}...{/color}, {b}...{/b} etc.)
	BBCODE_PASSTHROUGH,  # BBCode直接変換
	CUSTOM           # カスタムタグ（ユーザー定義）
}

# タグ実行タイミング
enum ExecutionTiming {
	PRE_VARIABLE,    # 変数展開前に実行
	POST_VARIABLE,   # 変数展開後に実行
	DURING_TYPEWRITER # タイプライター中に実行
}

# 即座実行タグの定義 (変数展開前に処理される)
var immediate_tags: Dictionary = {
	"w": { "type": TagType.IMMEDIATE, "timing": ExecutionTiming.PRE_VARIABLE },
	"wait": { "type": TagType.IMMEDIATE, "timing": ExecutionTiming.PRE_VARIABLE },
	"p": { "type": TagType.IMMEDIATE, "timing": ExecutionTiming.DURING_TYPEWRITER },
	"pause": { "type": TagType.IMMEDIATE, "timing": ExecutionTiming.DURING_TYPEWRITER },
	"clear": { "type": TagType.IMMEDIATE, "timing": ExecutionTiming.PRE_VARIABLE },
	"shake": { "type": TagType.IMMEDIATE, "timing": ExecutionTiming.PRE_VARIABLE },
}

# 装飾タグの定義 (BBCodeに変換される)
var decoration_tags: Dictionary = {
	"color": { "type": TagType.DECORATION, "bbcode": "color" },
	"size": { "type": TagType.DECORATION, "bbcode": "font_size" },
	"b": { "type": TagType.DECORATION, "bbcode": "b" },
	"i": { "type": TagType.DECORATION, "bbcode": "i" },
	"u": { "type": TagType.DECORATION, "bbcode": "u" },
	"s": { "type": TagType.DECORATION, "bbcode": "s" },
	"bgcolor": { "type": TagType.DECORATION, "bbcode": "bgcolor" },
	"a": { "type": TagType.DECORATION, "bbcode": "url" },  # リンクタグ追加
}

# カスタムタグレジストリ（ユーザー定義タグ）
var custom_tags: Dictionary = {}

# カスタムコマンドハンドラー参照
var custom_command_handler: CustomCommandHandler

# 解析済みタグ情報
class ParsedTag:
	var tag_type: TagType
	var tag_name: String
	var parameters: Dictionary
	var start_position: int
	var end_position: int
	var original_text: String
	var is_end_tag: bool
	var execution_timing: ExecutionTiming
	
	func _init(type: TagType, name: String, params: Dictionary, start: int, end: int, original: String, end_tag: bool = false):
		tag_type = type
		tag_name = name
		parameters = params
		start_position = start
		end_position = end
		original_text = original
		is_end_tag = end_tag
		execution_timing = ExecutionTiming.POST_VARIABLE  # デフォルト

# タグ処理結果
class ProcessResult:
	var clean_text: String      # タグが処理されたテキスト
	var immediate_commands: Array[Dictionary]  # 即座実行するコマンド
	var typewriter_tags: Array[ParsedTag]  # タイプライター中に実行するタグ
	
	func _init(initial_text: String = ""):
		clean_text = initial_text
		immediate_commands = []
		typewriter_tags = []

# === 初期化 ===

func _init():
	print("🏷️ InlineTagProcessor v2 initialized")

func set_custom_command_handler(handler: CustomCommandHandler):
	"""カスタムコマンドハンドラーを設定"""
	custom_command_handler = handler
	print("🔗 InlineTagProcessor connected to CustomCommandHandler")

# === メインの解析機能 ===

func process_text_pre_variable(input_text: String) -> ProcessResult:
	"""変数展開前のタグ処理（即座実行タグのみ）"""
	print("🏷️ Processing pre-variable tags in: ", input_text)
	
	var result = ProcessResult.new(input_text)
	var regex = RegEx.new()
	regex.compile("\\{([^}]+)\\}")  # {tag} 形式
	
	var matches = regex.search_all(input_text)
	var offset = 0
	
	for match in matches:
		var tag_content = match.get_string(1)
		var parsed_tag = _parse_single_tag(tag_content, match.get_start(), match.get_end(), match.get_string(0))
		
		if parsed_tag and parsed_tag.tag_type == TagType.IMMEDIATE:
			var tag_info = immediate_tags.get(parsed_tag.tag_name)
			if tag_info and tag_info.timing == ExecutionTiming.PRE_VARIABLE:
				# 即座実行コマンドとして登録
				result.immediate_commands.append({
					"command": parsed_tag.tag_name,
					"parameters": parsed_tag.parameters,
					"original": parsed_tag.original_text
				})
				
				# テキストからタグを除去
				var tag_start = match.get_start() - offset
				var tag_end = match.get_end() - offset
				result.clean_text = result.clean_text.left(tag_start) + result.clean_text.substr(tag_end)
				offset += tag_end - tag_start
			elif tag_info and tag_info.timing == ExecutionTiming.DURING_TYPEWRITER:
				# タイプライター中実行用として保存（位置調整）
				parsed_tag.start_position = match.get_start() - offset
				result.typewriter_tags.append(parsed_tag)
	
	print("🏷️ Pre-variable processing result: ", result.immediate_commands.size(), " immediate commands, ", result.typewriter_tags.size(), " typewriter tags")
	return result

func process_text_post_variable(input_text: String) -> String:
	"""変数展開後のタグ処理（装飾タグをBBCodeに変換）"""
	print("🏷️ Processing post-variable tags in: ", input_text)
	
	var result_text = input_text
	
	# 角括弧パターン [tag=param] と波括弧パターン {tag=param} の両方を処理
	var regex_bracket = RegEx.new()
	regex_bracket.compile("\\[(/?)([^\\]=]+)(?:=([^\\]]*))?\\]")  # [tag=param] または [/tag] 形式
	
	var regex_brace = RegEx.new()
	regex_brace.compile("\\{(/?)([^}=]+)(?:=([^}]*))?\\}")  # {tag=param} または {/tag} 形式
	
	# 角括弧パターンから処理
	var matches_bracket = regex_bracket.search_all(result_text)
	var matches_brace = regex_brace.search_all(result_text)
	
	# 全てのマッチを位置順にソート
	var all_matches = []
	for match in matches_bracket:
		all_matches.append(match)
	for match in matches_brace:
		all_matches.append(match)
	
	all_matches.sort_custom(func(a, b): return a.get_start() < b.get_start())
	
	var matches = all_matches
	var offset = 0
	
	for match in matches:
		var is_end_tag = not match.get_string(1).is_empty()
		var tag_name = match.get_string(2)
		var tag_param = match.get_string(3) if match.get_group_count() > 2 else ""
		
		# 装飾タグの処理
		if decoration_tags.has(tag_name):
			var tag_info = decoration_tags[tag_name]
			var bbcode_tag = _convert_to_bbcode(tag_name, tag_param, is_end_tag, tag_info)
			
			if not bbcode_tag.is_empty():
				var tag_start = match.get_start() - offset
				var tag_end = match.get_end() - offset
				result_text = result_text.left(tag_start) + bbcode_tag + result_text.substr(tag_end)
				offset -= bbcode_tag.length() - (tag_end - tag_start)
		
		# カスタム装飾タグの処理
		elif custom_tags.has(tag_name) and custom_tags[tag_name].type == TagType.DECORATION:
			var custom_tag = custom_tags[tag_name]
			var custom_bbcode = _process_custom_decoration_tag(tag_name, tag_param, is_end_tag, custom_tag)
			
			if not custom_bbcode.is_empty():
				var tag_start = match.get_start() - offset
				var tag_end = match.get_end() - offset
				result_text = result_text.left(tag_start) + custom_bbcode + result_text.substr(tag_end)
				offset -= custom_bbcode.length() - (tag_end - tag_start)
	
	print("🏷️ Post-variable processing result: ", result_text)
	return result_text

# === タグ解析ヘルパー ===

func _parse_single_tag(tag_content: String, tag_start: int, tag_end: int, original_tag: String) -> ParsedTag:
	"""単一のタグを解析"""
	var is_end_tag = tag_content.begins_with("/")
	var actual_tag_name = tag_content
	if is_end_tag:
		actual_tag_name = tag_content.substr(1)
	
	var parts = actual_tag_name.split("=", false, 1)
	var tag_name = parts[0].strip_edges()
	var parameters = {}
	
	if parts.size() > 1:
		var param_value = parts[1].strip_edges()
		parameters["value"] = _convert_parameter_value(param_value)
		parameters["raw_value"] = param_value
	
	# タグタイプを決定
	var tag_type = TagType.CUSTOM
	if immediate_tags.has(tag_name):
		tag_type = TagType.IMMEDIATE
	elif decoration_tags.has(tag_name):
		tag_type = TagType.DECORATION
	elif custom_tags.has(tag_name):
		tag_type = custom_tags[tag_name].type
	
	var parsed_tag = ParsedTag.new(tag_type, tag_name, parameters, tag_start, tag_end, original_tag, is_end_tag)
	
	# 特殊パラメータ解析
	_parse_tag_specific_parameters(parsed_tag)
	
	return parsed_tag

func _parse_tag_specific_parameters(tag: ParsedTag):
	"""タグ固有のパラメータ解析"""
	match tag.tag_name:
		"w", "wait":
			if tag.parameters.has("value"):
				tag.parameters["duration"] = float(tag.parameters["value"])
			else:
				tag.parameters["duration"] = 1.0
		"shake":
			if not tag.parameters.has("value"):
				tag.parameters["intensity"] = 2.0
				tag.parameters["duration"] = 0.3
		"color":
			if tag.parameters.has("value"):
				tag.parameters["color"] = _parse_color_string(str(tag.parameters["value"]))
		"size":
			if tag.parameters.has("value"):
				_parse_size_parameter(tag.parameters)

func _convert_parameter_value(value_str: String) -> Variant:
	"""パラメータ値を適切な型に変換"""
	value_str = value_str.strip_edges()
	
	if value_str.is_valid_float():
		return value_str.to_float() if "." in value_str else value_str.to_int()
	
	if value_str.to_lower() in ["true", "false"]:
		return value_str.to_lower() == "true"
	
	if value_str.begins_with("\"") and value_str.ends_with("\""):
		return value_str.substr(1, value_str.length() - 2)
	
	return value_str

func _parse_size_parameter(parameters: Dictionary):
	"""サイズパラメータを解析"""
	var raw_value = parameters.get("raw_value", "0")
	var size_value = str(parameters.get("value", "0"))
	
	if raw_value.begins_with("+") or raw_value.begins_with("-"):
		parameters["relative"] = true
		parameters["change"] = int(size_value)
	else:
		parameters["relative"] = false
		parameters["size"] = int(size_value)

func _parse_color_string(color_str: String) -> Color:
	"""色文字列をColor型に変換"""
	match color_str.to_lower():
		"red": return Color.RED
		"green": return Color.GREEN
		"blue": return Color.BLUE
		"yellow": return Color.YELLOW
		"white": return Color.WHITE
		"black": return Color.BLACK
		"cyan": return Color.CYAN
		"magenta": return Color.MAGENTA
		_:
			if color_str.begins_with("#"):
				return Color.html(color_str)
			else:
				return Color.WHITE

func _convert_to_bbcode(tag_name: String, param: String, is_end_tag: bool, tag_info: Dictionary) -> String:
	"""装飾タグをBBCodeに変換"""
	if is_end_tag:
		return "[/" + tag_info.bbcode + "]"
	
	var bbcode_name = tag_info.bbcode
	
	if param.is_empty():
		return "[" + bbcode_name + "]"
	else:
		# パラメータ処理
		match tag_name:
			"color":
				var color = _parse_color_string(param)
				var color_hex = "#%02x%02x%02x" % [int(color.r * 255), int(color.g * 255), int(color.b * 255)]
				return "[color=" + color_hex + "]"
			"size":
				return "[font_size=" + param + "]"
			"a":
				# [a=glossary:sangenjaya]三軒茶屋[/a] -> [url=glossary:sangenjaya]三軒茶屋[/url]
				return "[url=" + param + "]"
			_:
				return "[" + bbcode_name + "=" + param + "]"

func _process_custom_decoration_tag(tag_name: String, param: String, is_end_tag: bool, custom_tag: Dictionary) -> String:
	"""カスタム装飾タグを処理"""
	if custom_command_handler and custom_command_handler.has_method("process_custom_decoration_tag"):
		return custom_command_handler.process_custom_decoration_tag(tag_name, param, is_end_tag, custom_tag)
	return ""

# === 即座実行コマンド実行 ===

func execute_immediate_commands(commands: Array[Dictionary], adv_system: Node):
	"""即座実行コマンドを実行"""
	for cmd in commands:
		print("🎯 Executing immediate tag command: ", cmd.command, " with params: ", cmd.parameters)
		
		match cmd.command:
			"w", "wait":
				var duration = cmd.parameters.get("duration", 1.0)
				if adv_system:
					await adv_system.get_tree().create_timer(duration).timeout
			"clear":
				if adv_system and adv_system.has_method("clear_text_effects"):
					adv_system.clear_text_effects()
			"shake":
				if adv_system and adv_system.has_method("shake_screen"):
					var intensity = cmd.parameters.get("intensity", 2.0)
					var duration = cmd.parameters.get("duration", 0.3)
					adv_system.shake_screen(intensity, duration)
			_:
				# カスタムコマンドとして実行
				if custom_command_handler:
					custom_command_handler.call_deferred("_on_custom_command_executed", cmd.command, cmd.parameters, cmd.original)

# === カスタムタグ管理 ===

func register_custom_tag(tag_name: String, tag_type: TagType, properties: Dictionary = {}):
	"""カスタムタグを登録"""
	custom_tags[tag_name] = {
		"type": tag_type,
		"properties": properties
	}
	print("✅ Registered custom tag: ", tag_name, " type: ", tag_type)

func unregister_custom_tag(tag_name: String) -> bool:
	"""カスタムタグの登録を削除"""
	if custom_tags.has(tag_name):
		custom_tags.erase(tag_name)
		print("✅ Unregistered custom tag: ", tag_name)
		return true
	return false

func get_supported_tags() -> Array[String]:
	"""サポートされているタグ一覧を返す"""
	var tags: Array[String] = []
	tags.append_array(immediate_tags.keys())
	tags.append_array(decoration_tags.keys())
	tags.append_array(custom_tags.keys())
	return tags

func get_tag_help(tag_name: String) -> String:
	"""タグのヘルプを返す"""
	match tag_name:
		"w", "wait":
			return "Wait: {w=1.5} - Wait for specified seconds"
		"p", "pause":
			return "Pause: {p} - Wait for player input during typewriter"
		"shake":
			return "Shake: {shake} - Screen shake effect"
		"clear":
			return "Clear: {clear} - Clear all text effects"
		"color":
			return "Color: {color=red}text{/color} - Text color decoration"
		"size":
			return "Size: {size=18}text{/size} - Text size decoration"
		"b":
			return "Bold: {b}text{/b} - Bold text decoration"
		"i":
			return "Italic: {i}text{/i} - Italic text decoration"
		"u":
			return "Underline: {u}text{/u} - Underline text decoration"
		_:
			if custom_tags.has(tag_name):
				return "Custom tag: " + tag_name + " - " + str(custom_tags[tag_name])
			return "Unknown tag: " + tag_name
