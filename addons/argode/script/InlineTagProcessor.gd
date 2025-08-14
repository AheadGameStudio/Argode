# InlineTagProcessor.gd
# v2新機能: カスタムインラインタグ解析エンジン
extends RefCounted
class_name InlineTagProcessor

# インラインタグの種類
enum TagType {
	WAIT,        # {w=0.5} - 待機
	SHAKE,       # {shake} - シェイク効果
	COLOR,       # {color=red} - 文字色変更
	SIZE,        # {size=+2} - 文字サイズ変更
	SPEED,       # {speed=slow} - タイプライター速度変更
	PAUSE,       # {p} - クリック待ち
	CLEAR,       # {clear} - 効果クリア
	CUSTOM       # その他カスタムタグ
}

# インラインタグ定義（BBCodeと区別するため、独自のタグ名を使用）
var tag_definitions: Dictionary = {
	"w": TagType.WAIT,
	"wait": TagType.WAIT,
	"shake": TagType.SHAKE,
	"icolor": TagType.COLOR,  # インライン色変更（BBCode colorと区別）
	"isize": TagType.SIZE,    # インラインサイズ変更（BBCode sizeと区別）
	"speed": TagType.SPEED,
	"p": TagType.PAUSE,
	"pause": TagType.PAUSE,
	"clear": TagType.CLEAR,
}

# 解析済みタグ情報
class ParsedTag:
	var tag_type: TagType
	var tag_name: String
	var parameters: Dictionary
	var start_position: int
	var end_position: int
	var original_text: String
	
	func _init(type: TagType, name: String, params: Dictionary, start: int, end: int, original: String):
		tag_type = type
		tag_name = name
		parameters = params
		start_position = start
		end_position = end
		original_text = original

# タグ処理結果
class ProcessResult:
	var clean_text: String      # タグが除去されたテキスト
	var tags: Array[ParsedTag]  # 解析されたタグ情報
	var position_mapping: Array[int]  # 元の位置から新しい位置へのマッピング
	
	func _init(initial_text: String = ""):
		clean_text = initial_text
		tags = []
		position_mapping = []

# === メインの解析機能 ===

func process_text(input_text: String) -> ProcessResult:
	"""テキストを解析してインラインタグを抽出・処理"""
	var result = ProcessResult.new(input_text)
	var regex = RegEx.new()
	regex.compile("\\[([^\\]]+)\\]")
	
	result.clean_text = input_text
	var current_clean_position = 0
	var offset = 0
	
	# すべてのタグを検索
	var regex_matches = regex.search_all(input_text)
	
	for regex_match in regex_matches:
		var tag_start = regex_match.get_start()
		var tag_end = regex_match.get_end()
		var full_tag = regex_match.get_string()
		var tag_content = regex_match.get_string(1)
		
		# BBCodeタグかインラインタグかを判定
		if _is_bbcode_tag(tag_content):
			# BBCodeタグはそのまま残す
			continue
		
		# インラインタグを解析
		var parsed_tag = _parse_single_tag(tag_content, tag_start, tag_end, full_tag)
		if parsed_tag:
			# タグが出現するクリーンテキスト内での位置を計算
			var position_in_clean_text = tag_start - offset
			parsed_tag.start_position = position_in_clean_text
			parsed_tag.end_position = position_in_clean_text
			
			# 色変更タグとサイズタグは BBCode に変換してテキストに残す
			if parsed_tag.tag_type == TagType.COLOR:
				var bbcode_tag = _convert_to_bbcode(parsed_tag)
				if not bbcode_tag.is_empty():
					print("🎨 Converting color tag to BBCode: '", full_tag, "' -> '", bbcode_tag, "'")
					result.clean_text = result.clean_text.left(tag_start - offset) + bbcode_tag + result.clean_text.substr(tag_end - offset)
					offset -= bbcode_tag.length() - full_tag.length()  # 長さの差分を調整
				else:
					# BBCode変換失敗時はタグとして処理
					result.tags.append(parsed_tag)
					result.clean_text = result.clean_text.left(tag_start - offset) + result.clean_text.substr(tag_end - offset)
					offset += tag_end - tag_start
			elif parsed_tag.tag_type == TagType.SIZE:
				var bbcode_tag = _convert_to_bbcode(parsed_tag)
				if not bbcode_tag.is_empty():
					print("📏 Converting size tag to BBCode: '", full_tag, "' -> '", bbcode_tag, "'")
					result.clean_text = result.clean_text.left(tag_start - offset) + bbcode_tag + result.clean_text.substr(tag_end - offset)
					offset -= bbcode_tag.length() - full_tag.length()  # 長さの差分を調整
				else:
					# BBCode変換失敗時はタグとして処理
					result.tags.append(parsed_tag)
					result.clean_text = result.clean_text.left(tag_start - offset) + result.clean_text.substr(tag_end - offset)
					offset += tag_end - tag_start
			elif parsed_tag.tag_type == TagType.CUSTOM and (parsed_tag.tag_name.begins_with("/icolor") or parsed_tag.tag_name.begins_with("/isize")):
				# 終了タグもBBCodeに変換
				var bbcode_tag = _convert_to_bbcode(parsed_tag)
				if not bbcode_tag.is_empty():
					print("🎨 Converting end tag to BBCode: '", full_tag, "' -> '", bbcode_tag, "'")
					result.clean_text = result.clean_text.left(tag_start - offset) + bbcode_tag + result.clean_text.substr(tag_end - offset)
					offset -= bbcode_tag.length() - full_tag.length()
				else:
					result.clean_text = result.clean_text.left(tag_start - offset) + result.clean_text.substr(tag_end - offset)
					offset += tag_end - tag_start
			else:
				result.tags.append(parsed_tag)
				# テキストからインラインタグを除去
				result.clean_text = result.clean_text.left(tag_start - offset) + result.clean_text.substr(tag_end - offset)
				offset += tag_end - tag_start
	
	# タグを位置順にソート
	result.tags.sort_custom(func(a, b): return a.start_position < b.start_position)
	
	print("🏷️ InlineTag: Processed '", input_text, "' -> '", result.clean_text, "' with ", result.tags.size(), " tags")
	for tag in result.tags:
		print("   Tag: ", tag.tag_name, " at pos ", tag.start_position, " params: ", tag.parameters)
	
	return result

