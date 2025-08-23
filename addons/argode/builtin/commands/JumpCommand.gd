extends ArgodeCommandBase
class_name JumpCommand

func _ready():
	command_class_name = "JumpCommand"
	command_execute_name = "jump"
	command_description = "指定されたラベルにジャンプします"
	command_help = "jump label_name"

## 引数検証（シンプル版）
func validate_args(args: Dictionary) -> bool:
	var label_name = get_optional_arg(args, "0", "")
	if label_name.is_empty():
		log_error("ジャンプ先のラベル名が指定されていません")
		return false
	return true

## Universal Block Execution対応のコマンド中核処理
func execute_core(args: Dictionary) -> void:
	var label_name = get_required_arg(args, "0", "ジャンプ先ラベル名")
	if label_name == null:
		return
	
	print("🎯 JUMP: Jumping to label: %s" % label_name)
	
	# ラベルの存在確認
	var label_info = ArgodeSystem.LabelRegistry.get_label(label_name)
	if label_info.is_empty():
		log_error("ラベル '%s' が見つかりません" % label_name)
		return
	
	var file_path = label_info.get("path", "")
	var label_line = label_info.get("line", 0)
	
	print("🎯 JUMP: Label found at %s (line %d)" % [file_path, label_line])
	
	# StatementManagerを取得
	var statement_manager = ArgodeSystem.StatementManager
	if not statement_manager:
		log_error("StatementManager not found")
		return
	
	# 効率的なラベルステートメント取得（StatementManager活用）
	var label_statements = statement_manager.get_label_statements(label_name)
	if label_statements.is_empty():
		log_error("ラベル '%s' にステートメントが見つかりません" % label_name)
		return
	
	print("🎯 JUMP: Found %d statements in label '%s'" % [label_statements.size(), label_name])
	
	# Universal Block Execution: ラベルブロックを直接実行
	await statement_manager.execute_block(label_statements)
	
	print("🎯 JUMP: Jump execution completed")