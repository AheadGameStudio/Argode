# ArgodeStatementManager.gd (Service Layer Pattern)
extends RefCounted
class_name ArgodeStatementManager

## 統一API提供のStatementManager (200行以下)
## 内部実装はServiceクラスに分離、カスタムコマンド向け統一インターフェース維持

# 内部Service層（ユーザー非公開）
var execution_service: ArgodeExecutionService
var call_stack_service: ArgodeCallStackService
var context_service: ArgodeContextService
var input_handler_service: ArgodeInputHandlerService
var ui_control_service: ArgodeUIControlService

# RGDパーサー・システム参照
var rgd_parser: ArgodeRGDParser
var inline_command_manager: ArgodeInlineCommandManager
var message_window: ArgodeMessageWindow = null
var message_renderer: ArgodeMessageRenderer = null

# 実行状態管理（公開プロパティ）
var is_executing: bool = false
var is_paused: bool = false

func _init():
	ArgodeSystem.log_workflow("StatementManager initializing with Service Layer Pattern")
	_initialize_services()
	rgd_parser = ArgodeRGDParser.new()
	inline_command_manager = ArgodeInlineCommandManager.new()
	if input_handler_service:
		input_handler_service.valid_input_received.connect(_on_valid_input_received)

## 初期化準備完了フラグ
var _is_ready: bool = false

## StatementManagerが使用できる状態かチェック
func ensure_ready():
	if not _is_ready:
		_setup_parser_registry()
		_is_ready = true

## パーサーにCommandRegistryを設定（遅延実行）
func _setup_parser_registry():
	if rgd_parser and ArgodeSystem and ArgodeSystem.CommandRegistry:
		rgd_parser.set_command_registry(ArgodeSystem.CommandRegistry)
		ArgodeSystem.log_workflow("🔧 RGDParser CommandRegistry configured")
	
	# InlineCommandManagerのTagRegistryを初期化
	if inline_command_manager and ArgodeSystem and ArgodeSystem.CommandRegistry:
		inline_command_manager.initialize_tag_registry(ArgodeSystem.CommandRegistry)
		ArgodeSystem.log_workflow("🔧 InlineCommandManager TagRegistry configured")
	
	ArgodeSystem.log_workflow("StatementManager initialization completed")

func _initialize_services():
	execution_service = ArgodeExecutionService.new()
	call_stack_service = ArgodeCallStackService.new()
	context_service = ArgodeContextService.new()
	input_handler_service = ArgodeInputHandlerService.new()
	ui_control_service = ArgodeUIControlService.new()
	
	# InputHandlerServiceとの連携は遅延実行（Controllerの初期化完了を待つ）
	call_deferred("_connect_controller_services")
	
	ArgodeSystem.log_debug_detail("All internal services initialized")

## ArgodeControllerとの連携を設定（遅延実行）
func _connect_controller_services():
	# ArgodeControllerとの連携を設定
	var controller = ArgodeSystem.Controller
	if controller and controller.has_method("connect_input_handler_service"):
		controller.connect_input_handler_service(input_handler_service)
		ArgodeSystem.log_workflow("InputHandlerService connected to ArgodeController via StatementManager")
	else:
		# まだControllerが準備されていない場合は再試行
		call_deferred("_connect_controller_services")

# === カスタムコマンド向け統一API ===

func load_scenario_file(file_path: String) -> bool:
	if not FileAccess.file_exists(file_path):
		ArgodeSystem.log_critical("Scenario file not found: %s" % file_path)
		return false
	
	# パーサーのCommandRegistry設定を確認・再設定
	if rgd_parser and not rgd_parser.command_registry and ArgodeSystem.CommandRegistry:
		rgd_parser.set_command_registry(ArgodeSystem.CommandRegistry)
		ArgodeSystem.log_workflow("🔧 RGDParser CommandRegistry configured in load_scenario_file")
	
	var statements = rgd_parser.parse_file(file_path)
	if statements.is_empty():
		ArgodeSystem.log_critical("Failed to parse scenario file: %s" % file_path)
		return false
	
	# デバッグ: パース結果を表示
	ArgodeSystem.log_workflow("🔧 Parsed %d statements from %s:" % [statements.size(), file_path])
	for i in range(statements.size()):
		var stmt = statements[i]
		ArgodeSystem.log_workflow("  [%d] type=%s, name=%s, args=%s" % [i, stmt.get("type", ""), stmt.get("name", ""), stmt.get("args", [])])
	
	return execution_service.start_execution_session(statements, file_path)