func _is_bbcode_tag(tag_content: String) -> bool:
	"""BBCodeタグかどうかを判定"""
	# 一般的なBBCodeタグのリスト
	var bbcode_tags = [
		"b", "/b",           # 太字
		"i", "/i",           # 斜体  
		"u", "/u",           # 下線
		"s", "/s",           # 取り消し線
		"color", "/color",   # 色
		"bgcolor", "/bgcolor", # 背景色
		"font", "/font",     # フォント
		"size", "/size",     # サイズ（BBCode版）
		"center", "/center", # 中央揃え
		"right", "/right",   # 右揃え
		"left", "/left",     # 左揃え
		"url", "/url",       # URL
		"img", "/img",       # 画像
		"code", "/code",     # コード
		"table", "/table",   # テーブル
		"cell", "/cell"      # セル
	]
	
	# タグ名を抽出（パラメータを除去）
	var tag_name = tag_content.split("=")[0].split(" ")[0].strip_edges()
	
	return tag_name in bbcode_tags

func _convert_to_bbcode(parsed_tag: ParsedTag) -> String:
	"""インラインタグをBBCodeに変換"""
	# 終了タグの処理
	if parsed_tag.tag_name.begins_with("/icolor"):
		return "[/color]"
	elif parsed_tag.tag_name.begins_with("/isize"):
		return "[/font_size]"
	
	match parsed_tag.tag_type:
		TagType.COLOR:
			var color = parsed_tag.parameters.get("color", Color.WHITE)
			print("🔍 COLOR case: color=", color, " is_Color=", color is Color)
			if color is Color:
				var color_hex = "#%02x%02x%02x" % [int(color.r * 255), int(color.g * 255), int(color.b * 255)]
				var bbcode_result = "[color=" + color_hex + "]"
				print("🎨 Color conversion: ", color, " -> ", color_hex)
				print("🔍 COLOR case returning: '", bbcode_result, "'")
				return bbcode_result
			else:
				print("⚠️ Invalid color value: ", color, " (type: ", typeof(color), ")")
				return ""
		TagType.SIZE:
			var is_relative = parsed_tag.parameters.get("relative", false)
			if is_relative:
				var change = parsed_tag.parameters.get("change", 0)
				if change != 0:
					var base_size = 16  # 基本フォントサイズ
					var new_size = base_size + change
					print("📏 Size conversion (relative): ", change, " -> ", new_size, "pt")
					return "[font_size=" + str(new_size) + "]"
			else:
				var size = parsed_tag.parameters.get("size", 16)
				print("📏 Size conversion (absolute): ", size, "pt")
				return "[font_size=" + str(size) + "]"
	
	print("⚠️ _convert_to_bbcode: No matching case for tag_type ", parsed_tag.tag_type, " tag_name ", parsed_tag.tag_name)
	return ""

