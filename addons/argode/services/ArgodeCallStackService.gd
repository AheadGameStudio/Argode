# ArgodeCallStackService.gd
extends RefCounted

class_name ArgodeCallStackService

## Call/Returnスタック専用サービス
## 責任: callコマンドとreturnコマンドの管理、実行位置の保存と復帰

# Call/Returnスタック
var call_stack: Array = []

## callを実行（現在の実行位置をスタックに保存）
func push_call(file_path: String, statement_index: int, context_data: Dictionary = {}) -> bool:
	var call_frame = {
		"file_path": file_path,
		"statement_index": statement_index,
		"context_data": context_data,
		"timestamp": Time.get_ticks_msec()
	}
	
	call_stack.push_back(call_frame)
	
	# 🎬 WORKFLOW: Call実行（GitHub Copilot重要情報）
	ArgodeSystem.log_workflow("Call pushed: %s[%d] (stack depth: %d)" % [file_path, statement_index, call_stack.size()])
	
	return true

## returnを実行（スタックから実行位置を復帰）
func pop_return() -> Dictionary:
	if call_stack.is_empty():
		# 🚨 CRITICAL: 重要なエラー（GitHub Copilot重要情報）
		ArgodeSystem.log_critical("Return called but call stack is empty")
		return {}
	
	var call_frame = call_stack.pop_back()
	
	# 🎬 WORKFLOW: Return実行（GitHub Copilot重要情報）
	ArgodeSystem.log_workflow("Return popped: %s[%d] (stack depth: %d)" % [
		call_frame.get("file_path", ""), 
		call_frame.get("statement_index", -1), 
		call_stack.size()
	])
	
	return call_frame

## スタックの現在の深度を取得
func get_stack_depth() -> int:
	return call_stack.size()

## スタックが空かチェック
func is_stack_empty() -> bool:
	return call_stack.is_empty()

## スタックの最上位フレームを確認（pop せずに参照のみ）
func peek_top_frame() -> Dictionary:
	if call_stack.is_empty():
		return {}
	return call_stack[-1]

## スタックをクリア
func clear_stack():
	var previous_depth = call_stack.size()
	call_stack.clear()
	
	if previous_depth > 0:
		# 🎬 WORKFLOW: スタッククリア（GitHub Copilot重要情報）
		ArgodeSystem.log_workflow("Call stack cleared (%d frames removed)" % previous_depth)

## デバッグ用：スタック全体の状態を出力
func debug_print_stack():
	if call_stack.is_empty():
		# 🔍 DEBUG: スタック状態詳細（通常は非表示）
		ArgodeSystem.log_debug_detail("Call stack is empty")
		return
	
	# 🔍 DEBUG: スタック状態詳細（通常は非表示）
	ArgodeSystem.log_debug_detail("Call stack (depth: %d):" % call_stack.size())
	for i in range(call_stack.size()):
		var frame = call_stack[i]
		ArgodeSystem.log_debug_detail("  [%d] %s[%d]" % [i, frame.get("file_path", ""), frame.get("statement_index", -1)])

## スタックオーバーフローチェック
func check_stack_overflow(max_depth: int = 50) -> bool:
	if call_stack.size() >= max_depth:
		# 🚨 CRITICAL: 重要なエラー（GitHub Copilot重要情報）
		ArgodeSystem.log_critical("Call stack overflow detected (depth: %d)" % call_stack.size())
		return true
	return false