func start_execution() -> bool:
	ensure_ready()  # 初期化を確実に実行
	if not execution_service.can_execute():
		return false
	_ensure_message_system_ready()
	ArgodeSystem.log_workflow("Scenario execution started")
	_execute_main_loop()
	return true

func play_from_label(label_name: String) -> bool:
	ensure_ready()  # 初期化を確実に実行
	var label_registry = ArgodeSystem.LabelRegistry
	if not label_registry:
		ArgodeSystem.log_critical("LabelRegistry not found")
		return false
	
	# ラベル情報を取得
	var label_info = label_registry.get_label(label_name)
	if label_info.is_empty():
		ArgodeSystem.log_critical("Label not found: %s" % label_name)
		return false
	
	var file_path = label_info.get("path", "")
	var label_line = label_info.get("line", 0)
	
	ArgodeSystem.log_workflow("Playing from label: %s at %s:%d" % [label_name, file_path, label_line])
	
	# execution_serviceの存在確認
	if not execution_service:
		ArgodeSystem.log_critical("⚠️ CRITICAL: execution_service is null - initializing fallback execution")
		# フォールバック: 直接実行
		return await _fallback_play_from_label(label_name, file_path, label_line)
	
	# 指定されたラベルのブロック内容をパース
	var label_statements = await _parse_label_block(file_path, label_name)
	if label_statements.is_empty():
		ArgodeSystem.log_critical("No statements found in label block: %s" % label_name)
		return false
	
	# ラベルブロックのステートメントで実行セッションを開始
	if not execution_service.start_execution_session(label_statements, file_path):
		ArgodeSystem.log_critical("Failed to start execution session for label: %s" % label_name)
		return false
	
	await _execute_main_loop()
	
	return true

## 指定されたラベルのブロック内容をパース
func _parse_label_block(file_path: String, label_name: String) -> Array:
	if rgd_parser and not rgd_parser.command_registry and ArgodeSystem.CommandRegistry:
		rgd_parser.set_command_registry(ArgodeSystem.CommandRegistry)
	
	var statements = rgd_parser.parse_label_block(file_path, label_name)
	
	# デバッグ: ラベルブロックのパース結果を表示
	ArgodeSystem.log_workflow("🔧 Parsed %d statements from label '%s':" % [statements.size(), label_name])
	for i in range(statements.size()):
		var stmt = statements[i]
		ArgodeSystem.log_workflow("  [%d] type=%s, name=%s, args=%s" % [i, stmt.get("type", ""), stmt.get("name", ""), stmt.get("args", [])])
	
	return statements

## フォールバック実行（Service Layer Pattern不使用）
func _fallback_play_from_label(label_name: String, file_path: String, label_line: int) -> bool:
	"""Service Layerが使用できない場合のフォールバック実行"""
	ArgodeSystem.log_workflow("🔧 Using fallback execution for label: %s" % label_name)
	
	# 従来の実行方式を使用
	# ここに既存のラベル実行ロジックを実装
	# 現在は簡単なログ出力のみ
	ArgodeSystem.log_workflow("📜 Would execute scenario from %s:%d" % [file_path, label_line])
	
	return true

func pause_execution(reason: String = ""):
	execution_service.pause_execution()
	if reason != "":
		ArgodeSystem.log_workflow("Execution paused: %s" % reason)

func resume_execution():
	execution_service.resume_execution()
	ArgodeSystem.log_workflow("🔄 Execution service resumed - main loop will continue naturally")

func stop_execution():
	execution_service.stop_execution()
	call_stack_service.clear_stack()
	context_service.clear_context_stack()
	ui_control_service.reset_ui_state()

func set_waiting_for_command(waiting: bool, reason: String = ""):
	execution_service.set_waiting_for_command(waiting, reason)

## WaitCommandなどからの明示的な実行再開要求
func continue_execution():
	ArgodeSystem.log("🔄 StatementManager: continue_execution() called")
	if execution_service.is_waiting_for_command:
		ArgodeSystem.log("⚠️ StatementManager: Still waiting for command - cannot continue")
		return
	
	ArgodeSystem.log("⏭️ StatementManager: Advancing to next statement")
	# 次のステートメントに進む
	if not execution_service.advance_to_next_statement():
		ArgodeSystem.log("🔚 StatementManager: No more statements to execute")
		return
	
	ArgodeSystem.log("▶️ StatementManager: Executing next statement")
	# メインループを再開
	_execute_main_loop()

func get_current_statement() -> Dictionary:
	return execution_service.get_current_statement()

