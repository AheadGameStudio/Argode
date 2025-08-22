# ArgodeContextService.gd
extends RefCounted

class_name ArgodeContextService

## 実行コンテキスト管理サービス
## 責任: 子ステートメント実行、実行コンテキストスタック、ネストした実行の管理

# 実行コンテキストスタック（ネストした実行用）
var context_stack: Array = []

## 現在のコンテキストをスタックに保存して新しいコンテキストに移行
func push_context(statements: Array, context_name: String = "", context_data: Dictionary = {}) -> bool:
	if statements.is_empty():
		# 🚨 CRITICAL: 重要なエラー（GitHub Copilot重要情報）
		ArgodeSystem.log_critical("Cannot push empty context")
		return false
	
	# 現在のコンテキスト情報を保存
	var current_context = {
		"context_name": context_name,
		"statements": statements,
		"statement_index": 0,
		"context_data": context_data,
		"timestamp": Time.get_ticks_msec()
	}
	
	context_stack.push_back(current_context)
	
	# 🎬 WORKFLOW: コンテキスト開始（GitHub Copilot重要情報）
	ArgodeSystem.log_workflow("Context pushed: %s (%d statements, depth: %d)" % [
		context_name if context_name != "" else "unnamed",
		statements.size(),
		context_stack.size()
	])
	
	return true

## コンテキストスタックから復帰
func pop_context() -> Dictionary:
	if context_stack.is_empty():
		# 🚨 CRITICAL: 重要なエラー（GitHub Copilot重要情報）
		ArgodeSystem.log_critical("Cannot pop context: stack is empty")
		return {}
	
	var context = context_stack.pop_back()
	
	# 🎬 WORKFLOW: コンテキスト復帰（GitHub Copilot重要情報）
	ArgodeSystem.log_workflow("Context popped: %s (depth: %d)" % [
		context.get("context_name", "unnamed"),
		context_stack.size()
	])
	
	return context

## 現在のコンテキスト深度を取得
func get_context_depth() -> int:
	return context_stack.size()

## コンテキストスタックが空かチェック
func is_context_stack_empty() -> bool:
	return context_stack.is_empty()

## 現在のコンテキストを取得（最上位フレーム）
func get_current_context() -> Dictionary:
	if context_stack.is_empty():
		return {}
	return context_stack[-1]

## コンテキストスタックをクリア
func clear_context_stack():
	var previous_depth = context_stack.size()
	context_stack.clear()
	
	if previous_depth > 0:
		# 🎬 WORKFLOW: コンテキストクリア（GitHub Copilot重要情報）
		ArgodeSystem.log_workflow("Context stack cleared (%d contexts removed)" % previous_depth)

## 子ステートメント用の特別なコンテキスト管理
func execute_child_statements(child_statements: Array, parent_context: String = "") -> bool:
	if child_statements.is_empty():
		# 🔍 DEBUG: 子ステートメント実行詳細（通常は非表示）
		ArgodeSystem.log_debug_detail("No child statements to execute")
		return true
	
	var context_name = "child_" + parent_context if parent_context != "" else "child_statements"
	return push_context(child_statements, context_name, {"parent": parent_context})

## コンテキストオーバーフローチェック
func check_context_overflow(max_depth: int = 20) -> bool:
	if context_stack.size() >= max_depth:
		# 🚨 CRITICAL: 重要なエラー（GitHub Copilot重要情報）
		ArgodeSystem.log_critical("Context stack overflow detected (depth: %d)" % context_stack.size())
		return true
	return false

## デバッグ用：コンテキストスタック全体の状態を出力
func debug_print_context_stack():
	if context_stack.is_empty():
		# 🔍 DEBUG: コンテキスト状態詳細（通常は非表示）
		ArgodeSystem.log_debug_detail("Context stack is empty")
		return
	
	# 🔍 DEBUG: コンテキスト状態詳細（通常は非表示）
	ArgodeSystem.log_debug_detail("Context stack (depth: %d):" % context_stack.size())
	for i in range(context_stack.size()):
		var context = context_stack[i]
		var context_name = context.get("context_name", "unnamed")
		var statement_count = context.get("statements", []).size()
		ArgodeSystem.log_debug_detail("  [%d] %s (%d statements)" % [i, context_name, statement_count])
