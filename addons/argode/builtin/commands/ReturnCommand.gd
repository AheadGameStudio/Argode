extends ArgodeCommandBase
class_name ReturnCommand

func _ready():
	command_class_name = "ReturnCommand"
	command_execute_name = "return"

func execute(args: Dictionary) -> void:
	var statement_manager = args.get("statement_manager")
	
	if not statement_manager:
		log_error("StatementManager not provided")
		return
	
	log_info("Return command executed")
	
	# Call/Returnスタックから戻り先を取得
	var return_context = statement_manager.pop_call_context()
	
	if return_context.is_empty():
		log_error("No call context to return to - Return without Call")
		return
	
	var return_index = return_context.get("return_index", -1)
	var return_file_path = return_context.get("return_file_path", "")
	
	# 子ステートメント実行復帰の特別処理
	if return_index == -2:  # 子ステートメント実行復帰の特別値
		log_info("Returning to child statement execution context")
		# 子ステートメント実行を継続するための特別な戻り値
		statement_manager.command_result = {
			"result": "return_to_child_execution"
		}
		return
	
	if return_index == -1 or return_file_path.is_empty():
		log_error("Invalid return context")
		return
	
	log_info("Returning to index %d in file %s" % [return_index, return_file_path])
	
	# Returnはジャンプ結果として戻り先情報を設定
	statement_manager.command_result = {
		"result": "return",
		"return_index": return_index,
		"return_file_path": return_file_path
	}