func is_running() -> bool:
	return execution_service.is_running()

func get_variable(name: String):
	return ArgodeSystem.VariableManager.get_variable(name)

func set_variable(name: String, value):
	ArgodeSystem.VariableManager.set_variable(name, value)

func evaluate_expression(expression: String):
	var variable_manager = ArgodeSystem.VariableManager
	if variable_manager and variable_manager.has_method("evaluate_expression"):
		return variable_manager.evaluate_expression(expression)
	return null

func show_message(text: String, character: String = ""):
	_ensure_message_system_ready()
	
	ArgodeSystem.log("🔍 show_message: message_renderer=%s, message_window=%s" % [message_renderer, message_window])
	
	if message_renderer:
		# InlineCommandManagerでテキストを前処理（変数展開・タグ処理）
		var processed_result = inline_command_manager.process_text(text)
		var display_text = processed_result.get("display_text", text)
		var position_commands = processed_result.get("position_commands", [])
		
		# 位置ベースコマンド付きメッセージレンダリング
		message_renderer.render_message_with_position_commands(character, display_text, position_commands, inline_command_manager)
		ArgodeSystem.log("📺 Message displayed via renderer: %s: %s" % [character, display_text], ArgodeSystem.LOG_LEVEL.WORKFLOW)
		
		# レンダリング完了後に入力待ち状態になるまで待機
		# 完了コールバックで set_waiting_for_input(true) が呼ばれる
		
	else:
		ArgodeSystem.log("⚠️ show_message: using fallback window path")
		# メッセージウィンドウが無い場合は動的に作成
		if not message_window:
			_create_default_message_window()
			# 作成後に再度レンダラーが利用可能かをチェック
			if message_renderer:
				ArgodeSystem.log("✅ Renderer now available, using renderer path")
				# InlineCommandManagerでテキストを前処理（変数展開・タグ処理）
				var processed_result = inline_command_manager.process_text(text)
				var display_text = processed_result.get("display_text", text)
				var position_commands = processed_result.get("position_commands", [])
				
				# 位置ベースコマンド付きメッセージレンダリング
				message_renderer.render_message_with_position_commands(character, display_text, position_commands, inline_command_manager)
				ArgodeSystem.log("📺 Message displayed via renderer (after creation): %s: %s" % [character, display_text], ArgodeSystem.LOG_LEVEL.WORKFLOW)
				return
		
		# メッセージウィンドウを使って表示
		if message_window:
			_display_message_via_window(text, character)
		else:
			# 代替処理：メッセージレンダラーが無い場合はコンソールログに出力
			var display_text = ""
			if character != "":
				display_text = "%s: %s" % [character, text]
			else:
				display_text = text
			
			ArgodeSystem.log("📺 Message Display: %s" % display_text, ArgodeSystem.LOG_LEVEL.WORKFLOW)
			
			# 今後のために：簡単なメッセージウィンドウまたはレンダラーの初期化を試みる
			_try_fallback_message_display(display_text)

func handle_command_result(result_data: Dictionary):
	match result_data.get("type", ""):
		"jump": _handle_jump_via_services(result_data)
		"call": _handle_call_via_services(result_data)
		"return": _handle_return_via_services(result_data)
		"statements": _handle_statements_via_services(result_data)

func push_call_context(file_path: String, statement_index: int):
	call_stack_service.push_call(file_path, statement_index)

func pop_call_context() -> Dictionary:
	return call_stack_service.pop_return()

func _execute_child_statements(statements: Array):
	context_service.execute_child_statements(statements)

# === 内部実装層 ===

