class_name TypewriterTextParser
extends RefCounted

## TypewriterTextParser v1.2.0 Phase 2
## テキスト解析専用サービス - 基本機能実装

## === 解析結果構造 ===

class ParseResult:
	var plain_text: String = ""          # プレーンテキスト（表示用）
	var total_length: int = 0            # 総文字数
	var char_positions: Array[int] = []  # 各文字の位置マップ
	var commands: Array = []             # 検出されたコマンド情報
	
	func _init(text: String = ""):
		plain_text = text
		total_length = text.length()

## === 基本API ===

static func parse_text(text: String) -> ParseResult:
	"""テキストを解析してParseResultを返す（Phase 2基本版）"""
	var result = ParseResult.new()
	
	if not text or text.length() == 0:
		return result
	
	# ✅ Task 6-3: 変数展開統合
	var processed_text = _expand_variables(text)
	
	# Phase 2: 基本的なテキストクリーニングのみ
	var cleaned_text = _clean_basic_text(processed_text)
	result.plain_text = cleaned_text
	result.total_length = cleaned_text.length()
	
	# 文字位置マップ生成
	result.char_positions = _generate_position_map(cleaned_text)
	
	# Phase 2: コマンド検出（実行は次フェーズ）
	result.commands = _detect_commands(processed_text)
	
	return result

static func get_substring_at_position(result: ParseResult, position: int) -> String:
	"""指定位置までの表示文字列を取得"""
	if not result or position < 0:
		return ""
	
	var end_pos = min(position, result.total_length)
	return result.plain_text.substr(0, end_pos)

## === 内部処理（Phase 2版） ===

static func _clean_basic_text(text: String) -> String:
	"""基本的なテキストクリーニング（v1.2.0拡張性対応: 動的タグパターン生成）"""
	# Phase 2: 最小限のクリーニング
	var cleaned = text.strip_edges()
	
	# v1.2.0: ArgodeTagRegistryから動的にタグパターンを取得
	var tag_patterns = _get_dynamic_tag_patterns()
	
	# 優先度順でタグ除去を実行
	for pattern_info in tag_patterns:
		var regex = RegEx.new()
		if regex.compile(pattern_info.pattern) == OK:
			cleaned = regex.sub(cleaned, "", true)
		else:
			ArgodeSystem.log("⚠️ Invalid regex pattern: %s" % pattern_info.pattern)
	
	# 連続する空白を単一化
	cleaned = cleaned.replace("\t", " ")
	while cleaned.contains("  "):
		cleaned = cleaned.replace("  ", " ")
	
	return cleaned

## v1.2.0: TagRegistryから動的にタグパターンを取得
static func _get_dynamic_tag_patterns() -> Array:
	"""登録されたタグコマンドから動的にパターンを生成"""
	var patterns: Array = []
	
	# ArgodeTagRegistryから全タグを取得
	var tag_registry = ArgodeSystem.get_registry("tag")
	if not tag_registry:
		ArgodeSystem.log("🚨 CRITICAL: TagRegistry not available - system not properly initialized", 2)
		return []  # 空配列を返し、タグ除去をスキップ
	
	# 各タグコマンドからパターンを収集
	var commands_with_priority: Array = []
	for tag_name in tag_registry.get_tag_names():
		var command_data = tag_registry.get_tag_command(tag_name)
		if command_data.has("instance"):
			var command_instance: ArgodeCommandBase = command_data.instance
			var tag_patterns = command_instance.get_tag_patterns()
			var custom_patterns = command_instance.get_custom_tag_patterns()
			var priority = command_instance.get_tag_removal_priority()
			
			# 通常のタグパターンを追加
			for pattern in tag_patterns:
				commands_with_priority.append({
					"pattern": pattern,
					"priority": priority,
					"command": tag_name
				})
			
			# カスタムパターンを追加
			for pattern in custom_patterns:
				commands_with_priority.append({
					"pattern": pattern,
					"priority": priority - 10,  # カスタムパターンは優先度高め
					"command": tag_name + "_custom"
				})
	
	# 優先度順でソート（小さい数値が先）
	commands_with_priority.sort_custom(func(a, b): return a.priority < b.priority)
	
	ArgodeSystem.log("🏷️ Generated %d dynamic tag patterns from TagRegistry" % commands_with_priority.size())
	return commands_with_priority

static func _generate_position_map(text: String) -> Array[int]:
	"""文字位置マップを生成"""
	var positions: Array[int] = []
	
	for i in range(text.length()):
		positions.append(i)
	
	return positions

static func _detect_commands(text: String) -> Array:
	"""コマンドを検出（Phase 2: 検出のみ、実行は後のフェーズ）"""
	var commands: Array = []
	
	ArgodeSystem.log("🔍 [PARSER] Detecting commands in text: '%s'" % text)
	
	# Phase 2: 単一タグパターン検出 {w=1.0}
	var single_regex = RegEx.new()
	single_regex.compile(r"\{(\w+)([^}]*)\}")
	
	var single_results = single_regex.search_all(text)
	for regex_result in single_results:
		var tag_type = regex_result.get_string(1)
		var is_decoration = _is_decoration_command(tag_type)
		
		# 装飾コマンドでない場合のみ単一タグとして登録
		if not is_decoration:
			var command_info = {
				"type": tag_type,
				"params": regex_result.get_string(2),
				"start": regex_result.get_start(),
				"end": regex_result.get_end(),
				"is_pair": false
			}
			commands.append(command_info)
			ArgodeSystem.log("🔍 [PARSER] Single tag found: %s at %d-%d" % [command_info.type, command_info.start, command_info.end])
	
	# Phase 2: ペアタグパターン検出 {color=red}...{/color}（装飾コマンド専用）
	var pair_regex = RegEx.new()
	pair_regex.compile(r"\{(\w+)([^}]*)\}([^{]*)\{/\1\}")
	
	var pair_results = pair_regex.search_all(text)
	for regex_result in pair_results:
		var tag_type = regex_result.get_string(1)
		var tag_params = regex_result.get_string(2)
		var tag_content = regex_result.get_string(3)
		
		# 装飾コマンドの場合のみペアタグとして登録
		if _is_decoration_command(tag_type):
			var command_info = {
				"type": tag_type,
				"params": tag_params,
				"content": tag_content,
				"start": regex_result.get_start(),
				"end": regex_result.get_end(),
				"is_pair": true
			}
			commands.append(command_info)
			ArgodeSystem.log("🔍 [PARSER] Decoration pair tag found: %s='%s' content='%s' at %d-%d" % [tag_type, tag_params, tag_content, command_info.start, command_info.end])
		else:
			ArgodeSystem.log("⚠️ [PARSER] Non-decoration command with closing tag ignored: %s" % tag_type)
	
	ArgodeSystem.log("🔍 [PARSER] Total commands detected: %d" % commands.size())
	
	return commands

## 装飾コマンド判定ヘルパー
static func _is_decoration_command(command_type: String) -> bool:
	"""指定されたコマンドが装飾コマンドかどうかを判定"""
	# 既知の装飾コマンド
	var decoration_commands = ["color", "scale", "ruby", "bold", "italic", "underline"]
	return command_type in decoration_commands

## ✅ Task 6-3: 変数展開機能統合
static func _expand_variables(text: String) -> String:
	"""[variable_name]パターンの変数を展開"""
	if not ArgodeSystem or not ArgodeSystem.VariableManager:
		return text
	
	# ArgodeVariableResolverを使用して変数展開
	var variable_resolver = ArgodeVariableResolver.new(ArgodeSystem.VariableManager)
	return variable_resolver.resolve_text(text)
