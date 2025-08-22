# ArgodeDefinitionService.gd
extends RefCounted

class_name ArgodeDefinitionService

## 定義ステートメント実行専用サービス（StatementManagerから分離）
## 責任: 定義コマンド実行、初期化時の定義処理、フォールバック処理

## 定義ステートメントを実行（ArgodeSystem._execute_definition_commands用）
func execute_definition_statements(statements: Array, statement_manager: RefCounted = null) -> bool:
	"""
	Execute definition statements during system initialization.
	
	Args:
		statements: Array of definition statements to execute
		statement_manager: StatementManager instance for compatibility
		
	Returns:
		bool: True if all statements executed successfully
	"""
	if statements.is_empty():
		ArgodeSystem.log_workflow("DefinitionService: No definition statements to execute")
		return true
	
	ArgodeSystem.log_workflow("DefinitionService: Executing %d definition statements..." % statements.size())
	
	var success = true
	
	for i in range(statements.size()):
		var statement = statements[i]
		ArgodeSystem.log_debug_detail("DefinitionService: Executing definition statement %d: %s" % [i + 1, statement.get("command", "unknown")])
		
		# 定義ステートメントを実行
		var command_result = await execute_definition_statement(statement, statement_manager)
		if not command_result:
			ArgodeSystem.log_critical("DefinitionService: Definition statement %d failed" % [i + 1])
			success = false
	
	if success:
		ArgodeSystem.log_workflow("DefinitionService: All definition statements executed successfully")
	else:
		ArgodeSystem.log_critical("DefinitionService: Some definition statements failed during execution")
	
	return success

## 単一定義ステートメントを実行
func execute_definition_statement(statement: Dictionary, statement_manager: RefCounted = null) -> bool:
	"""
	Execute a single definition statement with enhanced error handling.
	
	Args:
		statement: Definition statement to execute
		statement_manager: StatementManager instance for compatibility
		
	Returns:
		bool: True if execution succeeded
	"""
	var command_name = statement.get("command", "")
	var name = statement.get("name", "")  # nameフィールドも確認
	var args = statement.get("args", [])
	
	# commandかnameのどちらかを使用
	var actual_command = command_name if not command_name.is_empty() else name
	
	if actual_command.is_empty():
		ArgodeSystem.log_critical("DefinitionService: Statement has no command name")
		return false
	
	# ArgodeSystemのCommandRegistryを使用してコマンドを実行
	if not ArgodeSystem.CommandRegistry:
		ArgodeSystem.log_critical("DefinitionService: CommandRegistry not available")
		return false
	
	var command_data = ArgodeSystem.CommandRegistry.get_command(actual_command)
	if command_data.is_empty():
		ArgodeSystem.log_critical("DefinitionService: Command not found: %s" % actual_command)
		return false
	
	# Dictionaryからインスタンスを取得
	var command_instance = command_data.get("instance")
	if not command_instance:
		ArgodeSystem.log_critical("DefinitionService: Command instance not available: %s" % actual_command)
		return false
	
	# 引数をDictionary形式に変換（通常のexecute_commandと同じ形式）
	var args_dict = _convert_args_to_dict(args)
	
	# StatementManagerインスタンスを提供（互換性維持）
	if statement_manager:
		args_dict["statement_manager"] = statement_manager
	
	# コマンドを実行（エラーハンドリング付き）
	var execution_result = await command_instance.execute(args_dict)
	
	# 実行結果を確認（コマンドによって戻り値の形式が異なる可能性がある）
	if execution_result == false:
		ArgodeSystem.log_critical("DefinitionService: Command execution failed: %s" % actual_command)
		return false
	
	ArgodeSystem.log_debug_detail("DefinitionService: Definition command executed successfully: %s" % actual_command)
	return true

## 引数配列をDictionary形式に変換（StatementManagerから移譲）
func _convert_args_to_dict(args: Array) -> Dictionary:
	"""
	Convert argument array to dictionary format for command execution.
	
	Args:
		args: Array of arguments
		
	Returns:
		Dictionary: Converted arguments
	"""
	# フォールバック: 安全な処理を優先
	var result_dict = {}
	for i in range(args.size()):
		result_dict[str(i)] = args[i]  # "0", "1", "2" 形式（既存コマンドとの互換性）
	return result_dict

## 定義実行の詳細ログを出力（デバッグ用）
func debug_print_definition_execution(statement: Dictionary):
	"""
	Print detailed information about definition statement execution.
	
	Args:
		statement: Definition statement to analyze
	"""
	ArgodeSystem.log_debug_detail("DefinitionService Debug:")
	ArgodeSystem.log_debug_detail("  command: %s" % statement.get("command", "none"))
	ArgodeSystem.log_debug_detail("  name: %s" % statement.get("name", "none"))
	ArgodeSystem.log_debug_detail("  args: %s" % str(statement.get("args", [])))
	ArgodeSystem.log_debug_detail("  type: %s" % statement.get("type", "none"))

## 定義ステートメントの有効性をチェック
func validate_definition_statement(statement: Dictionary) -> bool:
	"""
	Validate if a statement is a proper definition statement.
	
	Args:
		statement: Statement to validate
		
	Returns:
		bool: True if valid definition statement
	"""
	var command_name = statement.get("command", "")
	var name = statement.get("name", "")
	
	# コマンド名またはnameが存在するかチェック
	if command_name.is_empty() and name.is_empty():
		ArgodeSystem.log_critical("DefinitionService: Invalid statement - no command name")
		return false
	
	# 実際に使用するコマンド名を取得
	var actual_command = command_name if not command_name.is_empty() else name
	
	# CommandRegistryに存在するかチェック
	if not ArgodeSystem.CommandRegistry or not ArgodeSystem.CommandRegistry.has_command(actual_command):
		ArgodeSystem.log_critical("DefinitionService: Command not registered: %s" % actual_command)
		return false
	
	# 定義コマンド（is_define_command = true）かチェック
	var command_data = ArgodeSystem.CommandRegistry.get_command(actual_command)
	var command_instance = command_data.get("instance")
	
	if command_instance and command_instance.has_method("is_define_command"):
		if not command_instance.is_define_command():
			ArgodeSystem.log_critical("DefinitionService: Command is not a definition command: %s" % actual_command)
			return false
	
	return true

## 定義実行統計を取得
func get_definition_execution_stats() -> Dictionary:
	"""
	Get statistics about definition statement execution.
	
	Returns:
		Dictionary: Execution statistics
	"""
	# 将来的な拡張：実行統計の記録・取得
	return {
		"service_name": "ArgodeDefinitionService",
		"version": "1.0.0",
		"capabilities": [
			"definition_statement_execution",
			"command_validation",
			"error_handling",
			"compatibility_mode"
		]
	}
