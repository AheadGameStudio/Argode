extends ArgodeCommandBase
class_name IfCommand

var variable_resolver: ArgodeVariableResolver

func _ready():
	command_class_name = "IfCommand"
	command_execute_name = "if"
	command_description = "条件分岐を実行します"
	command_help = "if variable operator value: の形式で使用し、条件に応じてブロックを実行します"
	
	# VariableResolverを初期化
	if ArgodeSystem and ArgodeSystem.VariableManager:
		variable_resolver = ArgodeVariableResolver.new(ArgodeSystem.VariableManager)

## 引数検証
func validate_args(args: Dictionary) -> bool:
	# ifコマンドは条件式が必要
	var condition_args = []
	var i = 0
	while args.has(str(i)):
		condition_args.append(args[str(i)])
		i += 1
	
	if condition_args.size() < 3:
		log_error("条件式が不完全です。'variable operator value'の形式で指定してください")
		return false
	return true

## コマンド中核処理
func execute_core(args: Dictionary) -> void:
	# ログ出力を一時的に無効化してスタックオーバーフロー原因を特定
	# log_info("IfCommand: 条件分岐開始")
	
	# VariableResolverが初期化されていない場合の保険
	if not variable_resolver and ArgodeSystem and ArgodeSystem.VariableManager:
		variable_resolver = ArgodeVariableResolver.new(ArgodeSystem.VariableManager)
	
	if not variable_resolver:
		# log_error("VariableResolver not available")
		return
	
	# StatementManagerから現在のステートメント情報を取得
	var statement_manager = ArgodeSystem.StatementManager
	if not statement_manager:
		# log_error("StatementManager not found")
		return
	
	# 現在のif文のステートメント構造を取得
	var current_statement = statement_manager.get_current_statement()
	if current_statement.is_empty():
		# log_error("Could not get current if statement")
		return
	
	# log_info("🔍 Processing if statement structure")
	
	# if条件を評価
	var condition_result = _evaluate_condition(args)
	# log_info("🔍 If condition result: %s" % str(condition_result))
	
	# 実行するステートメントブロックを決定
	var statements_to_execute = []
	
	if condition_result:
		# if条件が真の場合、ifブロックを実行
		statements_to_execute = current_statement.get("statements", [])
		# log_info("✅ If condition true, executing if block (%d statements)" % statements_to_execute.size())
	else:
		# elif/else条件をチェック
		statements_to_execute = _find_matching_elif_else_block(current_statement)
		if statements_to_execute.size() > 0:
			# log_info("✅ Found matching elif/else block (%d statements)" % statements_to_execute.size())
			pass
		else:
			# log_info("ℹ️ No matching conditions, skipping all blocks")
			pass
	
	# 選択されたブロックを実行
	if statements_to_execute.size() > 0:
		# log_info("🎯 Pushing if block statements to ContextService...")
		
		# ContextServiceを取得
		var context_service = statement_manager.context_service
		if context_service:
			# 子ステートメントをContextServiceにプッシュ
			context_service.push_context(statements_to_execute, "if_block")
			# log_info("✅ If block statements pushed to context")
		else:
			# log_error("ContextService not found")
			pass
		
		# log_info("✅ If block execution setup completed")
	else:
		# log_info("ℹ️ No statements to execute, continuing to next statement")
		pass
	
	# log_info("IfCommand: 条件分岐完了")

## 条件を評価
func _evaluate_condition(args: Dictionary) -> bool:
	# 条件式の引数を取得（variable operator value）
	var condition_args = []
	var i = 0
	while args.has(str(i)):
		condition_args.append(args[str(i)])
		i += 1
	
	if condition_args.size() < 3:
		# log_error("条件式が不完全です")
		return false
	
	var variable_name = condition_args[0]
	var operator = condition_args[1]
	var expected_value_str = condition_args[2]
	
	# log_info("🔍 Evaluating condition: %s %s %s" % [variable_name, operator, expected_value_str])
	
	# 変数の現在値を取得
	var current_value = variable_resolver.variable_manager.get_variable(variable_name)
	if current_value == null:
		current_value = 0  # デフォルト値
	
	# 期待値を処理（文字列でない場合はそのまま使用）
	var expected_value
	if typeof(expected_value_str) == TYPE_STRING:
		expected_value = variable_resolver._process_value(expected_value_str)
	else:
		expected_value = expected_value_str
	
	# log_info("🔍 Comparison: %s (%s) %s %s (%s)" % [
	#	str(current_value), 
	#	type_string(typeof(current_value)),
	#	operator, 
	#	str(expected_value),
	#	type_string(typeof(expected_value))
	# ])
	
	# 比較演算を実行
	match operator:
		">":
			return current_value > expected_value
		"<":
			return current_value < expected_value
		">=":
			return current_value >= expected_value
		"<=":
			return current_value <= expected_value
		"==":
			return current_value == expected_value
		"!=":
			return current_value != expected_value
		_:
			# log_error("未対応の演算子: %s" % operator)
			return false

## elif/elseブロックから条件に合うものを探す
func _find_matching_elif_else_block(if_statement: Dictionary) -> Array:
	var elif_else_blocks = if_statement.get("elif_else_blocks", [])
	
	log_info("🔍 Checking %d elif/else blocks" % elif_else_blocks.size())
	
	for block in elif_else_blocks:
		var block_type = block.get("name", "")
		
		if block_type == "elif":
			# elif条件を評価
			var elif_args = block.get("args", [])
			var elif_condition = _evaluate_elif_condition(elif_args)
			log_info("🔍 Elif condition result: %s" % str(elif_condition))
			
			if elif_condition:
				return block.get("statements", [])
		elif block_type == "else":
			# else文は無条件で実行
			log_info("🔍 Executing else block")
			return block.get("statements", [])
	
	return []  # 条件に合うブロックが見つからない

## elif条件を評価
func _evaluate_elif_condition(elif_args: Array) -> bool:
	if elif_args.size() < 3:
		log_error("elif条件式が不完全です")
		return false
	
	# argsをDictionary形式に変換してevaluate_conditionを再利用
	var args_dict = {}
	for i in range(elif_args.size()):
		args_dict[str(i)] = elif_args[i]
	
	return _evaluate_condition(args_dict)