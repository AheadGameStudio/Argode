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
	log_info("Calling label '%s'" % label_name)
	
	# ラベルレジストリからラベル情報を取得
	var label_info = ArgodeSystem.LabelRegistry.get_label(label_name)
	
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
	
	# 現在の実行コンテキストに基づいて正しい戻り位置を計算
	var current_index = statement_manager.current_statement_index
	var current_file = statement_manager.current_file_path
	var return_index = statement_manager.calculate_return_index()
	
	# 子ステートメント実行中の場合は特別処理
	if return_index == -1:  # 子ステートメント実行中
		# 子ステートメント実行コンテキストに戻る必要がある
		# Return時に子ステートメント実行を継続するための情報を保存
		var child_context = {
			"type": "child_statement_return",
			"parent_context": statement_manager.execution_context_stack.back() if statement_manager.execution_context_stack.size() > 0 else {},
			"return_to_child_execution": true
		}
		statement_manager.push_call_context(-2, current_file)  # -2は子ステートメント実行復帰の特別値
		log_debug("CallCommand: Child statement context - will return to child execution")
	else:
		# 通常のCall/Return処理
		statement_manager.push_call_context(return_index, current_file)
		log_debug("CallCommand: current_index=%d, return_index=%d, file=%s" % [current_index, return_index, current_file])
	
	
	# 指定されたラベルにジャンプ
	log_info("Call jumping to label '%s' at line %d" % [label_name, label_line])
	
	# JumpCommandと同様にjump結果を返す
	statement_manager.command_result = {
		"result": "jump",
		"label": label_name,
		"file_path": label_file_path,
		"line": label_line
	}

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