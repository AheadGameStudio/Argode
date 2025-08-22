# ArgodeExecutionService.gd
extends RefCounted

class_name ArgodeExecutionService

## 実行フロー制御専用サービス（StatementManagerから分離）
## 責任: ステートメント実行の制御、実行状態管理、実行フローの制御

# 実行状態管理
var is_executing: bool = false
var is_paused: bool = false
var is_waiting_for_input: bool = false
var is_waiting_for_command: bool = false
var skip_index_increment: bool = false
var statements_inserted_by_command: bool = false
var is_executing_child_statements: bool = false
var jump_executed: bool = false
var is_skipped: bool = false

# 現在の実行コンテキスト
var current_statements: Array = []
var current_statement_index: int = 0
var current_file_path: String = ""
var executing_statement: Dictionary = {}
var command_result: Dictionary = {}

## 新しいステートメント実行を開始
func start_execution_session(statements: Array, file_path: String = "") -> bool:
	if is_executing:
		# 🚨 CRITICAL: 重要なエラー（GitHub Copilot重要情報）
		ArgodeSystem.log_critical("Cannot start execution: already executing")
		return false
	
	current_statements = statements
	current_file_path = file_path
	current_statement_index = 0
	is_executing = true
	is_paused = false
	
	# 🎬 WORKFLOW: 実行開始（GitHub Copilot重要情報）
	ArgodeSystem.log_workflow("ExecutionService started: %d statements in %s" % [statements.size(), file_path])
	
	return true

## 実行を一時停止
func pause_execution():
	if not is_executing:
		return
	
	is_paused = true
	# 🎬 WORKFLOW: 実行一時停止（GitHub Copilot重要情報）
	ArgodeSystem.log_workflow("ExecutionService paused")

## 実行を再開
func resume_execution():
	if not is_executing:
		return
		
	is_paused = false
	# 🎬 WORKFLOW: 実行再開（GitHub Copilot重要情報）
	ArgodeSystem.log_workflow("ExecutionService resumed")

## 実行を停止
func stop_execution():
	is_executing = false
	is_paused = false
	is_waiting_for_input = false
	is_waiting_for_command = false
	current_statements.clear()
	current_statement_index = 0
	current_file_path = ""
	
	# 🎬 WORKFLOW: 実行停止（GitHub Copilot重要情報）
	ArgodeSystem.log_workflow("ExecutionService stopped")

## 次のステートメントに進む
func advance_to_next_statement() -> bool:
	if not is_executing or current_statements.is_empty():
		ArgodeSystem.log_critical("🚨 advance_to_next_statement failed: is_executing=%s, statements_empty=%s" % [is_executing, current_statements.is_empty()])
		return false
	
	if not skip_index_increment:
		current_statement_index += 1
	else:
		skip_index_increment = false
	
	# 🔍 DEBUG: ステートメント進行詳細（通常は非表示）
	ArgodeSystem.log_workflow("🎯 Advanced to statement %d/%d" % [current_statement_index, current_statements.size()])
	
	var result = current_statement_index < current_statements.size()
	ArgodeSystem.log_workflow("🎯 advance_to_next_statement result: %s" % result)
	return result

## 現在のステートメントを取得
func get_current_statement() -> Dictionary:
	if current_statement_index < current_statements.size():
		return current_statements[current_statement_index]
	return {}

## 実行状態を確認
func is_running() -> bool:
	return is_executing and not is_paused

## 入力待ち状態を設定
func set_waiting_for_input(waiting: bool):
	ArgodeSystem.log_workflow("🔧 ExecutionService.set_waiting_for_input: %s → %s" % [is_waiting_for_input, waiting])
	is_waiting_for_input = waiting
	if waiting:
		# 🔍 DEBUG: 入力待ち状態詳細（通常は非表示）
		ArgodeSystem.log_debug_detail("ExecutionService waiting for input")

## コマンド待ち状態を設定
func set_waiting_for_command(waiting: bool, reason: String = ""):
	is_waiting_for_command = waiting
	if waiting:
		# 🔍 DEBUG: コマンド待ち状態詳細（通常は非表示）
		ArgodeSystem.log_debug_detail("ExecutionService waiting for command: %s" % reason)

## 実行可能かチェック
func can_execute() -> bool:
	return is_executing and not is_paused and not is_waiting_for_input and not is_waiting_for_command

## 指定された行（ステートメントインデックス）にジャンプ
func jump_to_label_line(line_index: int):
	if not is_executing or current_statements.is_empty():
		ArgodeSystem.log_critical("Cannot jump: execution not active")
		return
	
	# 行番号をステートメントインデックスに変換（簡単な実装）
	var target_index = line_index - 1  # 1-based indexから0-basedに変換
	
	if target_index >= 0 and target_index < current_statements.size():
		current_statement_index = target_index
		skip_index_increment = true  # 次の進行時にインデックスをスキップ
		jump_executed = true
		ArgodeSystem.log_workflow("Jumped to statement %d (line %d)" % [target_index, line_index])
	else:
		ArgodeSystem.log_critical("Jump target out of range: line %d (statements: %d)" % [line_index, current_statements.size()])

## 実行状態を設定
func set_execution_state(executing: bool, paused: bool = false):
	is_executing = executing
	is_paused = paused
	ArgodeSystem.log_debug_detail("ExecutionService state set: executing=%s, paused=%s" % [executing, paused])

