# ArgodeExecutionService.gd
extends RefCounted

class_name ArgodeExecutionService

## Universal Block Execution エンジン - 新設計
## 責任: 独立したブロック実行とExecutionPathManager統合

# ExecutionPathManagerへの参照
const ArgodeExecutionPathManager = preload("res://addons/argode/services/ArgodeExecutionPathManager.gd")

# 実行状態（最小限）
var is_executing: bool = false
var current_file_path: String = ""
var executing_statement: Dictionary = {}
# Services参照
var statement_manager: RefCounted
var context_service: RefCounted

# ラベルリストキャッシュ（最適化）
var file_label_cache: Dictionary = {}  # {file_path: Array[String]}
var cache_timestamp: Dictionary = {}   # {file_path: int}

## 初期化
func initialize(stmt_manager: RefCounted, ctx_service: RefCounted):
	statement_manager = stmt_manager
	context_service = ctx_service
	print("🎯 EXECUTION: Service initialized with universal block processing")

## Universal Block Execution エンジン（新設計）
func execute_block(statements: Array, context_name: String = "", source_label: String = "") -> void:
	"""
	Universal Block Execution - 独立したブロック実行
	各ブロックが完全に独立して実行され、元のブロックには戻らない
	
	Args:
		statements: 実行するステートメント配列
		context_name: デバッグ用のコンテキスト名
		source_label: 実行元ラベル名（ExecutionPathManager用）
	"""
	if statements.is_empty():
		print("🎯 BLOCK: Empty block '%s' - skipping" % context_name)
		return
	
	# ExecutionPathManagerにパス登録（空の場合はmainとして扱う）
	var execution_label = source_label if not source_label.is_empty() else context_name
	if not execution_label.is_empty() and execution_label != "main_execution":
		ArgodeExecutionPathManager.push_execution_point(execution_label)
	
	print("🎯 BLOCK: Starting execution of %d statements in '%s'" % [statements.size(), context_name])
	is_executing = true
	
	# ブロック内の各ステートメントを順次実行
	for i in range(statements.size()):
		var statement = statements[i]
		print("🎯 BLOCK: Executing statement %d/%d: %s" % [i+1, statements.size(), statement.get("type", "unknown")])
		
		# 個別ステートメント実行
		await execute_statement(statement)
		
		# Jump/Return/Call等で実行が中断された場合は終了
		if not is_executing:
			print("🎯 BLOCK: Execution interrupted by control flow command")
			break
		
		# フレーム待機で無限ループ防止
		await Engine.get_main_loop().process_frame
	
	print("🎯 BLOCK: Completed execution of block '%s'" % context_name)
	
	# ラベル実行完了後、次のラベルを自動継続実行
	if source_label and not source_label.is_empty() and is_executing:
		await continue_to_next_label(source_label)
	
	# ExecutionPathManagerからパス削除（main_executionは除外）
	if not execution_label.is_empty() and execution_label != "main_execution":
		ArgodeExecutionPathManager.pop_execution_point()
	
	is_executing = false

## Universal Statement Execution（新設計）
func execute_statement(statement: Dictionary) -> void:
	"""
	個別ステートメント実行 - Universal Block Execution対応
	制御フローコマンド（jump/call/return）は実行を中断する可能性がある
	"""
	executing_statement = statement
	var statement_type = statement.get("type", "")
	var statement_name = statement.get("name", "")
	
	print("🎯 STATEMENT: Executing %s '%s'" % [statement_type, statement_name])
	
	match statement_type:
		"text":
			# Say文の実行
			await execute_text_statement(statement)
		
		"say":
			# Say文もSayCommandとして統一実行（Universal Block Execution）
			await execute_command_statement(statement)
		
		"command":
			# コマンド実行（menu, call, return, jump等）
			await execute_command_statement(statement)
			
			# JumpCommandの場合は実行継続（Universal Block Execution対応）
			# returnコマンドのみ実行中断として扱う
			if statement_name == "return" and not is_executing:
				print("🎯 STATEMENT: Return command interrupted execution")
			elif statement_name == "jump":
				# JumpCommandは実行を継続する（Phase 5対応）
				print("🎯 STATEMENT: Jump command completed, continuing execution")
		
		"label":
			# ラベルブロック実行（独立ブロック処理）
			var label_statements = statement.get("statements", [])
			# 新方式：ラベルを独立して実行（元のブロックに戻らない）
			await execute_block(label_statements, "label_" + statement_name, statement_name)
		
		_:
			print("🎯 STATEMENT: Unknown statement type: %s" % statement_type)