func _execute_main_loop():
	ArgodeSystem.log_workflow("🔧 Main execution loop started")
	while execution_service.is_running():
		ArgodeSystem.log_debug_detail("🔍 Loop: is_running=%s, can_execute=%s" % [execution_service.is_running(), execution_service.can_execute()])
		
		if not execution_service.can_execute():
			await Engine.get_main_loop().process_frame
			continue
			
		var statement = execution_service.get_current_statement()
		if statement.is_empty():
			ArgodeSystem.log_workflow("🔧 Main loop: no more statements")
			break
			
		ArgodeSystem.log_workflow("🔧 Executing statement %d: %s" % [execution_service.current_statement_index, statement.get("name", "unknown")])
		await _execute_single_statement(statement)
		
		# 入力待ち状態の場合は、入力を待って次に進む
		if execution_service.is_waiting_for_input:
			ArgodeSystem.log_workflow("🔧 Waiting for user input to continue...")
			while execution_service.is_waiting_for_input:
				await Engine.get_main_loop().process_frame
			ArgodeSystem.log_workflow("🔧 Input received, continuing execution...")
			ArgodeSystem.log_workflow("🔧 Current statement index after input: %d" % execution_service.current_statement_index)
		
		# コマンド待ち状態の場合は、コマンド完了を待って次に進む
		if execution_service.is_waiting_for_command:
			ArgodeSystem.log_workflow("🔧 Waiting for command to complete...")
			while execution_service.is_waiting_for_command:
				await Engine.get_main_loop().process_frame
			ArgodeSystem.log_workflow("🔧 Command completed, continuing execution...")
		
		# ContextServiceで子コンテキストがプッシュされているかチェック
		var executed_child_context = false
		if not context_service.is_context_stack_empty():
			var child_context = context_service.get_current_context()
			var child_statements = child_context.get("statements", [])
			if not child_statements.is_empty():
				ArgodeSystem.log_workflow("🔧 Executing child context statements (%d statements)..." % child_statements.size())
				# 子ステートメントを直接実行
				for child_statement in child_statements:
					ArgodeSystem.log_workflow("🔧 Executing child statement: %s" % child_statement.get("name", "unknown"))
					await _execute_single_statement(child_statement)
				ArgodeSystem.log_workflow("🔧 Child context execution completed")
				# コンテキストをポップ
				context_service.pop_context()
				executed_child_context = true
		
		# 子コンテキストを実行した場合は、ステートメントを進めて次のループへ
		if executed_child_context:
			# 子コンテキスト実行後はメインステートメントを次に進める
			if not execution_service.advance_to_next_statement():
				ArgodeSystem.log_workflow("🔧 Main loop: cannot advance after child context")
				break
			# ExecutionServiceの状態をチェック
			ArgodeSystem.log_workflow("🎯 After child context: is_running=%s, is_executing=%s, is_paused=%s" % [execution_service.is_running(), execution_service.is_executing, execution_service.is_paused])
			# フレーム待機を追加して無限ループを防止
			await Engine.get_main_loop().process_frame
			continue
		
		if not execution_service.advance_to_next_statement():
			ArgodeSystem.log_workflow("🔧 Main loop: cannot advance to next statement")
			break
		
		ArgodeSystem.log_workflow("🔧 Advanced to next statement: index=%d" % execution_service.current_statement_index)
		
		# フレーム待機を追加して無限ループを防止
		await Engine.get_main_loop().process_frame
	
	ArgodeSystem.log_workflow("🔧 Main execution loop ended")

func _execute_single_statement(statement: Dictionary):
	var statement_type = statement.get("type", "")
	var command_name = statement.get("name", "")
	var args = statement.get("args", [])
	
	match statement_type:
		"command": await _execute_command_via_services(command_name, args)
		"say": 
			await _execute_command_via_services(command_name, args)
			# sayコマンドの場合は入力待ち状態になるまで待機
			if execution_service.is_waiting_for_input:
				ArgodeSystem.log_workflow("🔧 Say command set input waiting - waiting for user input...")
		"text": await _handle_text_statement(statement)

func _execute_command_via_services(command_name: String, args: Array):
	ArgodeSystem.log_workflow("🔍 Executing command: %s with args: %s" % [command_name, str(args)])
	
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
			execution_service.executing_statement = execution_service.get_current_statement()
			var args_dict = _convert_args_to_dict(args)
			args_dict["statement_manager"] = self
			ArgodeSystem.log_workflow("🔍 Calling execute with args: %s" % str(args_dict))
			await actual_instance.execute(args_dict)
			if actual_instance.has_method("is_async") and actual_instance.is_async():
				await actual_instance.execution_completed
		else:
			ArgodeSystem.log_critical("Command instance not found in registry data: %s" % command_name)
	else:
		ArgodeSystem.log_critical("Command registry data not found: %s" % command_name)

func _handle_text_statement(statement: Dictionary):
	var text = statement.get("content", "")
	var character = statement.get("character", "")
	show_message(text, character)
	# 入力待ち状態は show_message → message_renderer の完了コールバックで設定される

func _convert_args_to_dict(args: Array) -> Dictionary:
	# フォールバック: 安全な処理を優先
	var result_dict = {}
	for i in range(args.size()):
		result_dict[str(i)] = args[i]  # "0", "1", "2" 形式（既存コマンドとの互換性）
	return result_dict

func _is_keyword_argument(arg: String) -> bool:
	return arg.contains("=") and not arg.begins_with("=") and not arg.ends_with("=")