func _parse_single_tag(tag_content: String, tag_start: int, tag_end: int, original_tag: String) -> ParsedTag:
	"""単一のタグを解析"""
	# 終了タグの判定
	var is_end_tag = tag_content.begins_with("/")
	var actual_tag_name = tag_content
	if is_end_tag:
		actual_tag_name = tag_content.substr(1)  # "/" を除去
	
	# パラメータを分離 (例: "color=red" -> name="color", params={"value": "red"})
	var parts = actual_tag_name.split("=", false, 1)
	var tag_name = parts[0].strip_edges()
	var parameters = {}
	
	# 終了タグの場合は特別な処理
	if is_end_tag:
		parameters["is_end_tag"] = true
		# 終了タグは基本的にカスタム処理
		return ParsedTag.new(TagType.CUSTOM, "/" + tag_name, parameters, 0, 0, original_tag)  # 位置は後で設定
	
	if parts.size() > 1:
		var param_value = parts[1].strip_edges()
		parameters["raw_value"] = param_value  # 元の文字列を保持
		parameters["value"] = _convert_parameter_value(param_value)
		
		# 複数パラメータをサポート (例: "shake intensity=3 duration=0.5")
		var extra_params = _parse_extra_parameters(param_value)
		parameters.merge(extra_params)
	
	# タグタイプを決定
	var tag_type = tag_definitions.get(tag_name, TagType.CUSTOM)
	
	# 特殊タグの追加解析
	match tag_type:
		TagType.SHAKE:
			if not parameters.has("value"):
				parameters["intensity"] = 2.0
				parameters["duration"] = 0.3
		TagType.WAIT:
			if parameters.has("value"):
				parameters["duration"] = float(parameters["value"])
			else:
				parameters["duration"] = 1.0
		TagType.SPEED:
			_parse_speed_parameter(parameters)
		TagType.SIZE:
			_parse_size_parameter(parameters)
		TagType.COLOR:
			_parse_color_parameter(parameters)
	
	return ParsedTag.new(tag_type, tag_name, parameters, 0, 0, original_tag)  # 位置は後で設定

func _parse_extra_parameters(param_string: String) -> Dictionary:
	"""追加パラメータを解析 (例: "intensity=3 duration=0.5")"""
	var extra_params = {}
	var tokens = param_string.split(" ")
	
	for token in tokens:
		if "=" in token:
			var kv = token.split("=", false, 1)
			if kv.size() == 2:
				var key = kv[0].strip_edges()
				var value = kv[1].strip_edges()
				extra_params[key] = _convert_parameter_value(value)
	
	return extra_params

func _convert_parameter_value(value_str: String) -> Variant:
	"""パラメータ値を適切な型に変換"""
	value_str = value_str.strip_edges()
	
	# 数値
	if value_str.is_valid_float():
		if "." in value_str:
			return value_str.to_float()
		else:
			return value_str.to_int()
	
	# ブール値
	if value_str.to_lower() in ["true", "false"]:
		return value_str.to_lower() == "true"
	
	# 文字列（クォート除去）
	if value_str.begins_with("\"") and value_str.ends_with("\""):
		return value_str.substr(1, value_str.length() - 2)
	
	return value_str

func _parse_speed_parameter(parameters: Dictionary):
	"""速度パラメータを解析"""
	var speed_value = parameters.get("value", "normal")
	
	match speed_value:
		"slow":
			parameters["multiplier"] = 0.5
		"fast":
			parameters["multiplier"] = 2.0
		"instant":
			parameters["multiplier"] = 100.0
		_:
			# 数値として解析を試行
			if str(speed_value).is_valid_float():
				parameters["multiplier"] = float(speed_value)
			else:
				parameters["multiplier"] = 1.0

func _parse_size_parameter(parameters: Dictionary):
	"""サイズパラメータを解析"""
	# 元の文字列をraw_valueとして保持
	var raw_value = parameters.get("raw_value", "0")
	var size_value = str(parameters.get("value", "0"))
	
	# 元の文字列で+/-を判定
	if raw_value.begins_with("+") or raw_value.begins_with("-"):
		# 相対サイズ
		parameters["relative"] = true
		parameters["change"] = int(size_value)
		print("📏 Size parameter parsing (relative): raw='", raw_value, "' parsed_change=", parameters["change"])
	else:
		# 絶対サイズ
		parameters["relative"] = false
		parameters["size"] = int(size_value)
		print("📏 Size parameter parsing (absolute): raw='", raw_value, "' parsed_size=", parameters["size"])

