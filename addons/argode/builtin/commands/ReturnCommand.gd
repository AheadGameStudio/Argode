extends ArgodeCommandBase
class_name ReturnCommand
## Return命令 - ExecutionPathManager対応版
##
## 設計思想:
## - ExecutionPathManagerによる戻り先管理
## - execute_block()による独立ブロック実行
## - 複雑なコンテキスト管理を排除
## - 静的スタック廃止でサービス不要

# ExecutionPathManagerへの参照
const ArgodeExecutionPathManager = preload("res://addons/argode/services/ArgodeExecutionPathManager.gd")

func _ready():
	command_class_name = "ReturnCommand"
	command_execute_name = "return"
	command_description = "call元の位置に戻ります"
	command_help = "return"

## 引数検証 - ExecutionPathManager対応版
func validate_args(args: Dictionary) -> bool:
	# ExecutionPathManagerクラス（静的メソッド）を使用
	if ArgodeExecutionPathManager.is_stack_empty():
		log_error("Return実行時にCall contextが存在しません")
		return false
	
	return true

## Universal Block Execution対応のコマンド中核処理
func execute_core(args: Dictionary) -> void:
	print("🎯 RETURN: Starting return process")
	
	# 戻り先情報を取得（静的メソッド使用）
	var return_info = ArgodeExecutionPathManager.pop_execution_point()
	if return_info.is_empty():
		log_error("Return called but no call context exists")
		return
	
	print("🎯 RETURN: Popped return info - label: %s, statement: %d" % [return_info.label_name, return_info.statement_index])
	
	# ExecutionServiceを取得
	var execution_service = args.get("execution_service", null)
	if not execution_service:
		log_error("ExecutionService not found")
		return
	
	# Universal Block Execution: 戻り先ラベルブロックの続きを実行
	var label_name = return_info.label_name
	var continue_index = return_info.statement_index + 1  # Call文の次から再開
	
	print("🎯 RETURN: Returning to '%s' from statement %d" % [label_name, continue_index])
	
	# 戻り先ブロックの残り部分を実行
	await execution_service.execute_block_from_index(label_name, continue_index, "return_" + label_name)
	
	print("🎯 RETURN: Return process completed")