func _handle_jump_via_services(result_data: Dictionary):
	var label_name = result_data.get("label", "")
	if label_name == "":
		ArgodeSystem.log_critical("Jump command missing label name")
		return
	var label_registry = ArgodeSystem.LabelRegistry
	if not label_registry:
		ArgodeSystem.log_critical("LabelRegistry not found for jump")
		return
	var label_info = label_registry.get_label(label_name)
	if label_info.is_empty():
		ArgodeSystem.log_critical("Label not found: %s" % label_name)
		return
	
	var file_path = label_info.get("path", "")
	var line = label_info.get("line", 0)
	ArgodeSystem.log_workflow("Jumping to label: %s at %s:%d" % [label_name, file_path, line])
	
	# execution_serviceの存在確認
	if not execution_service:
		ArgodeSystem.log_critical("⚠️ CRITICAL: execution_service is null - cannot execute jump")
		ArgodeSystem.log_critical("🔧 Service Layer Pattern not properly initialized")
		return
	
	# 現在の実行を停止してジャンプ先のラベルから開始
	execution_service.stop_execution()
	ArgodeSystem.log_workflow("🔧 Jump: Stopped current execution, starting from label: %s" % label_name)
	
	# 新しいラベルから実行を開始（call_deferredで非同期実行）
	call_deferred("play_from_label", label_name)

func _handle_call_via_services(result_data: Dictionary):
	var label_name = result_data.get("label", "")
	if label_name == "":
		ArgodeSystem.log_critical("Call command missing label name")
		return
	call_stack_service.push_call(
		execution_service.current_file_path,
		execution_service.current_statement_index + 1
	)
	_handle_jump_via_services(result_data)

func _handle_return_via_services(result_data: Dictionary):
	var call_frame = call_stack_service.pop_return()
	if call_frame.is_empty():
		ArgodeSystem.log_critical("Return called but no call stack frame")
		return
	var return_file = call_frame.get("file_path", "")
	var return_index = call_frame.get("statement_index", 0)
	ArgodeSystem.log_workflow("Returning to %s[%d]" % [return_file, return_index])

func _handle_statements_via_services(result_data: Dictionary):
	var child_statements = result_data.get("statements", [])
	context_service.execute_child_statements(child_statements)

func _on_valid_input_received(action_name: String):
	ArgodeSystem.log_workflow("🎮 StatementManager received input: %s" % action_name)
	
	match action_name:
		"argode_advance", "argode_skip":
			# タイプライター効果が進行中かチェック
			var is_typewriter_active = false
			if message_renderer and message_renderer.has_method("is_typewriter_active"):
				is_typewriter_active = message_renderer.is_typewriter_active()
			
			if is_typewriter_active:
				# タイプライター進行中の場合：全文表示に切り替え
				ArgodeSystem.log_workflow("🎮 Typewriter active - completing typewriter effect")
				if message_renderer.has_method("complete_typewriter"):
					message_renderer.complete_typewriter()
				# ここでは入力待ち状態は変更しない（タイプライター完了後に入力待ちになる）
				return
			
			# タイプライターが非アクティブの場合：次のステートメントに進む
			if execution_service and execution_service.is_waiting_for_input:
				ArgodeSystem.log_workflow("🎮 Advancing execution due to input: %s" % action_name)
				ArgodeSystem.log_workflow("🎮 Before: is_waiting_for_input=%s" % execution_service.is_waiting_for_input)
				execution_service.set_waiting_for_input(false)
				ArgodeSystem.log_workflow("🎮 After: is_waiting_for_input=%s" % execution_service.is_waiting_for_input)
				ArgodeSystem.log_workflow("🎮 Input processing completed - execution should resume")
				
				# 実行ループを再開するためのシグナルを送信（必要に応じて）
				# 実行ループは既に入力待ち状態をチェックしているので、フラグの変更だけで十分
				
			else:
				ArgodeSystem.log_workflow("🎮 Input ignored (not waiting): %s" % action_name)
		_:
			ArgodeSystem.log_workflow("🎮 Unknown input action: %s" % action_name)

func _ensure_message_system_ready():
	ArgodeSystem.log("🔍 _ensure_message_system_ready: before - message_window=%s, message_renderer=%s" % [message_window, message_renderer])
	
	if not message_window:
		message_window = ArgodeSystem.UIManager.get_message_window()
		ArgodeSystem.log("🔍 Got message_window from UIManager: %s" % message_window)
	if not message_renderer:
		message_renderer = ArgodeSystem.UIManager.get_message_renderer()
		ArgodeSystem.log("🔍 Got message_renderer from UIManager: %s" % message_renderer)
	
	ArgodeSystem.log("🔍 _ensure_message_system_ready: after - message_window=%s, message_renderer=%s" % [message_window, message_renderer])