## メイン実行ループを実行（StatementManagerから移譲）
func execute_main_loop(statement_manager: RefCounted):
	ArgodeSystem.log_workflow("🔧 ExecutionService: Main execution loop started")
	
	while is_running():
		ArgodeSystem.log_debug_detail("🔍 Loop: is_running=%s, can_execute=%s" % [is_running(), can_execute()])
		
		if not can_execute():
			await Engine.get_main_loop().process_frame
			continue
			
		var statement = get_current_statement()
		if statement.is_empty():
			ArgodeSystem.log_workflow("🔧 ExecutionService: no more statements")
			break
			
		ArgodeSystem.log_workflow("🔧 Executing statement %d: %s" % [current_statement_index, statement.get("name", "unknown")])
		await execute_single_statement(statement, statement_manager)
		
		# 入力待ち状態の処理
		if is_waiting_for_input:
			ArgodeSystem.log_workflow("🔧 Waiting for user input to continue...")
			while is_waiting_for_input:
				await Engine.get_main_loop().process_frame
			ArgodeSystem.log_workflow("🔧 Input received, continuing execution...")
			ArgodeSystem.log_workflow("🔧 Current statement index after input: %d" % current_statement_index)
		
		# コマンド待ち状態の処理
		if is_waiting_for_command:
			ArgodeSystem.log_workflow("🔧 Waiting for command to complete...")
			while is_waiting_for_command:
				await Engine.get_main_loop().process_frame
			ArgodeSystem.log_workflow("🔧 Command completed, continuing execution...")
		
		# 子コンテキスト実行の処理
		var executed_child_context = false
		if statement_manager.has_method("_handle_child_context_execution"):
			executed_child_context = await statement_manager._handle_child_context_execution()
		
		# 子コンテキスト実行後は次のステートメントに進む
		if executed_child_context:
			if not advance_to_next_statement():
				ArgodeSystem.log_workflow("🔧 ExecutionService: cannot advance after child context")
				break
			# フレーム待機を追加して無限ループを防止
			await Engine.get_main_loop().process_frame
			continue
		
		if not advance_to_next_statement():
			ArgodeSystem.log_workflow("🔧 ExecutionService: cannot advance to next statement")
			break
		
		ArgodeSystem.log_workflow("🔧 Advanced to next statement: index=%d" % current_statement_index)
		
		# フレーム待機を追加して無限ループを防止
		await Engine.get_main_loop().process_frame
	
	ArgodeSystem.log_workflow("🔧 ExecutionService: Main execution loop ended")

## 単一ステートメントを実行（StatementManagerから移譲）
func execute_single_statement(statement: Dictionary, statement_manager: RefCounted):
	var statement_type = statement.get("type", "")
	var command_name = statement.get("name", "")
	var args = statement.get("args", [])
	
	match statement_type:
		"command": 
			await execute_command_via_services(command_name, args, statement_manager)
		"say": 
			await execute_command_via_services(command_name, args, statement_manager)
			# sayコマンドの場合は入力待ち状態になるまで待機
			if is_waiting_for_input:
				ArgodeSystem.log_workflow("🔧 Say command set input waiting - waiting for user input...")
		"text": 
			await statement_manager._handle_text_statement(statement)

## コマンドを実行（StatementManagerから移譲）
func execute_command_via_services(command_name: String, args: Array, statement_manager: RefCounted):
	ArgodeSystem.log_workflow("🔍 ExecutionService: Executing command: %s with args: %s" % [command_name, str(args)])
	
	var command_registry = ArgodeSystem.CommandRegistry
	if not command_registry or not command_registry.has_command(command_name):
		ArgodeSystem.log_critical("Command not found: %s" % command_name)
		return
	
	var command_instance = command_registry.get_command(command_name)
	ArgodeSystem.log_workflow("🔍 Retrieved command instance: %s" % str(command_instance))
	
	if command_instance and not command_instance.is_empty():
		var actual_instance = command_instance.get("instance")
		ArgodeSystem.log_workflow("🔍 Actual instance: %s" % str(actual_instance))
		
		if actual_instance:
			executing_statement = get_current_statement()
			var args_dict = statement_manager._convert_args_to_dict(args)
			args_dict["statement_manager"] = statement_manager
			ArgodeSystem.log_workflow("🔍 Calling execute with args: %s" % str(args_dict))
			await actual_instance.execute(args_dict)
			if actual_instance.has_method("is_async") and actual_instance.is_async():
				await actual_instance.execution_completed
		else:
			ArgodeSystem.log_critical("Command instance not found in registry data: %s" % command_name)
	else:
		ArgodeSystem.log_critical("Command registry data not found: %s" % command_name)

## デバッグ情報を出力
func debug_print_state():
	# 🔍 DEBUG: 実行状態詳細（通常は非表示）
	ArgodeSystem.log_debug_detail("ExecutionService State:")
	ArgodeSystem.log_debug_detail("  executing: %s, paused: %s" % [str(is_executing), str(is_paused)])
	ArgodeSystem.log_debug_detail("  waiting_input: %s, waiting_command: %s" % [str(is_waiting_for_input), str(is_waiting_for_command)])
	ArgodeSystem.log_debug_detail("  statement: %d/%d" % [current_statement_index, current_statements.size()])
