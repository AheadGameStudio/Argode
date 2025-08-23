# ArgodeExecutionPathManager.gd
extends RefCounted

class_name ArgodeExecutionPathManager

## Universal Block Execution用の軽量パス管理
## LabelRegistry互換の辞書構造でCall/Return/Jumpの実行パスを追跡
## 複雑なContextService/CallStackServiceを置き換える軽量設計

# 実行パスのスタック（LabelRegistry形式の辞書配列）
static var execution_path_stack: Array[Dictionary] = []

# デバッグ用の実行深度カウンタ
static var call_depth: int = 0

# パフォーマンス測定用
static var total_push_operations: int = 0
static var total_pop_operations: int = 0

## 新しいブロック実行開始時にパスを保存
static func push_execution_point(label_name: String, statement_index: int = 0) -> void:
	"""
	実行パスに新しい実行ポイントを追加
	LabelRegistry形式で戻り先情報を保存
	
	Args:
		label_name: 実行開始するラベル名
		statement_index: ラベル内のステートメントインデックス（通常0）
	"""
	var current_label_info = ArgodeSystem.LabelRegistry.get_label(label_name)
	if current_label_info.is_empty():
		ArgodeSystem.log_critical("🚨 Cannot push unknown label: %s" % label_name)
		return
	
	var execution_point = {
		"label": label_name,
		"path": current_label_info.path,
		"line": current_label_info.line,
		"statement_index": statement_index,
		"timestamp": Time.get_ticks_msec(),
		"call_depth": call_depth
	}
	
	execution_path_stack.push_back(execution_point)
	
	# デバッグ出力（構造化）
	var indent = "  ".repeat(call_depth)
	print("🎯 %sPUSH: %s (depth: %d, stack: %d)" % [indent, label_name, call_depth, execution_path_stack.size()])
	
	call_depth += 1
	total_push_operations += 1

## ブロック実行完了時にパスから戻る
static func pop_execution_point() -> Dictionary:
	"""
	実行パススタックから戻り先を取得
	Return/Call完了時に使用
	
	Returns:
		Dictionary: LabelRegistry形式の戻り先情報、スタックが空の場合は空辞書
	"""
	if execution_path_stack.is_empty():
		ArgodeSystem.log_critical("🚨 Execution path stack is empty")
		return {}
	
	var return_point = execution_path_stack.pop_back()
	call_depth = max(0, call_depth - 1)
	
	# デバッグ出力（構造化）
	var indent = "  ".repeat(call_depth)
	print("🎯 %sPOP: %s (depth: %d, remaining: %d)" % [indent, return_point.label, call_depth, execution_path_stack.size()])
	
	total_pop_operations += 1
	return return_point

## 現在の実行パスを文字列で取得（デバッグ用）
static func get_current_path_string() -> String:
	"""
	現在の実行パスを人間が読みやすい文字列で返す
	
	Returns:
		String: "main → intro → greeting" 形式のパス文字列
	"""
	var path_names: Array[String] = []
	for point in execution_path_stack:
		path_names.append(point.label)
	
	if path_names.is_empty():
		return "(empty stack)"
	
	return " → ".join(path_names)

## デバッグ用の詳細パス表示
static func debug_print_execution_stack() -> void:
	"""
	実行スタックの詳細情報をデバッグ出力
	各階層のラベル名、ファイルパス、行番号を表示
	"""
	print("🎯 ═══ EXECUTION STACK (%d levels) ═══" % execution_path_stack.size())
	
	if execution_path_stack.is_empty():
		print("🎯   (empty stack)")
	else:
		for i in range(execution_path_stack.size()):
			var point = execution_path_stack[i]
			var indent = "  ".repeat(i)
			print("🎯 %s[%d] %s (%s:%d) @%dms" % [
				indent, 
				i, 
				point.label, 
				point.path, 
				point.line,
				point.timestamp
			])
	
	print("🎯 ═══════════════════════════════════")

## 現在のスタック深度を取得
static func get_current_depth() -> int:
	"""
	現在の実行深度を取得
	
	Returns:
		int: 実行深度（0 = メインレベル）
	"""
	return call_depth

## スタックが空かどうかチェック
static func is_stack_empty() -> bool:
	"""
	実行パススタックが空かどうか確認
	
	Returns:
		bool: スタックが空の場合true
	"""
	return execution_path_stack.is_empty()

## スタックサイズを取得
static func get_stack_size() -> int:
	"""
	現在のスタックサイズを取得
	
	Returns:
		int: スタック内の要素数
	"""
	return execution_path_stack.size()

## パフォーマンス統計を取得
static func get_performance_stats() -> Dictionary:
	"""
	パフォーマンス測定用の統計情報を取得
	
	Returns:
		Dictionary: push/pop操作回数などの統計
	"""
	return {
		"total_push_operations": total_push_operations,
		"total_pop_operations": total_pop_operations,
		"current_stack_size": execution_path_stack.size(),
		"current_depth": call_depth,
		"memory_usage_estimate": execution_path_stack.size() * 200  # 概算バイト数
	}

## スタックをクリア（デバッグ用・エラー復旧用）
static func clear_execution_stack() -> void:
	"""
	実行パススタックを完全にクリア
	デバッグやエラー復旧時に使用
	"""
	var previous_size = execution_path_stack.size()
	execution_path_stack.clear()
	call_depth = 0
	
	if previous_size > 0:
		ArgodeSystem.log_workflow("🎯 EXECUTION STACK CLEARED (%d frames removed)" % previous_size)

## 統計リセット（テスト用）
static func reset_performance_stats() -> void:
	"""
	パフォーマンス統計をリセット
	テストや測定開始時に使用
	"""
	total_push_operations = 0
	total_pop_operations = 0
	ArgodeSystem.log_debug("🎯 Performance stats reset")

## 健全性チェック（デバッグ用）
static func validate_stack_integrity() -> bool:
	"""
	スタックの整合性をチェック
	デバッグ時のスタック状態検証
	
	Returns:
		bool: スタックが健全な場合true
	"""
	# call_depthとstack_sizeの整合性チェック
	var expected_depth = execution_path_stack.size()
	if call_depth != expected_depth:
		ArgodeSystem.log_critical("🚨 Stack integrity error: depth=%d, stack_size=%d" % [call_depth, expected_depth])
		# 自動修復試行
		call_depth = expected_depth
		return false
	
	# タイムスタンプの単調性チェック（デバッグビルドのみ）
	if OS.is_debug_build():
		for i in range(1, execution_path_stack.size()):
			if execution_path_stack[i].timestamp < execution_path_stack[i-1].timestamp:
				ArgodeSystem.log_critical("🚨 Stack timestamp integrity error at index %d" % i)
				return false
	
	return true