## Text文実行（Say文）
func execute_text_statement(statement: Dictionary) -> void:
	# RGDParserはSay文のテキストをargs[0]に格納
	var args = statement.get("args", [])
	var text_content = args[0] if args.size() > 0 else ""
	print("🎯 TEXT: Displaying message: %s" % text_content)
	
	# UIControlServiceでメッセージ表示
	if statement_manager and statement_manager.has_method("show_message_via_service"):
		await statement_manager.show_message_via_service(text_content, {})
	else:
		print("🎯 TEXT: StatementManager show_message_via_service not available")

## Universal Command Execution（新設計）
func execute_command_statement(statement: Dictionary) -> void:
	var command_name = statement.get("name", "")
	var args = statement.get("args", [])  # Array として取得
	
	print("🎯 COMMAND: Executing command '%s'" % command_name)
	
	# Universal Block Execution: 各コマンドが独立してexecute_blockを制御
	await execute_regular_command(command_name, args)
	
	# Phase 5: JumpCommandは連続実行を継続、Returnのみ停止
	if command_name == "return":
		# Returnは実行を完全に停止
		is_executing = false
		print("🎯 COMMAND: 'return' command terminated current block execution")
	elif command_name == "jump":
		# JumpCommandは実行継続（Universal Block Execution Phase 5対応）
		print("🎯 COMMAND: 'jump' command completed, execution continues")

## Universal Command Execution Core（新設計）
func execute_regular_command(command_name: String, args: Array) -> void:
	print("🎯 COMMAND: Executing unified command '%s'" % command_name)
	
	# CommandRegistryからコマンド取得・実行
	var command_registry = ArgodeSystem.CommandRegistry
	if command_registry and command_registry.has_command(command_name):
		var command_data = command_registry.get_command(command_name)  # 辞書を取得
		if command_data and not command_data.is_empty():
			var command_instance = command_data.get("instance")  # 辞書からinstanceを抽出
			if command_instance:
				# ArgsをDictionaryに変換してコマンドに渡す（既存システムとの互換性）
				var args_dict = {}
				if statement_manager and statement_manager.has_method("_convert_args_to_dict"):
					args_dict = statement_manager._convert_args_to_dict(args)
				else:
					# フォールバック: 直接変換
					for i in range(args.size()):
						args_dict[str(i)] = args[i]
				
				# Universal Block Execution用の追加データを設定
				args_dict["statement_manager"] = statement_manager
				args_dict["parsed_line"] = args  # CallCommand/ReturnCommand等のため
				args_dict["_current_statement"] = executing_statement  # MenuCommand等のため
				args_dict["execution_service"] = self  # ExecutionService参照
				args_dict["execution_path_manager"] = ArgodeExecutionPathManager  # パス管理参照
				
				await command_instance.execute(args_dict)
			else:
				print("🎯 COMMAND: Command instance not found in registry data: '%s'" % command_name)
		else:
			print("🎯 COMMAND: Command data not found: '%s'" % command_name)
	else:
		print("🎯 COMMAND: Command '%s' not found" % command_name)

## 後方互換性のための関数（既存コードとの連携）
func start_execution_session(statements: Array, file_path: String = "") -> bool:
	current_file_path = file_path
	print("🎯 COMPAT: Starting execution session - %d statements" % statements.size())
	
	# execute_blockは非同期だが、この関数は同期的に成功/失敗を返す必要がある
	# 実際の実行は非同期で開始し、すぐにtrueを返す（既存の期待動作）
	if statements.is_empty():
		print("🎯 COMPAT: No statements to execute")
		return false
	
	# 非同期実行を開始（awaitしない）
	call_deferred("execute_block", statements, "main_execution")
	return true