func _try_fallback_message_display(display_text: String):
	"""
	代替メッセージ表示処理：レンダラーが無い場合の簡単な表示
	
	Args:
		display_text: 表示するテキスト
	"""
	# 将来的には簡単なメッセージウィンドウを動的に作成する処理を追加可能
	# 現在はコンソールログのみ
	pass

func _create_default_message_window():
	"""
	デフォルトのメッセージウィンドウを動的に作成
	"""
	var message_window_path = "res://addons/argode/builtin/scenes/default_message_window/default_message_window.tscn"
	
	# メッセージウィンドウをUIManagerに追加
	if ArgodeSystem.UIManager.add_ui(message_window_path, "message", 100):
		message_window = ArgodeSystem.UIManager.get_ui("message")
		ArgodeSystem.log("✅ Default message window created and added", ArgodeSystem.LOG_LEVEL.WORKFLOW)
		
		# メッセージレンダラーを作成してキャッシュ
		message_renderer = _create_message_renderer(message_window)
		if message_renderer:
			ArgodeSystem.log("✅ Message renderer created and configured", ArgodeSystem.LOG_LEVEL.DEBUG)
		else:
			ArgodeSystem.log("❌ Failed to create message renderer", ArgodeSystem.LOG_LEVEL.CRITICAL)
	else:
		ArgodeSystem.log("❌ Failed to create default message window", ArgodeSystem.LOG_LEVEL.CRITICAL)

## メッセージレンダラーを作成
func _create_message_renderer(window: ArgodeMessageWindow) -> ArgodeMessageRenderer:
	if not window:
		return null
	
	# ArgodeMessageRendererクラスを動的に読み込み
	var RendererClass = load("res://addons/argode/renderer/ArgodeMessageRenderer.gd")
	if not RendererClass:
		ArgodeSystem.log("❌ ArgodeMessageRenderer class not found", ArgodeSystem.LOG_LEVEL.CRITICAL)
		return null
	
	# レンダラーインスタンスを作成
	var renderer = RendererClass.new(window)
	
	# レンダラーをウィンドウに関連付け
	if renderer.has_method("set_message_window"):
		renderer.set_message_window(window)
		ArgodeSystem.log("✅ Message renderer created and linked to window", ArgodeSystem.LOG_LEVEL.DEBUG)
	
	# タイプライター完了コールバックを設定
	if renderer.has_method("set_typewriter_completion_callback"):
		renderer.set_typewriter_completion_callback(_on_message_rendering_completed)
		ArgodeSystem.log("✅ Message renderer completion callback set", ArgodeSystem.LOG_LEVEL.DEBUG)
	
	return renderer

## メッセージレンダリング完了時のコールバック
func _on_message_rendering_completed():
	"""メッセージレンダリング完了時に呼ばれるコールバック"""
	ArgodeSystem.log("✅ Message rendering completed - waiting for user input", ArgodeSystem.LOG_LEVEL.WORKFLOW)
	
	# ExecutionServiceに入力待機状態を設定
	if execution_service:
		execution_service.set_waiting_for_input(true)
		ArgodeSystem.log("⏳ Set waiting for user input to continue", ArgodeSystem.LOG_LEVEL.DEBUG)
	else:
		ArgodeSystem.log("❌ ExecutionService not available for input waiting", ArgodeSystem.LOG_LEVEL.CRITICAL)

