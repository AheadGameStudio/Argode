extends JumpCommand
class_name CallCommand
## Call命令 - Universal Block Execution対応版
##
## 設計思想:
## - ExecutionPathManagerによる軽量パス管理
## - execute_block()による独立ブロック実行
## - 複雑な子コンテキスト管理を排除
## - 静的スタック廃止でサービス不要

# ExecutionPathManager handles call/return path management
# No static variables needed

func _ready():
	command_class_name = "CallCommand"
	command_execute_name = "call"
	command_description = "指定されたラベルを呼び出し、returnで戻ります"
	command_help = "call label_name"

## 引数検証 - 親クラス（Jump）の検証を活用
func validate_args(args: Dictionary) -> bool:
	# JumpCommandの引数検証をそのまま使用
	if not super.validate_args(args):
		return false
	
	# Universal Block Execution: Return存在チェックは不要
	# ExecutionPathManagerが自動的に管理
	return true

## Universal Block Execution対応のコマンド中核処理  
func execute_core(args: Dictionary) -> void:
	var label_name = get_required_arg(args, "0", "Call先ラベル名")
	
	if label_name == null:
		return
	
	print("🎯 CALL: Starting call to '%s'" % label_name)
	
	# StatementManagerとExecutionServiceを取得
	var statement_manager = ArgodeSystem.StatementManager
	var execution_service = args.get("execution_service", null)
	var execution_path_manager = args.get("execution_path_manager", null)
	
	if not statement_manager or not execution_service:
		log_error("StatementManager or ExecutionService not available")
		return
	
	if not execution_path_manager:
		log_error("ExecutionPathManager not available")
		return
	
	# Universal Block Execution: ExecutionPathManagerでパス管理
	var label_info = ArgodeSystem.LabelRegistry.get_label(label_name)
	if label_info.is_empty():
		log_error("ラベル '%s' が見つかりません" % label_name)
		return
	
	# 効率的なラベルステートメント取得（ファイル読み込み一度だけ）
	var label_statements = statement_manager.get_label_statements(label_name)
	if label_statements.is_empty():
		log_error("ラベル '%s' にステートメントが見つかりません" % label_name)
		return
	
	print("🎯 CALL: Found %d statements in label '%s'" % [label_statements.size(), label_name])
	
	# Universal Block Execution: Call先ブロックを独立して実行
	# ExecutionPathManagerが自動的にパス管理を行う
	await execution_service.execute_block(label_statements, "call_" + label_name, label_name)
	
	print("🎯 CALL: Call execution completed for '%s'" % label_name)

# Stack management is now handled by ExecutionPathManager
# These methods are deprecated and removed

# Return check is now handled by ExecutionPathManager
# This method is deprecated and removed