func stop_execution():
	is_executing = false
	print("🎯 COMPAT: Execution stopped")

func pause_execution():
	print("🎯 COMPAT: Execution paused (no-op in block execution)")

func resume_execution():
	print("🎯 COMPAT: Execution resumed (no-op in block execution)")

## 実行中ステートメント取得（新設計対応）
func get_executing_statement() -> Dictionary:
	"""現在実行中のステートメントを取得"""
	return executing_statement

## Return用：指定インデックスから実行継続
func execute_block_from_index(label_name: String, start_index: int, debug_source: String = "") -> void:
	"""Return時の実行継続：指定されたラベルブロックの指定インデックスから実行"""
	
	print("🎬 RETURN: Block execution from index %d - label: %s" % [start_index, label_name])
	
	# ラベルブロックの取得
	var label_info = ArgodeSystem.LabelRegistry.get_label(label_name)
	if label_info.is_empty():
		ArgodeSystem.log_critical("Label '%s' not found for return execution" % label_name)
		return
	
	# 効率的なラベルステートメント取得（StatementManager活用）
	var label_statements = statement_manager.get_label_statements(label_name)
	if label_statements.is_empty():
		ArgodeSystem.log_critical("No statements found in label '%s'" % label_name)
		return
	
	# 指定インデックスから実行開始
	if start_index >= label_statements.size():
		print("🎬 RETURN: Start index %d exceeds statements size %d - execution completed" % [start_index, label_statements.size()])
		return
	
	# 部分配列を作成して実行
	var remaining_statements = label_statements.slice(start_index)
	print("🎬 RETURN: Executing %d remaining statements from index %d" % [remaining_statements.size(), start_index])
	
	await execute_block(remaining_statements, debug_source + "_from_" + str(start_index), label_name)

## ラベル実行完了後の自動継続処理
func continue_to_next_label(current_label: String) -> void:
	"""
	現在のラベル実行完了後、同一ファイル内の次のラベルに自動継続
	Universal Block Execution: 連続ラベル実行機能
	"""
	print("🎯 CONTINUE: Searching for next label after '%s'" % current_label)
	
	# 現在のラベル情報を取得
	var current_label_info = ArgodeSystem.LabelRegistry.get_label(current_label)
	if current_label_info.is_empty():
		print("🎯 CONTINUE: Current label not found in registry")
		return
	
	var current_file_path = current_label_info.get("path", "")
	if current_file_path.is_empty():
		print("🎯 CONTINUE: Invalid file path for current label")
		return
	
	print("🎯 CONTINUE: Current file path: '%s'" % current_file_path)
	
	# 同一ファイル内の次のラベルを検索（キャッシュ活用）
	var next_label = get_next_label_optimized(current_file_path, current_label)
	if next_label.is_empty():
		print("🎯 CONTINUE: No next label found in file '%s'" % current_file_path)
		print("🎯 CONTINUE: Script execution completed")
		return
	
	print("🎯 CONTINUE: Found next label '%s', continuing execution..." % next_label)
	
	# 次のラベルのステートメントを取得・実行
	var next_statements = statement_manager.get_label_statements(next_label)
	if next_statements.is_empty():
		print("🎯 CONTINUE: No statements found in next label '%s'" % next_label)
		return
	
	print("🎯 CONTINUE: Next label '%s' has %d statements" % [next_label, next_statements.size()])
	
	# 次のラベルを実行（再帰的にcontinue_to_next_labelが呼ばれる）
	await execute_block(next_statements, "auto_continue_" + next_label, next_label)