func _display_message_via_window(text: String, character: String):
	"""
	メッセージウィンドウを通してメッセージを表示
	
	Args:
		text: 表示するメッセージテキスト
		character: キャラクター名（オプション）
	"""
	if not message_window:
		ArgodeSystem.log("❌ Message window is not available", ArgodeSystem.LOG_LEVEL.CRITICAL)
		return
	
	# メッセージウィンドウを表示
	ArgodeSystem.UIManager.show_ui("message")
	
	# メッセージウィンドウにメッセージを設定
	if message_window.has_method("set_message_text"):
		message_window.set_message_text(text)
		ArgodeSystem.log("✅ Message text set via set_message_text", ArgodeSystem.LOG_LEVEL.DEBUG)
	else:
		ArgodeSystem.log("❌ Message window does not have set_message_text method", ArgodeSystem.LOG_LEVEL.CRITICAL)
	
	# キャラクター名を設定（空でない場合）
	if character != "":
		if message_window.has_method("set_character_name"):
			message_window.set_character_name(character)
			ArgodeSystem.log("✅ Character name set via set_character_name: %s" % character, ArgodeSystem.LOG_LEVEL.DEBUG)
		else:
			ArgodeSystem.log("❌ Message window does not have set_character_name method", ArgodeSystem.LOG_LEVEL.CRITICAL)
	else:
		# キャラクター名が無い場合は名前プレートを隠す
		if message_window.has_method("hide_character_name"):
			message_window.hide_character_name()
			ArgodeSystem.log("✅ Character name hidden", ArgodeSystem.LOG_LEVEL.DEBUG)
	
	ArgodeSystem.log("📺 Message displayed via window: %s: %s" % [character, text], ArgodeSystem.LOG_LEVEL.WORKFLOW)
	
	# ウィンドウパス使用時も入力待ち状態を設定
	if execution_service:
		execution_service.set_waiting_for_input(true)
		ArgodeSystem.log("⏳ Set waiting for user input to continue (via window)", ArgodeSystem.LOG_LEVEL.DEBUG)
	else:
		ArgodeSystem.log("❌ ExecutionService not available for input waiting", ArgodeSystem.LOG_LEVEL.CRITICAL)

# ===========================
# 実行状態管理API
# ===========================

## 実行状態を設定
func set_execution_state(executing: bool, paused: bool = false):
	is_executing = executing
	is_paused = paused
	if execution_service:
		execution_service.set_execution_state(executing, paused)
	ArgodeSystem.log_debug_detail("Execution state: executing=%s, paused=%s" % [executing, paused])

## 実行状態を取得
func get_execution_state() -> Dictionary:
	return {
		"executing": is_executing,
		"paused": is_paused,
		"waiting_for_input": execution_service.is_waiting_for_input if execution_service else false
	}

# ===========================
# 定義ステートメント実行API
# ===========================

## 定義ステートメントを実行（ArgodeSystem._execute_definition_commands用）
func execute_definition_statements(statements: Array) -> bool:
	"""
	Execute definition statements during system initialization.
	
	Args:
		statements: Array of definition statements to execute
		
	Returns:
		bool: True if all statements executed successfully
	"""
	if statements.is_empty():
		ArgodeSystem.log_workflow("No definition statements to execute")
		return true
	
	ArgodeSystem.log_workflow("Executing %d definition statements..." % statements.size())
	# 実行状態を設定
	is_executing = true
	is_paused = false
	
	var success = true
	
	for i in range(statements.size()):
		var statement = statements[i]
		ArgodeSystem.log_debug_detail("Executing definition statement %d: %s" % [i + 1, statement.get("command", "unknown")])
		
		# 直接コマンド実行（定義文は初期化時のみなのでservice層をバイパス）
		var command_result = await _execute_definition_statement_fallback(statement)
		if not command_result:
			ArgodeSystem.log_critical("Definition statement %d failed" % [i + 1])
			success = false
	
	# 実行状態をリセット
	is_executing = false
	is_paused = false
	
	if success:
		ArgodeSystem.log_workflow("All definition statements executed successfully")
	else:
		ArgodeSystem.log_critical("Some definition statements failed during execution")
	
	return success

## 単一定義ステートメントを実行（フォールバック用）
func _execute_definition_statement_fallback(statement: Dictionary) -> bool:
	"""
	Execute a single definition statement as fallback when service layer is not available.
	"""
	var command_name = statement.get("command", "")
	var name = statement.get("name", "")  # nameフィールドも確認
	var args = statement.get("args", [])
	
	# commandかnameのどちらかを使用
	var actual_command = command_name if not command_name.is_empty() else name
	
	if actual_command.is_empty():
		ArgodeSystem.log_critical("Statement has no command name")
		return false
	
	# ArgodeSystemのCommandRegistryを使用してコマンドを実行
	if not ArgodeSystem.CommandRegistry:
		ArgodeSystem.log_critical("CommandRegistry not available")
		return false
	
	var command_data = ArgodeSystem.CommandRegistry.get_command(actual_command)
	if command_data.is_empty():
		ArgodeSystem.log_critical("Command not found: %s" % actual_command)
		return false
	
	# Dictionaryからインスタンスを取得
	var command_instance = command_data.get("instance")
	if not command_instance:
		ArgodeSystem.log_critical("Command instance not available: %s" % actual_command)
		return false
	
	# 引数をDictionary形式に変換（通常のexecute_commandと同じ形式）
	var args_dict = _convert_args_to_dict(args)
	args_dict["statement_manager"] = self
	
	# コマンドを実行（エラーハンドリング付き）
	var execution_result = await command_instance.execute(args_dict)
	
	# 実行結果を確認（コマンドによって戻り値の形式が異なる可能性がある）
	if execution_result == false:
		ArgodeSystem.log_critical("Command execution failed: %s" % actual_command)
		return false
	
	ArgodeSystem.log_debug_detail("Definition command executed successfully: %s" % command_name)
	return true

