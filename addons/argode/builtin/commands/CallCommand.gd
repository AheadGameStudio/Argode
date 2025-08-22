extends ArgodeCommandBase
class_name CallCommand

func _ready():
	command_class_name = "CallCommand"
	command_execute_name = "call"

func execute(args: Dictionary) -> void:
	var parsed_line = args.get("parsed_line", [])
	var statement_manager = args.get("statement_manager")
	
	log_debug("CallCommand: Received parsed_line: %s" % str(parsed_line))
	
	if not statement_manager:
		log_error("StatementManager not provided")
		return
	
	if parsed_line.size() < 1:
		log_error("Call command requires a label name")
		return
	
	var label_name = parsed_line[0]  # 最初の要素がラベル名
	ArgodeSystem.log_critical("🎯 CALL_DEBUG: ===== CALL EXECUTION START =====")
	ArgodeSystem.log_critical("🎯 CALL_DEBUG: Calling label '%s'" % label_name)
	
	# ラベルレジストリからラベル情報を取得
	var label_info = ArgodeSystem.LabelRegistry.get_label(label_name)
	ArgodeSystem.log_critical("🎯 CALL_DEBUG: Label '%s' info: %s" % [label_name, str(label_info)])
	
	if label_info.is_empty():
		log_error("Label '%s' not found" % label_name)
		return
	
	var label_file_path = label_info.get("path", "")
	var label_line = label_info.get("line", -1)
	
	if label_file_path.is_empty() or label_line == -1:
		log_error("Invalid label info for '%s'" % label_name)
		return
	
	# Call先のラベルブロックにReturnが存在するかチェック
	if not _check_return_in_label_block(label_file_path, label_line):
		log_error("No 'return' command found in label block '%s' - Call requires Return" % label_name)
		return
	
	# 新しい設計：現在の実行位置を保存（子コンテキスト完了後の復帰用）
	var current_index = statement_manager.execution_service.current_statement_index
	var current_file = statement_manager.execution_service.current_file_path
	
	# Call/Returnスタックに現在位置を保存（次のstatementから実行再開するため+1）
	statement_manager.push_call_context(current_file, current_index + 1)
	log_debug("CallCommand: Call stack pushed - next_index=%d, file=%s" % [current_index + 1, current_file])
	
	
	# Call先のラベルブロックをパースして子コンテキストとして実行
	log_info("Call parsing label block '%s' at line %d" % [label_name, label_line])
	ArgodeSystem.log_critical("🎯 CALL_DEBUG: Parsing label block '%s' at %s:%d" % [label_name, label_file_path, label_line])
	
	# StatementManagerのparse_label_blockメソッドを使用してCall先のラベルブロックをパース
	ArgodeSystem.log_critical("🎯 CALL_DEBUG: About to call StatementManager.parse_label_block(%s, %s)" % [label_file_path, label_name])
	var call_statements = await statement_manager.parse_label_block(label_file_path, label_name)
	ArgodeSystem.log_critical("🎯 CALL_DEBUG: parse_label_block returned %d statements" % call_statements.size())
	
	if call_statements.is_empty():
		log_error("Failed to parse label block '%s'" % label_name)
		ArgodeSystem.log_critical("🎯 CALL_DEBUG: ❌ PARSE FAILED - No statements found for '%s'" % label_name)
		return
	
	ArgodeSystem.log_critical("🎯 CALL_DEBUG: ✅ PARSE SUCCESS - Parsed %d statements from '%s'" % [call_statements.size(), label_name])
	
	# ContextServiceを使用して子コンテキストとしてCall先を実行
	var context_service = statement_manager.context_service
	if not context_service:
		log_error("ContextService not available")
		ArgodeSystem.log_critical("🎯 CALL_DEBUG: ❌ CONTEXT SERVICE NOT FOUND")
		return
	
	ArgodeSystem.log_critical("🎯 CALL_DEBUG: About to push context for '%s'" % label_name)
	
	# Call先のステートメントを子コンテキストにプッシュ
	context_service.push_context(call_statements, "call_" + label_name)
	ArgodeSystem.log_critical("🎯 CALL_DEBUG: Call context pushed for '%s' (%d statements)" % [label_name, call_statements.size()])
	ArgodeSystem.log_critical("🎯 CALL_DEBUG: ===== CALL EXECUTION COMPLETE =====")

	log_info("Call command completed for label: %s" % label_name)

func _check_return_in_label_block(file_path: String, label_line: int) -> bool:
	"""指定されたラベルブロック内にreturnコマンドが存在するかチェック"""
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	if not file:
		log_error("Could not load file: %s" % file_path)
		return false
	
	var content = file.get_as_text()
	file.close()
	
	if content.is_empty():
		log_error("File is empty: %s" % file_path)
		return false
	
	var lines = content.split("\n")
	
	# ラベル行を探す（現在のArgode記法: "label label_name:"）
	var label_index = -1
	for i in range(lines.size()):
		var line = lines[i].strip_edges()
		if line.begins_with("label ") and i + 1 == label_line:  # 行番号は1ベース
			label_index = i
			break
	
	if label_index == -1:
		log_error("Label line %d not found in file" % label_line)
		return false
	
	# ラベルブロックの範囲を特定（次のラベルまで、またはファイル終端まで）
	var block_start = label_index + 1
	var block_end = lines.size()
	
	for i in range(block_start, lines.size()):
		var line = lines[i].strip_edges()
		if line.begins_with("label "):  # 次のラベルが見つかった
			block_end = i
			break
	
	# ブロック内でreturnコマンドを探す
	for i in range(block_start, block_end):
		var line = lines[i].strip_edges()
		if line.strip_edges() == "return":
			log_debug("Found 'return' command in label block at line %d" % (i + 1))
			return true
	
	log_error("No 'return' command found in label block (lines %d-%d)" % [block_start + 1, block_end])
	return false