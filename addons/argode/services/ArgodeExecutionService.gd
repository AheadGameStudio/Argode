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
		
		"command":
			# コマンド実行（menu, call, return, jump等）
			await execute_command_statement(statement)
			
			# 制御フローコマンドで実行が中断された場合のチェック
			if statement_name in ["jump", "return"] and not is_executing:
				print("🎯 STATEMENT: Control flow command interrupted execution")
		
		"label":
			# ラベルブロック実行（独立ブロック処理）
			var label_statements = statement.get("statements", [])
			# 新方式：ラベルを独立して実行（元のブロックに戻らない）
			await execute_block(label_statements, "label_" + statement_name, statement_name)
		
		_:
			print("🎯 STATEMENT: Unknown statement type: %s" % statement_type)

## Text文実行（Say文）
func execute_text_statement(statement: Dictionary) -> void:
	var text_content = statement.get("content", "")
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
	
	# 制御フローコマンド後の実行状態チェック
	if command_name in ["jump", "return"]:
		# Jump/Returnは実行を完全に停止
		is_executing = false
		print("🎯 COMMAND: '%s' command terminated current block execution" % command_name)

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

## 実行を再開 ※削除予定
# func resume_execution():
# 	if not is_executing:
# 		return
		
# 	is_paused = false
# 	# 🎬 WORKFLOW: 実行再開（GitHub Copilot重要情報）
# 	ArgodeSystem.log_workflow("ExecutionService resumed")

# ## 指定位置から実行を再開（Return処理用）
# func resume_execution_from_position(file_path: String, statement_index: int):
# 	"""指定されたファイルと位置から実行を再開"""
# 	ArgodeSystem.log_workflow("🎯 ExecutionService: Resuming from %s[%d]" % [file_path, statement_index])
	
# 	# ファイルが変わる場合の処理
# 	if current_file_path != file_path:
# 		current_file_path = file_path
# 		# 新しいファイルの読み込みが必要な場合の処理
# 		# (現在はStatementManagerで事前に読み込み済みを想定)
	
# 	# 実行位置をセット
# 	current_statement_index = statement_index
	
# 	# 実行状態を設定
# 	is_executing = true
# 	is_paused = false
# 	is_waiting_for_input = false
# 	is_waiting_for_command = false
	
# 	ArgodeSystem.log_workflow("🎯 ExecutionService: Position set, ready to resume execution")

## 実行を停止　※削除予定
# func stop_execution():
# 	is_executing = false
# 	is_paused = false
# 	is_waiting_for_input = false
# 	is_waiting_for_command = false
# 	current_statements.clear()
# 	current_statement_index = 0
# 	current_file_path = ""
	
# 	# 🎬 WORKFLOW: 実行停止（GitHub Copilot重要情報）
# 	ArgodeSystem.log_workflow("ExecutionService stopped")

## 次のステートメントに進む
# func advance_to_next_statement() -> bool:
# 	if not is_executing or current_statements.is_empty():
# 		ArgodeSystem.log_critical("🚨 advance_to_next_statement failed: is_executing=%s, statements_empty=%s" % [is_executing, current_statements.is_empty()])
# 		return false
	
# 	if not skip_index_increment:
# 		current_statement_index += 1
# 	else:
# 		skip_index_increment = false
	
# 	# 🔍 DEBUG: ステートメント進行詳細（通常は非表示）
# 	ArgodeSystem.log_workflow("🎯 Advanced to statement %d/%d" % [current_statement_index, current_statements.size()])
	
# 	var result = current_statement_index < current_statements.size()
# 	ArgodeSystem.log_workflow("🎯 advance_to_next_statement result: %s" % result)
# 	return result

## 現在のステートメントを取得
# func get_current_statement() -> Dictionary:
# 	if current_statement_index < current_statements.size():
# 		return current_statements[current_statement_index]
# 	return {}

## 実行状態を確認
# func is_running() -> bool:
# 	return is_executing and not is_paused

## 入力待ち状態を設定
# func set_waiting_for_input(waiting: bool):
# 	ArgodeSystem.log_workflow("🔧 ExecutionService.set_waiting_for_input: %s → %s" % [is_waiting_for_input, waiting])
# 	is_waiting_for_input = waiting
# 	if waiting:
# 		# 🔍 DEBUG: 入力待ち状態詳細（通常は非表示）
# 		ArgodeSystem.log_debug_detail("ExecutionService waiting for input")

## コマンド待ち状態を設定
# func set_waiting_for_command(waiting: bool, reason: String = ""):
# 	is_waiting_for_command = waiting
# 	if waiting:
# 		# 🔍 DEBUG: コマンド待ち状態詳細（通常は非表示）
# 		ArgodeSystem.log_debug_detail("ExecutionService waiting for command: %s" % reason)

