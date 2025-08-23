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
	
	# Phase 2: 基本的なテキストクリーニングのみ
	var cleaned_text = _clean_basic_text(text)
	result.plain_text = cleaned_text
	result.total_length = cleaned_text.length()
	
	# 文字位置マップ生成
	result.char_positions = _generate_position_map(cleaned_text)
	
	# Phase 2: コマンド検出（実行は次フェーズ）
	result.commands = _detect_commands(text)
	
	return result

static func get_substring_at_position(result: ParseResult, position: int) -> String:
	"""指定位置までの表示文字列を取得"""
	if not result or position < 0:
		return ""
	
	var end_pos = min(position, result.total_length)
	return result.plain_text.substr(0, end_pos)

## === 内部処理（Phase 2版） ===

static func _clean_basic_text(text: String) -> String:
	"""基本的なテキストクリーニング（Phase 3拡張: タグ除去対応）"""
	# Phase 2: 最小限のクリーニング
	var cleaned = text.strip_edges()
	
	# Phase 3: waitタグを除去
	var regex = RegEx.new()
	regex.compile(r"\{(w|wait)=([0-9.]+)\}")
	cleaned = regex.sub(cleaned, "", true)  # 全てのwaitタグを除去
	
	# 連続する空白を単一化
	cleaned = cleaned.replace("\t", " ")
	while cleaned.contains("  "):
		cleaned = cleaned.replace("  ", " ")
	
	return cleaned

static func _generate_position_map(text: String) -> Array[int]:
	"""文字位置マップを生成"""
	var positions: Array[int] = []
	
	for i in range(text.length()):
		positions.append(i)
	
	return positions

static func _detect_commands(text: String) -> Array:
	"""コマンドを検出（Phase 2: 検出のみ、実行は後のフェーズ）"""
	var commands: Array = []
	
	# Phase 2: 基本的なパターン検出
	var regex = RegEx.new()
	regex.compile(r"\{(\w+)([^}]*)\}")
	
	var results = regex.search_all(text)
	for regex_result in results:
		var command_info = {
			"type": regex_result.get_string(1),
			"params": regex_result.get_string(2),
			"start": regex_result.get_start(),
			"end": regex_result.get_end()
		}
		commands.append(command_info)
	
	return commands
