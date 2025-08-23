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
	
	# ExecutionPathManager統合確認（ログ用のみ）
	debug_execution_path(args)  # ヘルパー関数使用
	
	# ラベルの存在確認（ヘルパー関数使用）
	var label_info = get_label_info(label_name)
	if label_info.is_empty():
		return
	
	var file_path = label_info.get("path", "")
	var label_line = label_info.get("line", 0)
	
	print("🎯 JUMP: Label found at %s (line %d)" % [file_path, label_line])
	
	# Universal Block Execution: ラベルジャンプ実行（ヘルパー関数使用）
	await jump_to_label(label_name)
	
	print("🎯 JUMP: Jump execution completed")