# ## 実行可能かチェック
# func can_execute() -> bool:
# 	return is_executing and not is_paused and not is_waiting_for_input and not is_waiting_for_command

# ## 指定された行（ステートメントインデックス）にジャンプ
# func jump_to_label_line(line_index: int):
# 	if not is_executing or current_statements.is_empty():
# 		ArgodeSystem.log_critical("Cannot jump: execution not active")
# 		return
	
# 	# 行番号をステートメントインデックスに変換（簡単な実装）
# 	var target_index = line_index - 1  # 1-based indexから0-basedに変換
	
# 	if target_index >= 0 and target_index < current_statements.size():
# 		current_statement_index = target_index
# 		skip_index_increment = true  # 次の進行時にインデックスをスキップ
# 		jump_executed = true
# 		ArgodeSystem.log_workflow("Jumped to statement %d (line %d)" % [target_index, line_index])
# 	else:
# 		ArgodeSystem.log_critical("Jump target out of range: line %d (statements: %d)" % [line_index, current_statements.size()])

# ## 実行状態を設定
# func set_execution_state(executing: bool, paused: bool = false):
# 	is_executing = executing
# 	is_paused = paused
# 	ArgodeSystem.log_debug_detail("ExecutionService state set: executing=%s, paused=%s" % [executing, paused])

# ## メイン実行ループを実行（StatementManagerから移譲）
# func execute_main_loop(statement_manager: RefCounted):
# 	ArgodeSystem.log_workflow("🔧 ExecutionService: Main execution loop started")
	
# 	while is_running():
# 		ArgodeSystem.log_debug_detail("🔍 Loop: is_running=%s, can_execute=%s" % [is_running(), can_execute()])
		
# 		if not can_execute():
# 			await Engine.get_main_loop().process_frame
# 			continue
			
# 		var statement = get_current_statement()
# 		if statement.is_empty():
# 			ArgodeSystem.log_workflow("🔧 ExecutionService: no more statements")
# 			break
		
# 		# デバッグ: 実行ステートメントの詳細
# 		ArgodeSystem.log_critical("🚨 🎯 STMT_DEBUG: Type=%s, Name=%s, Args=%s" % [
# 			statement.get("type", "unknown"),
# 			statement.get("name", "unknown"),
# 			str(statement.get("args", []))
# 		])
			
# 		ArgodeSystem.log_workflow("🔧 Executing statement %d: %s" % [current_statement_index, statement.get("name", "unknown")])
		
# 		# 実行前のステートメント詳細ログ
# 		ArgodeSystem.log_critical("🚨 🎯 EXEC_DEBUG: About to execute: Type=%s, Name=%s" % [
# 			statement.get("type", "unknown"),
# 			statement.get("name", "unknown")
# 		])
# 		await execute_single_statement(statement, statement_manager)
		
# 		# 入力待ち状態の処理
# 		if is_waiting_for_input:
# 			ArgodeSystem.log_workflow("🔧 Waiting for user input to continue...")
# 			while is_waiting_for_input:
# 				await Engine.get_main_loop().process_frame
# 			ArgodeSystem.log_workflow("🔧 Input received, continuing execution...")
# 			ArgodeSystem.log_workflow("🔧 Current statement index after input: %d" % current_statement_index)
		
# 		# コマンド待ち状態の処理
# 		if is_waiting_for_command:
# 			ArgodeSystem.log_workflow("🔧 Waiting for command to complete...")
# 			while is_waiting_for_command:
# 				await Engine.get_main_loop().process_frame
# 			ArgodeSystem.log_workflow("🔧 Command completed, continuing execution...")
		
# 		# 子コンテキスト実行の処理
# 		var executed_child_context = false
# 		if statement_manager.has_method("_handle_child_context_execution"):
# 			executed_child_context = await statement_manager._handle_child_context_execution()
		
# 		# 子コンテキスト実行後は次のステートメントに進む（重複advance防止）
# 		if executed_child_context:
# 			if not advance_to_next_statement():
# 				ArgodeSystem.log_workflow("🔧 ExecutionService: cannot advance after child context")
# 				break
# 			# フレーム待機を追加して無限ループを防止
# 			await Engine.get_main_loop().process_frame
# 			continue  # continueで通常のadvance_to_next_statementをスキップ
		
# 		if not advance_to_next_statement():
# 			ArgodeSystem.log_workflow("🔧 ExecutionService: cannot advance to next statement")
# 			break
		
# 		ArgodeSystem.log_workflow("🔧 Advanced to next statement: index=%d" % current_statement_index)
		
# 		# フレーム待機を追加して無限ループを防止
# 		await Engine.get_main_loop().process_frame
	