func _parse_color_parameter(parameters: Dictionary):
	"""色パラメータを解析"""
	var color_value = parameters.get("value", "white")
	parameters["color"] = _parse_color_string(str(color_value))

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

func _build_position_mapping(result: ProcessResult, original_text: String):
	"""位置マッピングを構築"""
	result.position_mapping = []
	var clean_index = 0
	
	for i in range(original_text.length()):
		# この位置がタグ内かチェック
		var in_tag = false
		for tag in result.tags:
			var original_start = original_text.find(tag.original_text)
			var original_end = original_start + tag.original_text.length()
			if i >= original_start and i < original_end:
				in_tag = true
				break
		
		if not in_tag:
			result.position_mapping.append(clean_index)
			clean_index += 1
		else:
			result.position_mapping.append(-1)  # タグ内の位置

# === タグ効果の実行 ===

func execute_tag_at_position(tag: ParsedTag, target_node: Node) -> bool:
	"""指定されたタグの効果を実行"""
	print("🎯 InlineTag: Executing ", tag.tag_name, " with params ", tag.parameters)
	
	match tag.tag_type:
		TagType.WAIT:
			await _execute_wait(tag, target_node)
		TagType.SHAKE:
			_execute_shake(tag, target_node)
		TagType.COLOR:
			_execute_color(tag, target_node)
		TagType.SIZE:
			_execute_size(tag, target_node)
		TagType.SPEED:
			_execute_speed(tag, target_node)
		TagType.PAUSE:
			await _execute_pause(tag, target_node)
		TagType.CLEAR:
			_execute_clear(tag, target_node)
		TagType.CUSTOM:
			_execute_custom(tag, target_node)
		_:
			print("❓ Unknown tag type: ", tag.tag_type)
			return false
	
	return true

func _execute_wait(tag: ParsedTag, target_node: Node):
	"""待機タグの実行"""
	var duration = tag.parameters.get("duration", 1.0)
	print("⏱️ InlineTag: Wait for ", duration, " seconds")
	if target_node:
		await target_node.get_tree().create_timer(duration).timeout

func _execute_shake(tag: ParsedTag, target_node: Node):
	"""シェイクタグの実行"""
	var intensity = tag.parameters.get("intensity", 2.0)
	var duration = tag.parameters.get("duration", 0.3)
	print("📳 InlineTag: Shake effect intensity=", intensity, " duration=", duration)
	print("🔍 Target node: ", target_node, " class: ", target_node.get_class() if target_node else "null")
	
	if target_node:
		print("🔍 Node is Control: ", target_node is Control)
		print("🔍 Node position: ", target_node.position if target_node.has_method("get_position") else "no position")
		print("🔍 Node parent: ", target_node.get_parent() if target_node.get_parent() else "no parent")
		
		if target_node is Control:
			# RichTextLabelなどでのシェイク効果実装
			var original_pos = target_node.position
			print("📳 Starting shake animation from position: ", original_pos)
			print("📳 Shake steps: ", int(duration * 30))
			
			var tween = target_node.create_tween()
			var shake_steps = int(duration * 30)  # 30 FPS
			
			for i in range(shake_steps):
				var shake_offset = Vector2(
					randf_range(-intensity, intensity),
					randf_range(-intensity, intensity)
				)
				var target_pos = original_pos + shake_offset
				print("📳 Step ", i, ": moving to ", target_pos)
				tween.tween_property(target_node, "position", target_pos, duration / shake_steps)
			
			# 元の位置に戻す
			tween.tween_property(target_node, "position", original_pos, 0.1)
			print("📳 Shake animation setup completed, returning to: ", original_pos)
		else:
			print("⚠️ Cannot apply shake: target_node is not a Control node")
	else:
		print("⚠️ Cannot apply shake: target_node is null")