## 同一ファイル内の次のラベルを検索（最適化版）
func get_next_label_optimized(file_path: String, current_label: String) -> String:
	"""
	キャッシュを活用した最適化された次ラベル検索
	"""
	# キャッシュされたラベルリストを取得
	var label_list = get_file_labels_cached(file_path)
	if label_list.is_empty():
		print("🎯 CONTINUE: No labels found in file cache for '%s'" % file_path)
		return ""
	
	print("🎯 CONTINUE: File contains %d labels: %s" % [label_list.size(), str(label_list)])
	
	# 現在のラベルの位置を特定
	var current_index = label_list.find(current_label)
	if current_index == -1:
		print("🎯 CONTINUE: Current label '%s' not found in label list" % current_label)
		return ""
	
	print("🎯 CONTINUE: Current label '%s' is at index %d" % [current_label, current_index])
	
	# 次のラベルを返す
	if current_index + 1 < label_list.size():
		var next_label = label_list[current_index + 1]
		print("🎯 CONTINUE: Next label found: '%s' (index %d)" % [next_label, current_index + 1])
		return next_label
	
	print("🎯 CONTINUE: No next label available (current is last)")
	return ""

## ファイル内ラベルリストのキャッシュ取得
func get_file_labels_cached(file_path: String) -> Array[String]:
	"""
	指定ファイルのラベルリストをキャッシュから取得（必要時に生成）
	"""
	# キャッシュが存在し、新しい場合はそれを返す
	if file_label_cache.has(file_path):
		var cached_time = cache_timestamp.get(file_path, 0)
		var current_time = Time.get_ticks_msec()
		
		# 30秒以内のキャッシュは有効とする
		if current_time - cached_time < 30000:
			print("🎯 CACHE: Using cached label list for '%s'" % file_path)
			return file_label_cache[file_path]
	
	# キャッシュが無効または存在しない場合は生成
	print("🎯 CACHE: Generating new label list for '%s'" % file_path)
	var label_list = generate_file_label_list(file_path)
	
	# キャッシュに保存
	file_label_cache[file_path] = label_list
	cache_timestamp[file_path] = Time.get_ticks_msec()
	
	return label_list

## ファイル内ラベルリストの生成
func generate_file_label_list(file_path: String) -> Array[String]:
	"""
	指定されたファイル内のラベルをライン番号順にソートしたリストを生成
	"""
	var all_labels_dict = ArgodeSystem.LabelRegistry.get_label_dictionary()
	var file_labels = []
	
	# 同一ファイルのラベルを収集
	for label_name in all_labels_dict.keys():
		var label_info = all_labels_dict[label_name]
		if label_info.get("path", "") == file_path:
			file_labels.append({
				"name": label_name,
				"line": label_info.get("line", 0)
			})
	
	# ライン番号順にソート
	file_labels.sort_custom(func(a, b): return a.line < b.line)
	
	# ラベル名のみの配列を作成
	var result: Array[String] = []
	for label_data in file_labels:
		result.append(label_data.name)
	
	print("🎯 CACHE: Generated label list for '%s': %s" % [file_path, str(result)])
	return result

## 同一ファイル内の次のラベルを検索（レガシー版）
func find_next_label_in_file(file_path: String, current_label: String) -> String:
	"""
	指定されたファイル内で、現在のラベルの次に定義されているラベルを検索
	※レガシー版：デバッグ用に残存、通常は get_next_label_optimized を使用
	"""
	# 全ラベルを取得してファイルパスでフィルタリング
	var all_labels_dict = ArgodeSystem.LabelRegistry.get_label_dictionary()
	var file_labels = []
	
	# 同一ファイルのラベルを収集
	for label_name in all_labels_dict.keys():
		var label_info = all_labels_dict[label_name]
		if label_info.get("path", "") == file_path:
			file_labels.append({
				"name": label_name,
				"line": label_info.get("line", 0)
			})
	
	# ライン番号順にソート
	file_labels.sort_custom(func(a, b): return a.line < b.line)
	
	# 現在のラベルの位置を特定
	var current_index = -1
	for i in range(file_labels.size()):
		if file_labels[i].name == current_label:
			current_index = i
			break
	
	# 次のラベルを返す
	if current_index >= 0 and current_index + 1 < file_labels.size():
		return file_labels[current_index + 1].name
	
	return ""
