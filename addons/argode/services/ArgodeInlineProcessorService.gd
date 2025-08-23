extends RefCounted
class_name ArgodeInlineProcessorService

# ===========================
# Argode Inline Command Processor Service
# ===========================
# インラインコマンド（{color}, {scale}, {move}等）の解析と処理を担当
# MessageRendererから分離して専門化

# ===========================
# Dependencies
# ===========================
var inline_command_manager: ArgodeInlineCommandManager

# ===========================
# Processing Results
# ===========================
var display_text: String = ""
var position_commands: Array = []
var processing_error: String = ""

func _init():
	# ArgodeInlineCommandManagerを直接作成
	var inline_command_script = load("res://addons/argode/managers/ArgodeInlineCommandManager.gd")
	if inline_command_script:
		inline_command_manager = inline_command_script.new()
		ArgodeSystem.log("✅ InlineProcessorService initialized with InlineCommandManager", ArgodeSystem.LOG_LEVEL.DEBUG)
	else:
		ArgodeSystem.log("❌ Failed to load ArgodeInlineCommandManager", ArgodeSystem.LOG_LEVEL.CRITICAL)

# ===========================
# Main Processing Pipeline
# ===========================
func process_text_with_inline_commands(raw_text: String) -> Dictionary:
	"""
	インラインコマンドを含むテキストを処理し、表示用テキストとコマンド配列を返す
	
	Args:
		raw_text: インラインコマンドを含む生テキスト（例: "これは{color=#ff0000}赤い{/color}文字"）
		
	Returns:
		Dictionary: {
			"success": bool,
			"display_text": String,  # 表示用テキスト（タグ除去済み）
			"position_commands": Array,  # インラインコマンド配列
			"error": String  # エラーがある場合のメッセージ
		}
	"""
	ArgodeSystem.log("🔍 InlineProcessor: Processing text: '%s'" % raw_text, ArgodeSystem.LOG_LEVEL.DEBUG)
	
	# 初期化
	display_text = ""
	position_commands = []
	processing_error = ""
	
	if not inline_command_manager:
		processing_error = "InlineCommandManager not available"
		ArgodeSystem.log("❌ InlineCommandManager not found", ArgodeSystem.LOG_LEVEL.CRITICAL)
		return _create_error_result(processing_error)
	
	# インラインコマンドがない場合は素通し
	if not _has_inline_commands(raw_text):
		ArgodeSystem.log("🔍 No inline commands found, returning text as-is", ArgodeSystem.LOG_LEVEL.DEBUG)
		return {
			"success": true,
			"display_text": raw_text,
			"position_commands": [],
			"error": ""
		}
	
	# インラインコマンド処理を実行
	var parse_result = _parse_inline_commands(raw_text)
	
	if not parse_result.success:
		processing_error = parse_result.error
		ArgodeSystem.log("❌ Inline command parsing failed: %s" % processing_error, ArgodeSystem.LOG_LEVEL.CRITICAL)
		return _create_error_result(processing_error)
	
	# 結果を返す
	ArgodeSystem.log("✅ Inline processing completed - display_text: '%s', commands: %d" % [parse_result.display_text, parse_result.position_commands.size()], ArgodeSystem.LOG_LEVEL.DEBUG)
	
	return {
		"success": true,
		"display_text": parse_result.display_text,
		"position_commands": parse_result.position_commands,
		"error": ""
	}

# ===========================
# Inline Command Detection
# ===========================
func _has_inline_commands(text: String) -> bool:
	"""インラインコマンドが含まれているかチェック"""
	return text.contains("{") and text.contains("}")

# ===========================
# Inline Command Parsing
# ===========================
func _parse_inline_commands(raw_text: String) -> Dictionary:
	"""
	インラインコマンドを解析してposition_commandsに変換する
	
	Returns:
		Dictionary: {
			"success": bool,
			"display_text": String,
			"position_commands": Array,
			"error": String
		}
	"""
	# ArgodeInlineCommandManagerのprocess_textメソッドを使用
	if not inline_command_manager.has_method("process_text"):
		return _create_error_result("InlineCommandManager doesn't have process_text method")
	
	var result = inline_command_manager.process_text(raw_text)
	
	# 結果の妥当性チェック
	if result == null:
		return _create_error_result("Parse result is null")
	
	# 結果の形式を確認・正規化
	if typeof(result) == TYPE_DICTIONARY:
		# Dictionaryの場合
		var parsed_text = result.get("display_text", "")
		var commands = result.get("position_commands", [])
		
		if parsed_text.is_empty():
			return _create_error_result("Parsed text is empty")
		
		return {
			"success": true,
			"display_text": parsed_text,
			"position_commands": commands,
			"error": ""
		}
	else:
		return _create_error_result("Unexpected parse result format: %s" % str(result))

# ===========================
# Result Helpers
# ===========================
func _create_error_result(error_message: String) -> Dictionary:
	"""エラー結果を作成"""
	return {
		"success": false,
		"display_text": "",
		"position_commands": [],
		"error": error_message
	}

func _create_fallback_result(original_text: String) -> Dictionary:
	"""フォールバック結果を作成（インラインコマンド処理失敗時）"""
	ArgodeSystem.log("⚠️ Using fallback - displaying text without inline processing", ArgodeSystem.LOG_LEVEL.WORKFLOW)
	return {
		"success": true,
		"display_text": original_text,
		"position_commands": [],
		"error": "Fallback mode - inline commands not processed"
	}

# ===========================
# Debug and Validation
# ===========================
func validate_position_commands(commands: Array) -> bool:
	"""position_commandsの妥当性をチェック"""
	for cmd in commands:
		if typeof(cmd) != TYPE_DICTIONARY:
			ArgodeSystem.log("❌ Invalid command type: %s" % str(cmd), ArgodeSystem.LOG_LEVEL.DEBUG)
			return false
		
		if not cmd.has("position") or not cmd.has("command"):
			ArgodeSystem.log("❌ Missing required fields in command: %s" % str(cmd), ArgodeSystem.LOG_LEVEL.DEBUG)
			return false
	
	return true

func debug_print_processing_result(result: Dictionary) -> void:
	"""処理結果をデバッグ出力"""
	ArgodeSystem.log("🔍 Processing Result:", ArgodeSystem.LOG_LEVEL.DEBUG)
	ArgodeSystem.log("  Success: %s" % result.get("success", false), ArgodeSystem.LOG_LEVEL.DEBUG)
	ArgodeSystem.log("  Display Text: '%s'" % result.get("display_text", ""), ArgodeSystem.LOG_LEVEL.DEBUG)
	ArgodeSystem.log("  Commands Count: %d" % result.get("position_commands", []).size(), ArgodeSystem.LOG_LEVEL.DEBUG)
	
	if result.has("error") and not result.error.is_empty():
		ArgodeSystem.log("  Error: %s" % result.error, ArgodeSystem.LOG_LEVEL.DEBUG)
	
	var commands = result.get("position_commands", [])
	for i in range(commands.size()):
		ArgodeSystem.log("  Command %d: %s" % [i, str(commands[i])], ArgodeSystem.LOG_LEVEL.DEBUG)

# ===========================
# Public API for Direct Usage
# ===========================
func get_display_text() -> String:
	"""最後に処理された表示用テキストを取得"""
	return display_text

func get_position_commands() -> Array:
	"""最後に処理されたposition_commandsを取得"""
	return position_commands

func get_last_error() -> String:
	"""最後に発生したエラーメッセージを取得"""
	return processing_error

func has_processing_error() -> bool:
	"""処理エラーが発生したかチェック"""
	return not processing_error.is_empty()