func _execute_color(tag: ParsedTag, target_node: Node):
	"""カラータグの実行"""
	var color = tag.parameters.get("color", Color.WHITE)
	print("🎨 InlineTag: Color change to ", color)
	
	# RichTextLabelの場合、BBCodeタグを動的に挿入
	if target_node and target_node is RichTextLabel:
		print("🎨 InlineTag: Inserting BBCode color tag for RichTextLabel")
		# 実際にはTypewriterTextで処理される
		# ここではログ出力のみ
	elif target_node and target_node.has_method("add_theme_color_override"):
		target_node.add_theme_color_override("default_color", color)
	else:
		print("⚠️ InlineTag: Target node doesn't support color change: ", target_node)

func _execute_size(tag: ParsedTag, target_node: Node):
	"""サイズタグの実行"""
	print("📏 InlineTag: Size change ", tag.parameters)
	
	if target_node and target_node.has_method("add_theme_font_size_override"):
		var current_size = target_node.get_theme_font_size("font_size")
		if current_size <= 0:
			current_size = 14  # デフォルトサイズ
		
		if tag.parameters.get("relative", false):
			var change = tag.parameters.get("change", 0)
			target_node.add_theme_font_size_override("font_size", current_size + change)
		else:
			var new_size = tag.parameters.get("size", current_size)
			target_node.add_theme_font_size_override("font_size", new_size)

func _execute_speed(tag: ParsedTag, target_node: Node):
	"""スピードタグの実行"""
	var multiplier = tag.parameters.get("multiplier", 1.0)
	print("⚡ InlineTag: Speed change to ", multiplier, "x")
	
	# TypewriterTextに速度変更を適用
	if target_node and target_node.has_method("_on_speed_changed"):
		target_node._on_speed_changed(multiplier)
		print("⚡ InlineTag: Speed change applied via direct method call")
	elif target_node and target_node.has_signal("speed_changed"):
		target_node.emit_signal("speed_changed", multiplier)
		print("⚡ InlineTag: Speed change signal emitted")
	else:
		print("⚠️ InlineTag: Target node doesn't support speed change: ", target_node)

func _execute_pause(tag: ParsedTag, target_node: Node):
	"""ポーズタグの実行"""
	print("⏸️ InlineTag: Pause (waiting for input)")
	
	# 入力待ちの実装（簡易版）
	if target_node and target_node.get_tree():
		await target_node.get_tree().process_frame
		# 実際の実装では入力待ちロジックが必要

func _execute_clear(tag: ParsedTag, target_node: Node):
	"""クリアタグの実行"""
	print("🧹 InlineTag: Clear effects")
	
	if target_node and target_node.has_method("add_theme_color_override"):
		target_node.remove_theme_color_override("default_color")
		target_node.remove_theme_font_size_override("font_size")

func _execute_custom(tag: ParsedTag, target_node: Node):
	"""カスタムタグの実行"""
	print("🎯 InlineTag: Custom tag '", tag.tag_name, "' params: ", tag.parameters)
	
	# 終了タグの処理
	if tag.parameters.get("is_end_tag", false):
		print("🔚 InlineTag: End tag for '", tag.tag_name.substr(1), "'")
		# 終了タグは通常、開始タグで設定された効果を終了する
		# 実際の効果終了処理はアプリケーション側で実装
		return
	
	# カスタムシグナルを発行
	if target_node and target_node.has_signal("custom_inline_tag_executed"):
		target_node.emit_signal("custom_inline_tag_executed", tag.tag_name, tag.parameters)

# === ユーティリティ ===

func get_supported_tags() -> Array[String]:
	"""サポートされているタグ一覧を返す"""
	return tag_definitions.keys()

func add_custom_tag(tag_name: String, tag_type: TagType = TagType.CUSTOM):
	"""カスタムタグを追加"""
	tag_definitions[tag_name] = tag_type
	print("➕ InlineTag: Added custom tag '", tag_name, "' with type ", tag_type)

func get_tag_help(tag_name: String) -> String:
	"""タグのヘルプを返す"""
	match tag_name:
		"w", "wait":
			return "Wait: {w=1.5} - Wait for specified seconds"
		"shake":
			return "Shake: {shake} or {shake intensity=3 duration=0.5} - Text shake effect"
		"color":
			return "Color: {color=red} or {color=#ff0000} - Text color change"
		"size":
			return "Size: {size=+2} or {size=18} - Text size change"
		"speed":
			return "Speed: {speed=slow} or {speed=2.0} - Typing speed change"
		"p", "pause":
			return "Pause: {p} - Wait for player input"
		"clear":
			return "Clear: {clear} - Clear all text effects"
		_:
			return "Unknown tag: " + tag_name