# 	ArgodeSystem.log_workflow("🔧 ExecutionService: Main execution loop ended")

# ## 単一ステートメントを実行（StatementManagerから移譲）
# func execute_single_statement(statement: Dictionary, statement_manager: RefCounted):
# 	# 🔧 CRITICAL FIX: 実行中の文を正しく設定（子コンテキスト対応）
# 	executing_statement = statement
# 	ArgodeSystem.log_critical("🎯 EXECUTION_SERVICE_FIX: Set executing_statement to name=%s type=%s" % [statement.get("name", "unknown"), statement.get("type", "unknown")])
	
# 	var statement_type = statement.get("type", "")
# 	var command_name = statement.get("name", "")
# 	var args = statement.get("args", [])
	
# 	match statement_type:
# 		"command": 
# 			await execute_command_via_services(command_name, args, statement_manager)
# 		"say": 
# 			await execute_command_via_services(command_name, args, statement_manager)
# 			# sayコマンドの場合は入力待ち状態になるまで待機
# 			if is_waiting_for_input:
# 				ArgodeSystem.log_workflow("🔧 Say command set input waiting - waiting for user input...")
# 		"text": 
# 			await statement_manager._handle_text_statement(statement)

## コマンドを実行（StatementManagerから移譲）
# func execute_command_via_services(command_name: String, args: Array, statement_manager: RefCounted):
# 	ArgodeSystem.log_workflow("🔍 ExecutionService: Executing command: %s with args: %s" % [command_name, str(args)])
	
# 	var command_registry = ArgodeSystem.CommandRegistry
# 	if not command_registry or not command_registry.has_command(command_name):
# 		ArgodeSystem.log_critical("Command not found: %s" % command_name)
# 		return
	
# 	var command_instance = command_registry.get_command(command_name)
# 	ArgodeSystem.log_workflow("🔍 Retrieved command instance: %s" % str(command_instance))
	
# 	if command_instance and not command_instance.is_empty():
# 		var actual_instance = command_instance.get("instance")
# 		ArgodeSystem.log_workflow("🔍 Actual instance: %s" % str(actual_instance))
		
# 		if actual_instance:
# 			var args_dict = statement_manager._convert_args_to_dict(args)
# 			args_dict["statement_manager"] = statement_manager
# 			# CallCommand/ReturnCommand等のために元の配列も保持
# 			args_dict["parsed_line"] = args
# 			# MenuCommand等で現在実行中のstatementを参照できるように追加
# 			args_dict["_current_statement"] = executing_statement
# 			ArgodeSystem.log_workflow("🔍 Calling execute with args: %s" % str(args_dict))
			
# 			# ReturnCommand実行前の状態を記録
# 			var was_executing_before = is_executing
			
# 			await actual_instance.execute(args_dict)
			
# 			# ReturnCommandによって実行が停止された場合の検出
# 			if command_name == "return" and was_executing_before and not is_executing:
# 				ArgodeSystem.log_workflow("🔍 Return command detected - execution stopped by Return")
# 				return  # Return処理はStatementManagerが担当
			
# 			if actual_instance.has_method("is_async") and actual_instance.is_async():
# 				await actual_instance.execution_completed
# 		else:
# 			ArgodeSystem.log_critical("Command instance not found in registry data: %s" % command_name)
# 	else:
# 		ArgodeSystem.log_critical("Command registry data not found: %s" % command_name)

# ## デバッグ情報を出力
# func debug_print_state():
# 	# 🔍 DEBUG: 実行状態詳細（通常は非表示）
# 	ArgodeSystem.log_debug_detail("ExecutionService State:")
# 	ArgodeSystem.log_debug_detail("  executing: %s, paused: %s" % [str(is_executing), str(is_paused)])
# 	ArgodeSystem.log_debug_detail("  waiting_input: %s, waiting_command: %s" % [str(is_waiting_for_input), str(is_waiting_for_command)])
# 	ArgodeSystem.log_debug_detail("  statement: %d/%d" % [current_statement_index, current_statements.size()])

# ## Call/Return用戻り位置計算（StatementManagerから移譲）
# func calculate_return_index() -> int:
# 	"""Call時の戻り先インデックスを計算"""
# 	# 🎬 WORKFLOW: Call戻り位置計算（GitHub Copilot重要情報）
# 	ArgodeSystem.log_workflow("🔧 ExecutionService: Calculating return index from current position %d" % current_statement_index)
	
# 	# TODO: 子ステートメント実行中の特別処理は将来ContextServiceと連携
# 	# 現在は基本的な戻り位置計算のみ実装
# 	var return_index = current_statement_index + 1
	
# 	ArgodeSystem.log_workflow("🔧 Return index calculated: %d" % return_index)
# 	return return_index

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
