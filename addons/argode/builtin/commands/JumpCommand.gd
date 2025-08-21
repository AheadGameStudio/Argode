extends ArgodeCommandBase
class_name JumpCommand

func _ready():
	command_class_name = "JumpCommand"
	command_execute_name = "jump"
	command_description = "指定されたラベルにジャンプします"
	command_help = "jump label_name"

## 引数検証
func validate_args(args: Dictionary) -> bool:
	var label_name = get_optional_arg(args, "arg0", "")
	if label_name.is_empty():
		log_error("ジャンプ先のラベル名が指定されていません")
		return false
	return true

## コマンド中核処理
func execute_core(args: Dictionary) -> void:
	var label_name = get_required_arg(args, "arg0", "ジャンプ先ラベル名")
	
	if label_name == null:
		return
	
	log_info("Jumping to label: %s" % label_name)
	
	# ラベルの存在確認
	var label_info = ArgodeSystem.LabelRegistry.get_label(label_name)
	if label_info.is_empty():
		log_error("ラベル '%s' が見つかりません" % label_name)
		return
	
	var file_path = label_info.get("path", "")
	var label_line = label_info.get("line", 0)
	
	log_info("Label found: %s at %s (line %d)" % [label_name, file_path, label_line])
	
	# StatementManagerの汎用インターフェースを使用してジャンプを実行
	var statement_manager = ArgodeSystem.StatementManager
	if not statement_manager:
		log_error("StatementManager not found")
		return
	
	# StatementManagerの実行を一時停止してジャンプ処理を実行
	statement_manager.set_waiting_for_command(true, "JumpCommand executing")
	
	# ジャンプ結果をStatementManagerに送信
	statement_manager.handle_command_result({
		"type": "jump",
		"label": label_name,
		"file_path": file_path,
		"line": label_line
	})
	
	# ジャンプ完了後、StatementManagerの実行を再開
	statement_manager.set_waiting_for_command(false, "JumpCommand completed")
	
	log_info("Jump command executed successfully")