# =============================================================================
# タイプライター制御メソッド (ArgodeCommandBase用)
# =============================================================================

## タイプライターを一時停止
func pause_typewriter():
	if ui_control_service:
		ui_control_service.pause_typewriter()

## タイプライターを再開
func resume_typewriter():
	if ui_control_service:
		ui_control_service.resume_typewriter()

## タイプライター速度を変更
func push_typewriter_speed(new_speed: float):
	if ui_control_service:
		ui_control_service.push_typewriter_speed(new_speed)

## タイプライター速度を復元
func pop_typewriter_speed():
	if ui_control_service:
		ui_control_service.pop_typewriter_speed()

## 現在のタイプライター速度を取得
func get_current_typewriter_speed() -> float:
	if ui_control_service:
		return ui_control_service.get_current_typewriter_speed()
	return 0.05

## タイプライターの状態チェック
func is_typewriter_paused() -> bool:
	if ui_control_service:
		return ui_control_service.is_typewriter_paused()
	return false

func is_typewriter_active() -> bool:
	if ui_control_service:
		return ui_control_service.is_typewriter_active()
	return false

## タイプライターを即座に完了
func complete_typewriter():
	if ui_control_service:
		ui_control_service.complete_typewriter()

# =============================================================================
# メッセージアニメーション制御メソッド (SetMessageAnimationCommand用)
# =============================================================================

# メッセージアニメーション効果のリスト
var message_animation_effects: Array[Dictionary] = []

## メッセージアニメーション効果を追加
func add_message_animation_effect(effect_data: Dictionary):
	message_animation_effects.append(effect_data)
	ArgodeSystem.log("✨ Message animation effect added: %s" % effect_data.get("type", "unknown"))

## 全メッセージアニメーション効果をクリア
func clear_message_animations():
	message_animation_effects.clear()
	ArgodeSystem.log("🔄 All message animation effects cleared")

## メッセージアニメーションプリセットを適用
func set_message_animation_preset(preset_name: String):
	clear_message_animations()
	
	match preset_name.to_lower():
		"default":
			add_message_animation_effect({"type": "fade", "duration": 0.3})
			add_message_animation_effect({"type": "slide", "duration": 0.4, "offset_x": 0.0, "offset_y": -4.0})
		"fast":
			add_message_animation_effect({"type": "fade", "duration": 0.1})
			add_message_animation_effect({"type": "scale", "duration": 0.15})
		"dramatic":
			add_message_animation_effect({"type": "fade", "duration": 0.5})
			add_message_animation_effect({"type": "slide", "duration": 0.6, "offset_x": 0.0, "offset_y": -8.0})
			add_message_animation_effect({"type": "scale", "duration": 0.4})
		"simple":
			add_message_animation_effect({"type": "fade", "duration": 0.2})
		"none":
			# 何も追加しない（アニメーション無し）
			pass
		_:
			ArgodeSystem.log("⚠️ Unknown message animation preset: %s" % preset_name)
			return
	
	ArgodeSystem.log("🎭 Message animation preset applied: %s (%d effects)" % [preset_name, message_animation_effects.size()])

## 現在のメッセージアニメーション効果を取得
func get_message_animation_effects() -> Array[Dictionary]:
	return message_animation_effects.duplicate()

## メッセージアニメーション効果が設定されているかチェック
func has_message_animation_effects() -> bool:
	return not message_animation_effects.is_empty()

# =============================================================================
# UIControlService委譲メソッド（Phase 1, Step 1-1A 新規追加）
# =============================================================================

## UIControlServiceのメッセージシステム初期化を委譲
func ensure_ui_message_system_ready() -> void:
	"""UIControlServiceでメッセージシステムの初期化を確認"""
	if ui_control_service:
		ui_control_service.ensure_message_system_ready()
	else:
		ArgodeSystem.log_critical("🚨 UIControlService not available for message system initialization")
