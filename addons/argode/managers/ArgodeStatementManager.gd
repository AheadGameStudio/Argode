# # ステートメント管理
# 各ステートメント（インデントブロック含む）を管理
# 再帰的な構造とし、現在の実行コンテキストを管理
# StatementManagerは、個々のコマンドが持つ複雑なロジックを直接は扱わず、全体の流れを制御することに特化しています。
# スクリプト全体を俯瞰し、実行を指示するのがStatementManagerの役割。
# 一つひとつの具体的なタスク（台詞表示、ルビ描画など）を実行するのが各コマンドやサービスの役割。

extends RefCounted
class_name ArgodeStatementManager

## StatementManagerは実行制御に特化
## コマンド辞書の管理はArgodeCommandRegistryが担当

# 現在実行中のステートメントリスト
var current_statements: Array = []
# 現在実行中のステートメントインデックス
var current_statement_index: int = 0
# 現在読み込まれているファイルパス
var current_file_path: String = ""
# 実行中のステートメント（コマンドがget_current_statement()で取得するため）
var executing_statement: Dictionary = {}
# コマンドからの実行結果（jump, returnなど）
var command_result: Dictionary = {}
# 実行状態フラグ
var is_executing: bool = false
var is_paused: bool = false
var is_waiting_for_input: bool = false
var is_waiting_for_command: bool = false  # コマンド実行待ち（MenuCommandなど）
var skip_index_increment: bool = false  # 次回のインデックス増分をスキップ
var statements_inserted_by_command: bool = false  # コマンドによってステートメントが挿入された
var is_executing_child_statements: bool = false  # 子ステートメント実行中
var execution_context_stack: Array = []  # 実行コンテキストのスタック
var call_return_stack: Array = []  # Call/Returnスタック（戻り先の実行位置を保存）
var jump_executed: bool = false  # ジャンプが実行された（全コンテキスト復帰をスキップ）
var is_skipped: bool = false  # スキップされたかのフラグ
var input_debounce_timer: float = 0.0  # 入力デバウンス用
var last_input_time: int = 0  # 最後の入力時刻（ミリ秒）
const INPUT_DEBOUNCE_TIME: float = 0.1  # 入力間隔の最小時間（100ms）

# RGDパーサーのインスタンス
var rgd_parser: ArgodeRGDParser

# インラインコマンド管理
var inline_command_manager: ArgodeInlineCommandManager

# メッセージ関連の管理
var message_window: ArgodeMessageWindow = null
var message_renderer: ArgodeMessageRenderer = null

# タイプライター制御状態
var typewriter_speed_stack: Array[float] = []  # 速度スタック（ネストした速度変更に対応）
var typewriter_pause_count: int = 0  # 一時停止要求カウント（ネストした一時停止に対応）

# UI一時停止機能
var is_ui_paused: bool = false  # UI制御による一時停止フラグ
var ui_pause_reason: String = ""  # 一時停止の理由

# メッセージアニメーション設定管理
var current_animation_effects: Array[Dictionary] = []  # 現在のアニメーション効果リスト
var animation_preset: String = "default"  # 現在のアニメーションプリセット

# 入力コントローラーの参照
var controller: ArgodeController = null

func _init():
	rgd_parser = ArgodeRGDParser.new()
	inline_command_manager = ArgodeInlineCommandManager.new()
	
	# ArgodeControllerの参照を取得してシグナルを接続
	_setup_input_controller()

## ArgodeControllerとの連携を設定
func _setup_input_controller():
	# ArgodeSystemからControllerの参照を取得
	controller = ArgodeSystem.Controller
	
	if controller:
		# 入力シグナルを接続
		if not controller.input_action_pressed.is_connected(_on_input_action_pressed):
			controller.input_action_pressed.connect(_on_input_action_pressed)
		
		# デフォルトキーバインドを設定
		controller.setup_argode_default_bindings()
		
		ArgodeSystem.log("✅ StatementManager: Input controller connected")
	else:
		ArgodeSystem.log("⚠️ ArgodeController not found, input waiting disabled", 1)

## 入力アクションが押された時の処理
func _on_input_action_pressed(action_name: String):
	# Argode専用アクションのみを処理（Godotデフォルトアクションを無視）
	if not action_name.begins_with("argode_"):
		return
	
	# UI一時停止中は入力を無視
	if is_ui_paused:
		ArgodeSystem.log("⏸️ Input ignored due to UI pause: %s (reason: %s)" % [action_name, ui_pause_reason])
		return
	
	# デバウンシング処理（ミリ秒単位で処理）
	var current_time_ms = Time.get_ticks_msec()
	var time_since_last_input = (current_time_ms - last_input_time) / 1000.0  # 秒に変換
	
	if time_since_last_input < INPUT_DEBOUNCE_TIME:
		ArgodeSystem.log("⏭️ Input debounced: %.3fs since last input" % time_since_last_input)
		return
	
	last_input_time = current_time_ms
	
	# 入力待ち状態での処理
	if is_waiting_for_input:
		ArgodeSystem.log("🎮 Processing input action: %s (waiting: %s)" % [action_name, str(is_waiting_for_input)])
		match action_name:
			"argode_advance":
				# タイプライター効果が実行中の場合はスキップ
				if message_renderer and message_renderer.typewriter_service and message_renderer.typewriter_service.is_currently_typing():
					ArgodeSystem.log("⏭️ Typewriter is running, completing it")
					message_renderer.complete_typewriter()
					is_skipped = true  # スキップフラグを設定
					ArgodeSystem.log("⏭️ Typewriter effect skipped - waiting for completion")
					# タイプライター完了処理は_on_typing_finishedで行われる
				else:
					# タイプライター完了済み、または動作していない場合は次へ進む
					ArgodeSystem.log("⏭️ Typewriter not running, proceeding to next statement")
					is_waiting_for_input = false
					is_skipped = false
					ArgodeSystem.log("⏭️ User input received, continuing execution")
			
			"argode_skip":
				# スキップアクション（Ctrl、右クリック）でも同様の処理
				if message_renderer and message_renderer.typewriter_service and message_renderer.typewriter_service.is_currently_typing():
					ArgodeSystem.log("⏭️ Force skipping typewriter with skip key")
					message_renderer.complete_typewriter()
					is_skipped = true  # スキップフラグを設定
					ArgodeSystem.log("⏭️ Typewriter effect force skipped with skip key")
					# タイプライター完了処理は_on_typing_finishedで行われる
				else:
					# 即座に次へ進む
					ArgodeSystem.log("⏭️ Skip key pressed, proceeding to next statement")
					is_waiting_for_input = false
					is_skipped = false
					ArgodeSystem.log("⏭️ Skip input received, continuing execution")
	else:
		ArgodeSystem.log("🎮 Input action '%s' received but not waiting for input" % action_name)

## タイプライター完了時のコールバック
func _on_typing_finished():
	ArgodeSystem.log("✅ Typewriter finished callback received, skipped: %s" % str(is_skipped))
	
	# スキップされた場合は即座に次のステートメントに進む
	if is_skipped:
		is_waiting_for_input = false
		is_skipped = false
		ArgodeSystem.log("✅ Typewriter effect completed - automatically continuing due to skip")
	else:
		# 通常完了の場合はユーザー入力を待つ
		ArgodeSystem.log("✅ Typewriter completed - ready for user input")

## ユーザー入力を待つ
func _wait_for_user_input():
	ArgodeSystem.log("⏸️ _wait_for_user_input called")
	
	# コントローラーがない場合は再取得を試行
	if not controller:
		ArgodeSystem.log("🔄 Controller not found, attempting to retrieve...")
		_setup_input_controller()
	
	if not controller:
		# コントローラーがない場合は即座に続行
		ArgodeSystem.log("⚠️ No controller available, skipping input wait", 1)
		return
	
	# 入力待ち状態を設定してからログ出力
	is_waiting_for_input = true
	ArgodeSystem.log("⏸️ Waiting for user input... (is_waiting_for_input: %s, controller: %s)" % [str(is_waiting_for_input), str(controller != null)])
	
	# 入力があるまで待機（UI pause状態も考慮）
	while (is_waiting_for_input or is_ui_paused) and is_executing:
		if is_ui_paused:
			# UI pause中は特別な待機状態
			ArgodeSystem.log("⏸️ UI paused, waiting... (reason: %s)" % ui_pause_reason)
			await Engine.get_main_loop().process_frame
		else:
			# 通常の入力待ち
			await Engine.get_main_loop().process_frame
	
	ArgodeSystem.log("▶️ Input wait completed, continuing execution")

## タイプライター完了時のコールバック
func _on_typewriter_completed():
	# タイプライター完了後、入力待ち状態の場合は次へ進む準備完了
	if is_waiting_for_input:
		ArgodeSystem.log("✅ Typewriter finished callback received, skipped: %s" % str(is_skipped))
		if is_skipped:
			ArgodeSystem.log("✅ Typewriter was skipped - ready for user input")
			is_skipped = false  # スキップフラグをリセット
		else:
			ArgodeSystem.log("✅ Typewriter completed - ready for user input")
		# ここでは自動的に進まず、ユーザー入力を待つ

## ファイルパスからRGDファイルを読み込んで実行準備
func load_scenario_file(file_path: String) -> bool:
	if not FileAccess.file_exists(file_path):
		ArgodeSystem.log("❌ Scenario file not found: %s" % file_path, 2)
		return false
	
	ArgodeSystem.log("📖 Loading scenario file: %s" % file_path)
	
	# パーサーにコマンドレジストリを設定
	if ArgodeSystem.CommandRegistry:
		rgd_parser.set_command_registry(ArgodeSystem.CommandRegistry)
	
	# RGDファイルをパース
	current_statements = rgd_parser.parse_file(file_path)
	
	if current_statements.is_empty():
		ArgodeSystem.log("⚠️ No statements parsed from file: %s" % file_path, 1)
		return false
	
	# 現在のファイルパスを記録
	current_file_path = file_path
	
	# デバッグ出力
	ArgodeSystem.log("✅ Loaded %d statements from %s" % [current_statements.size(), file_path])
	
	# パース結果を詳細に表示
	ArgodeSystem.log("🔍 Detailed parse results:")
	for i in range(current_statements.size()):
		var stmt = current_statements[i]
		ArgodeSystem.log("  [%d] %s (line %d, type: %s)" % [i, stmt.get("name", "unknown"), stmt.get("line", 0), stmt.get("type", "unknown")])
		
		# ステートメントの全キーを表示
		ArgodeSystem.log("    Keys: %s" % str(stmt.keys()))
		
		# 子ステートメントがある場合は表示
		if stmt.has("statements") and stmt.statements.size() > 0:
			ArgodeSystem.log("    └── Has %d child statements:" % stmt.statements.size())
			for j in range(min(stmt.statements.size(), 10)):  # 最初の10個まで表示
				var child_stmt = stmt.statements[j]
				ArgodeSystem.log("        [%d] %s (line %d, type: %s)" % [j, child_stmt.get("name", "unknown"), child_stmt.get("line", 0), child_stmt.get("type", "unknown")])
		else:
			ArgodeSystem.log("    └── No child statements")
	
	if ArgodeSystem.DebugManager.is_debug_mode():
		rgd_parser.debug_print_statements(current_statements)
	else:
		# デバッグモードでない場合も、詳細なパース構造を表示
		ArgodeSystem.log("🔍 Forcing detailed parser debug for investigation:")
		rgd_parser.debug_print_statements(current_statements)
	
	# 実行インデックスをリセット
	current_statement_index = 0
	
	return true

## 定義コマンドリストを実行（起動時の定義処理用）
func execute_definition_statements(statements: Array) -> bool:
	if statements.is_empty():
		ArgodeSystem.log("⚠️ No definition statements to execute", 1)
		return true
	
	# 実行中の競合をチェック
	if is_executing:
		ArgodeSystem.log("⚠️ Cannot execute definition statements: StatementManager is already executing", 1)
		return false
	
	ArgodeSystem.log("🔧 Executing %d definition statements" % statements.size())
	
	# 定義コマンドのみを順次実行（分離された実行環境）
	for statement in statements:
		if statement.get("type") == "command":
			var command_name = statement.get("name", "")
			
			# 定義コマンドかチェック
			if ArgodeSystem.CommandRegistry.is_define_command(command_name):
				await _execute_definition_statement(statement)
			else:
				ArgodeSystem.log("⚠️ Skipping non-definition command: %s" % command_name, 1)
	
	ArgodeSystem.log("✅ Definition statements execution completed")
	return true

## 定義ステートメント専用の実行（通常実行と分離）
func _execute_definition_statement(statement: Dictionary):
	var statement_name = statement.get("name", "")
	var statement_args = statement.get("args", [])
	
	ArgodeSystem.log("🔧 Executing definition command: %s" % statement_name)
	
	# 定義コマンドを直接実行（通常の実行フローを使わない）
	await _execute_command(statement_name, statement_args)

## 指定ラベルから実行を開始
func play_from_label(label_name: String) -> bool:
	# ArgodeLabelRegistryからラベル情報を取得
	var label_info = ArgodeSystem.LabelRegistry.get_label(label_name)
	if label_info.is_empty():
		ArgodeSystem.log("❌ Label not found: %s" % label_name, 2)
		return false
	
	var file_path = label_info.get("path", "")
	var label_line = label_info.get("line", 0)
	
	# シナリオファイルを読み込み
	if not load_scenario_file(file_path):
		return false
	
	# ラベル行から開始するように調整
	var start_index = _find_statement_index_by_line(label_line)
	if start_index >= 0:
		current_statement_index = start_index
		ArgodeSystem.log("🎬 Starting execution from label '%s' at line %d (statement index %d)" % [label_name, label_line, start_index])
	else:
		ArgodeSystem.log("⚠️ Could not find statement at label line %d, starting from beginning" % label_line, 1)
		current_statement_index = 0
	
	# 実行開始
	return await start_execution()

## 実行を開始
func start_execution() -> bool:
	if current_statements.is_empty():
		ArgodeSystem.log("❌ No statements to execute", 2)
		return false
	
	# 実行開始のコールスタックをログ出力
	ArgodeSystem.log("🚀 start_execution() called from:")
	var stack = get_stack()
	for frame in stack:
		ArgodeSystem.log("  📂 %s:%d in %s()" % [frame.source, frame.line, frame.function])
	
	is_executing = true
	is_paused = false
	is_ui_paused = false  # UI一時停止もリセット
	is_waiting_for_command = false  # コマンド待ちもリセット
	
	ArgodeSystem.log("▶️ Starting statement execution from index %d" % current_statement_index)
	
	# ステートメントを順次実行
	while current_statement_index < current_statements.size() and is_executing and not is_paused:
		ArgodeSystem.log("🔍 Loop iteration: index=%d, size=%d, executing=%s, paused=%s" % [current_statement_index, current_statements.size(), is_executing, is_paused])
		
		# ジャンプが実行された場合は即座にループを終了
		if jump_executed:
			ArgodeSystem.log("🎯 Jump executed - breaking main execution loop")
			break
		
		# 一時停止状態の場合はループを抜ける
		if is_paused:
			ArgodeSystem.log("⏸️ Execution paused during loop, breaking")
			break
		
		ArgodeSystem.log("🔍 About to execute statement at index %d (total: %d)" % [current_statement_index, current_statements.size()])
		
		# 配列から正しいステートメントを取得
		var statement = current_statements[current_statement_index]
		ArgodeSystem.log("📋 Loop fetched statement: %s (line %d) from array[%d]" % [statement.get("name", "unknown"), statement.get("line", 0), current_statement_index])
		
		await _execute_single_statement(statement)
		
		# ジャンプが実行された場合は即座にループを終了（ステートメント実行後チェック）
		if jump_executed:
			ArgodeSystem.log("🎯 Jump executed after statement - breaking main execution loop")
			break
		
		# コマンド実行待ち状態の場合は待機
		while is_waiting_for_command and is_executing:
			ArgodeSystem.log("⏸️ Waiting for command completion...")
			await Engine.get_main_loop().process_frame
		
		# インデックス増分のスキップフラグをチェック
		ArgodeSystem.log("🔍 Index increment check: skip_flag=%s, current_index=%d" % [skip_index_increment, current_statement_index])
		if skip_index_increment:
			skip_index_increment = false
			ArgodeSystem.log("🔄 Skipping index increment (statements were inserted)")
		else:
			current_statement_index += 1
			ArgodeSystem.log("➡️ Index incremented to %d" % current_statement_index)
		
		# デバッグ: ループ継続条件をチェック
		var will_continue = current_statement_index < current_statements.size() and is_executing and not is_paused
		ArgodeSystem.log("🔍 Loop continuation check: index=%d < size=%d, executing=%s, not_paused=%s -> %s" % [
			current_statement_index, current_statements.size(), is_executing, not is_paused, will_continue
		])
	
	# 実行完了
	is_executing = false
	ArgodeSystem.log("🏁 Statement execution completed")
	
	return true

## 単一ステートメントを実行
func _execute_single_statement(statement: Dictionary):
	var statement_type = statement.get("type", "")
	var statement_name = statement.get("name", "")
	var statement_args = statement.get("args", [])
	var statement_line = statement.get("line", 0)
	
	# デバッグ: 呼び出し元を特定
	var caller_info = "unknown"
	if get_stack().size() > 1:
		var caller_frame = get_stack()[1]
		caller_info = "%s:%d" % [caller_frame.function, caller_frame.line]
	ArgodeSystem.log("📞 _execute_single_statement called from: %s" % caller_info)
	
	# デバッグ: 実行予定のステートメントと配列の内容を比較
	if current_statement_index < current_statements.size():
		var expected_statement = current_statements[current_statement_index]
		var expected_line = expected_statement.get("line", 0)
		var expected_name = expected_statement.get("name", "unknown")
		
		if statement_line != expected_line or statement_name != expected_name:
			ArgodeSystem.log("❌ MISMATCH! Expected: %s (line %d), Got: %s (line %d)" % [expected_name, expected_line, statement_name, statement_line])
			ArgodeSystem.log("🔍 Array[%d]: %s (line %d)" % [current_statement_index, expected_name, expected_line])
			ArgodeSystem.log("🔍 Received: %s (line %d)" % [statement_name, statement_line])
		else:
			ArgodeSystem.log("✅ Statement matches array[%d]: %s (line %d)" % [current_statement_index, statement_name, statement_line])
	
	# 実行中のステートメントを保存（コマンドがget_current_statement()で取得するため）
	executing_statement = statement
	
	ArgodeSystem.log("🎯 Executing statement: %s (line %d) [index: %d]" % [statement_name, statement_line, current_statement_index])
	
	# デバッグ: ステートメントの詳細を出力
	if statement_name != "menu":  # MenuCommand以外の場合のみ詳細ログ
		ArgodeSystem.log("🔍 Statement details: type=%s, line=%d, from_index=%d" % [statement_type, statement_line, current_statement_index])
		ArgodeSystem.log("🔍 Current execution state: executing=%s, paused=%s, waiting=%s" % [is_executing, is_paused, is_waiting_for_command])
	
	match statement_type:
		"command":
			await _execute_command(statement_name, statement_args)
			
			# 特定のコマンドは自分で子ステートメントを管理するため、自動実行をスキップ
			var commands_managing_own_statements = ["if"]  # menuを除外：先に子ステートメント実行してからコマンド実行
			var should_skip_auto_execution = statement_name in commands_managing_own_statements
			
			# 子ステートメントがある場合は実行（ただし自己管理コマンドは除く）
			if statement.has("statements") and statement.statements.size() > 0 and not should_skip_auto_execution:
				await _execute_child_statements(statement.statements)
				
				# labelコマンドなどのブロック構造コマンドは子ステートメント実行後に次へ進む
				if statement_name == "label":
					ArgodeSystem.log("🏷️ Label block execution completed, proceeding to next statement")
					# skip_index_incrementをfalseにして通常のインデックス進行を行う
					skip_index_increment = false
			elif should_skip_auto_execution:
				ArgodeSystem.log("🔄 Skipping auto child statement execution for self-managing command: %s" % statement_name)
		"say":
			# Sayコマンドは特別にStatementManagerで処理
			await _handle_say_command(statement_args)
		_:
			ArgodeSystem.log("⚠️ Unknown statement type: %s" % statement_type, 1)
	
	# 実行完了後にクリア
	executing_statement = {}

## 子ステートメントを実行
func _execute_child_statements(child_statements: Array):
	# 実行コンテキストの重複チェック（警告のみに変更）
	if is_executing:
		ArgodeSystem.log("� Note: Child statements executing while main execution is active (this may be normal for label blocks)", 1)
	
	# 呼び出し元の詳細情報をログ出力
	ArgodeSystem.log("🔄 _execute_child_statements called with %d statements" % child_statements.size())
	var stack = get_stack()
	ArgodeSystem.log("📞 Call stack for _execute_child_statements:")
	for i in range(min(stack.size(), 5)):  # 最大5フレーム表示
		var frame = stack[i]
		ArgodeSystem.log("  [%d] %s:%d in %s()" % [i, frame.source.get_file(), frame.line, frame.function])
	
	# 実行状態の詳細をログ出力
	ArgodeSystem.log("🔍 Execution state before child statements:")
	ArgodeSystem.log("  - current_statement_index: %d" % current_statement_index)
	ArgodeSystem.log("  - skip_index_increment: %s" % str(skip_index_increment))
	ArgodeSystem.log("  - is_executing: %s" % str(is_executing))
	ArgodeSystem.log("  - current_statements.size(): %d" % current_statements.size())
	
	# 子ステートメントの詳細をログ出力
	for i in range(child_statements.size()):
		var stmt = child_statements[i]
		ArgodeSystem.log("🔍 Child statement[%d]: %s (line %d)" % [i, stmt.get("name", "unknown"), stmt.get("line", 0)])
	
	# 現在の実行コンテキストを保存
	var saved_statements = current_statements
	var saved_index = current_statement_index
	var saved_executing_statement = executing_statement
	
	ArgodeSystem.log("💾 Saving execution context: %d statements, index %d" % [saved_statements.size(), saved_index])
	
	# 子実行状態を設定
	is_executing_child_statements = true
	execution_context_stack.push_back({
		"statements": saved_statements,
		"index": saved_index,
		"executing_statement": saved_executing_statement
	})
	
	for child_statement in child_statements:
		# 個別のステートメント実行（コンテキストを混同しない）
		executing_statement = child_statement
		
		var command_name = child_statement.get("name", "")
		var statement_type = child_statement.get("type", "")
		ArgodeSystem.log("🔍 Executing child statement: %s (type: %s)" % [command_name, statement_type])
		
		# sayコマンドは特別処理が必要
		if statement_type == "say":
			ArgodeSystem.log("🎭 Handling say command in child context with args: %s" % str(child_statement.get("args", [])))
			await _handle_say_command(child_statement.get("args", []))
			ArgodeSystem.log("✅ Say command completed in child context")
		else:
			await _execute_command(command_name, child_statement.get("args", []))
		
		# MenuCommandなどの特別なコマンドが実行された場合、
		# 親コンテキストに影響を与える可能性があるため確認
		if command_name == "menu" and statements_inserted_by_command:
			ArgodeSystem.log("🎯 MenuCommand execution inserted statements, breaking child execution")
			break
	# 子実行中にジャンプが発生した場合は、コンテキスト復帰をスキップ
	if not is_executing_child_statements or jump_executed:
		if jump_executed:
			ArgodeSystem.log("🔄 Jump executed - skipping all context restoration")
		else:
			ArgodeSystem.log("🔄 Jump executed during child statements - skipping context restoration")
		return
	
	# 実行コンテキストを復元
	current_statements = saved_statements
	current_statement_index = saved_index
	executing_statement = saved_executing_statement
	
	ArgodeSystem.log("🔄 Restored execution context: %d statements, index %d" % [current_statements.size(), current_statement_index])
	
	# コマンドによる挿入があった場合は親のインデックス制御に反映
	if statements_inserted_by_command:
		ArgodeSystem.log("🎯 Statements were inserted by child command, adjusting parent index")
		# skip_index_incrementを設定して親のループでインデックス進行を制御
		skip_index_increment = true
		statements_inserted_by_command = false  # フラグをリセット
	
	# 実行状態の詳細をログ出力
	ArgodeSystem.log("🔍 Execution state after child statements:")
	ArgodeSystem.log("  - current_statement_index: %d" % current_statement_index)
	ArgodeSystem.log("  - skip_index_increment: %s" % str(skip_index_increment))
	ArgodeSystem.log("  - is_executing: %s" % str(is_executing))
	ArgodeSystem.log("  - current_statements.size(): %d" % current_statements.size())

## Sayコマンドの特別処理
func _handle_say_command(args: Array):
	ArgodeSystem.log("🎭 _handle_say_command called with args: %s" % str(args))
	
	# まずSayCommandを実行（ログ出力等）
	await _execute_command("say", args)
	
	# メッセージウィンドウとレンダラーの初期化確認
	_ensure_message_system_ready()
	
	# 引数からキャラクター名とメッセージを抽出
	var character_name = ""
	var message_text = ""
	
	if args.size() >= 2:
		# キャラクター名がある場合: say ["キャラクター名", "メッセージ"]
		character_name = args[0]
		message_text = args[1]
	elif args.size() >= 1:
		# キャラクター名がない場合: say ["メッセージ"]
		message_text = args[0]
	else:
		ArgodeSystem.log("⚠️ Say command called with no arguments", 1)
		return
	
	ArgodeSystem.log("🎭 Processing say: character='%s', message='%s'" % [character_name, message_text])
	
	# InlineCommandManagerでテキストを前処理
	var processed_data = inline_command_manager.process_text(message_text)
	var display_text = processed_data.display_text
	var position_commands = processed_data.position_commands
	
	# 現在のアニメーション設定をレンダラーに適用
	apply_current_animations_to_renderer()
	
	# MessageRendererに表示用テキストと位置ベースコマンドを渡して表示
	if message_renderer:
		ArgodeSystem.log("🎭 Calling message_renderer.render_message_with_position_commands")
		message_renderer.render_message_with_position_commands(
			character_name, 
			display_text, 
			position_commands,
			inline_command_manager
		)
		ArgodeSystem.log("🎭 Message rendering initiated, waiting for user input")
	else:
		ArgodeSystem.log("❌ No message_renderer available", 2)
		return
	
	# ユーザー入力を待つ
	ArgodeSystem.log("⏸️ _handle_say_command: About to wait for user input")
	await _wait_for_user_input()
	ArgodeSystem.log("✅ _handle_say_command: User input completed")

## コマンドを実行
func _execute_command(command_name: String, args: Array):
	if not ArgodeSystem.CommandRegistry.has_command(command_name):
		ArgodeSystem.log("❌ Command not found: %s" % command_name, 2)
		return
	
	# コマンド実行前にcommand_resultをクリア
	command_result.clear()
	
	# コマンドデータを取得し、インスタンスを抽出
	var command_data = ArgodeSystem.CommandRegistry.get_command(command_name)
	if command_data.is_empty():
		ArgodeSystem.log("❌ Command data not found: %s" % command_name, 2)
		return
	
	var command_instance = command_data.get("instance")
	if command_instance and command_instance.has_method("execute"):
		# 引数をArrayからDictionaryに変換
		var args_dict = _convert_args_to_dict(args)
		# StatementManagerの参照を追加（Call/Returnコマンド用）
		args_dict["statement_manager"] = self
		args_dict["parsed_line"] = args  # 元の引数配列も保持
		await command_instance.execute(args_dict)
		
		# コマンド実行後にcommand_resultをチェック
		if not command_result.is_empty():
			await _process_command_result()
	else:
		ArgodeSystem.log("❌ Command '%s' does not have execute method" % command_name, 2)

## 引数のArrayをDictionaryに変換
func _convert_args_to_dict(args: Array) -> Dictionary:
	var result = {}
	
	# 引数が空の場合は空のDictionaryを返す
	if args.is_empty():
		return result
	
	# 引数を順序付きで保存
	for i in range(args.size()):
		result["arg" + str(i)] = args[i]
	
	# 特別なキーワード引数の処理
	var current_key = ""
	var skip_next = false
	
	for i in range(args.size()):
		if skip_next:
			skip_next = false
			continue
			
		var arg = str(args[i])
		
		# キーワード引数の処理 (例: "path", "color", etc.)
		if i + 1 < args.size() and _is_keyword_argument(arg):
			current_key = arg
			result[current_key] = args[i + 1]
			skip_next = true
		elif current_key == "" and i < 3:
			# 最初の3つの引数は位置引数として扱う
			match i:
				0:
					result["target"] = arg
				1:
					result["name"] = arg
				2:
					result["value"] = arg
	
	return result

## キーワード引数かどうかを判定
func _is_keyword_argument(arg: String) -> bool:
	var keywords = ["path", "color", "prefix", "layer", "position", "size", "volume", "loop"]
	return arg in keywords

## 行番号からステートメントインデックスを検索
func _find_statement_index_by_line(target_line: int) -> int:
	"""指定された行番号のステートメントインデックスを検索"""
	ArgodeSystem.log("🔍 Searching for statement at line %d in %d statements" % [target_line, current_statements.size()])
	
	for i in range(current_statements.size()):
		var statement = current_statements[i]
		var statement_line = statement.get("line", 0)
		var statement_name = statement.get("name", "unknown")
		var statement_type = statement.get("type", "unknown")
		
		ArgodeSystem.log("  [%d]: %s (%s) at line %d" % [i, statement_name, statement_type, statement_line])
		
		# 正確な行番号一致を確認
		if statement_line == target_line:
			ArgodeSystem.log("✅ Exact match found at index %d: %s (line %d)" % [i, statement_name, statement_line])
			return i
	
	ArgodeSystem.log("❌ No exact match found for line %d" % target_line)
	return -1

## 実行を一時停止
func pause_execution():
	is_paused = true
	ArgodeSystem.log("⏸️ Statement execution paused")

## 実行を再開
func resume_execution():
	if is_paused:
		is_paused = false
		ArgodeSystem.log("▶️ Statement execution resumed")
		await start_execution()

## 実行を停止
func stop_execution():
	is_executing = false
	is_paused = false
	is_waiting_for_input = false
	is_waiting_for_command = false
	skip_index_increment = false
	current_statement_index = 0
	ArgodeSystem.log("⏹️ Statement execution stopped")

## コマンド実行待ち状態を設定
func set_waiting_for_command(waiting: bool, reason: String = ""):
	is_waiting_for_command = waiting
	if waiting:
		ArgodeSystem.log("⏸️ Statement execution paused for command: %s" % reason)
	else:
		ArgodeSystem.log("▶️ Statement execution resumed from command: %s" % reason)

## 現在の実行状態を取得
func is_running() -> bool:
	return is_executing and not is_paused

## デバッグ情報を出力
func debug_print_current_state():
	ArgodeSystem.log("🔍 StatementManager Debug Info:")
	ArgodeSystem.log("  - Current statements: %d" % current_statements.size())
	ArgodeSystem.log("  - Current index: %d" % current_statement_index)
	ArgodeSystem.log("  - Is executing: %s" % str(is_executing))
	ArgodeSystem.log("  - Is paused: %s" % str(is_paused))
	ArgodeSystem.log("  - Is waiting for input: %s" % str(is_waiting_for_input))

## メッセージシステムの準備を確認・初期化
func _ensure_message_system_ready():
	# メッセージウィンドウの初期化
	if not message_window:
		_initialize_message_window()
	
	# メッセージレンダラーの初期化
	if not message_renderer and message_window:
		_initialize_message_renderer()
	
	# インラインコマンドマネージャーの初期化
	if inline_command_manager and not inline_command_manager.tag_registry.tag_command_dictionary.size():
		_initialize_inline_command_manager()

## メッセージウィンドウを初期化
func _initialize_message_window():
	var gui_layer = ArgodeSystem.LayerManager.get_gui_layer()
	if not gui_layer:
		ArgodeSystem.log("❌ GUI layer not available for message window", 2)
		return
	
	# デフォルトメッセージウィンドウシーンを読み込み
	var message_window_scene = load("res://addons/argode/builtin/scenes/default_message_window/default_message_window.tscn")
	if not message_window_scene:
		ArgodeSystem.log("❌ Default message window scene not found", 2)
		return
	
	# メッセージウィンドウをインスタンス化
	message_window = message_window_scene.instantiate()
	if not message_window:
		ArgodeSystem.log("❌ Failed to instantiate message window", 2)
		return
	
	# GUIレイヤーに追加
	gui_layer.add_child(message_window)
	
	# アクティブ状態変更シグナルを接続
	if message_window.has_signal("active_state_changed"):
		message_window.active_state_changed.connect(_on_message_window_active_state_changed)
	
	# 初期状態では非表示
	message_window.visible = false
	
	ArgodeSystem.log("✅ StatementManager: Message window initialized")

## メッセージウィンドウのアクティブ状態変更時の処理
func _on_message_window_active_state_changed(is_active: bool):
	if is_active:
		# メッセージウィンドウがアクティブになった場合、UI一時停止を解除
		resume_ui_operations("メッセージウィンドウがアクティブになりました")
	else:
		# メッセージウィンドウが非アクティブになった場合、UI一時停止を実行
		pause_ui_operations("メッセージウィンドウが非アクティブになりました")

## UI操作による一時停止
func pause_ui_operations(reason: String):
	if is_ui_paused:
		return  # 既に一時停止中
	
	is_ui_paused = true
	ui_pause_reason = reason
	
	# MenuCommand以外の場合のみタイプライターを一時停止
	if not reason.contains("MenuCommand"):
		if message_renderer and message_renderer.typewriter_service:
			message_renderer.typewriter_service.pause_typing()
	
	ArgodeSystem.log("⏸️ UI operations paused: %s" % reason)

## UI操作による一時停止を解除
func resume_ui_operations(reason: String):
	if not is_ui_paused:
		return  # 一時停止していない
	
	is_ui_paused = false
	ui_pause_reason = ""
	
	# MenuCommand以外の場合のみタイプライターを再開
	if not reason.contains("MenuCommand"):
		if message_renderer and message_renderer.typewriter_service:
			message_renderer.typewriter_service.resume_typing()
	
	ArgodeSystem.log("▶️ UI operations resumed: %s" % reason)

## メッセージレンダラーを初期化
func _initialize_message_renderer():
	if not message_window:
		ArgodeSystem.log("❌ Cannot initialize renderer without message window", 2)
		return
	
	# MessageRendererを作成してメッセージウィンドウを設定
	message_renderer = ArgodeMessageRenderer.new()
	message_renderer.set_message_window(message_window)
	
	# タイプライター完了コールバックを設定
	message_renderer.set_typewriter_completion_callback(_on_typing_finished)
	
	ArgodeSystem.log("✅ StatementManager: Message renderer initialized")

## インラインコマンドマネージャーを初期化
func _initialize_inline_command_manager():
	if ArgodeSystem.CommandRegistry:
		inline_command_manager.initialize_tag_registry(ArgodeSystem.CommandRegistry)
		ArgodeSystem.log("✅ StatementManager: Inline command manager initialized")

# =============================================================================
# タイプライター制御機能 (コマンドから使用)
# =============================================================================

## タイプライターを一時停止 (ネスト対応)
func pause_typewriter():
	typewriter_pause_count += 1
	if message_renderer and message_renderer.typewriter_service:
		message_renderer.typewriter_service.pause_typing()
		ArgodeSystem.log("⏸️ StatementManager: Typewriter paused (count: %d)" % typewriter_pause_count)

## タイプライターを再開 (ネスト対応)
func resume_typewriter():
	if typewriter_pause_count > 0:
		typewriter_pause_count -= 1
		
		# すべての一時停止要求が解除された場合のみ再開
		if typewriter_pause_count == 0:
			if message_renderer and message_renderer.typewriter_service:
				message_renderer.typewriter_service.resume_typing()
				ArgodeSystem.log("▶️ StatementManager: Typewriter resumed")

## タイプライター速度を変更 (スタック管理でネスト対応)
func push_typewriter_speed(new_speed: float):
	# 現在の速度を保存
	var current_speed = get_current_typewriter_speed()
	typewriter_speed_stack.push_back(current_speed)
	
	# 新しい速度を適用
	if message_renderer and message_renderer.typewriter_service:
		message_renderer.typewriter_service.typing_speed = new_speed
		ArgodeSystem.log("⚡ StatementManager: Typewriter speed changed: %.3f → %.3f" % [current_speed, new_speed])

## タイプライター速度を復元 (スタックからポップ)
func pop_typewriter_speed():
	if typewriter_speed_stack.size() > 0:
		var previous_speed = typewriter_speed_stack.pop_back()
		
		if message_renderer and message_renderer.typewriter_service:
			message_renderer.typewriter_service.typing_speed = previous_speed
			ArgodeSystem.log("⚡ StatementManager: Typewriter speed restored: %.3f" % previous_speed)

## 現在のタイプライター速度を取得
func get_current_typewriter_speed() -> float:
	if message_renderer and message_renderer.typewriter_service:
		return message_renderer.typewriter_service.typing_speed
	return 0.05  # デフォルト値

## タイプライターが一時停止中かチェック
func is_typewriter_paused() -> bool:
	return typewriter_pause_count > 0

## タイプライターが実行中かチェック
func is_typewriter_active() -> bool:
	if message_renderer and message_renderer.typewriter_service:
		return message_renderer.typewriter_service.is_typing
	return false

# =============================================================================
# メッセージアニメーション管理機能 (SetMessageAnimationCommandから使用)
# =============================================================================

## アニメーション効果をクリア
func clear_message_animations():
	current_animation_effects.clear()
	ArgodeSystem.log("🧹 StatementManager: Message animation effects cleared")

## アニメーション効果を追加
func add_message_animation_effect(effect_data: Dictionary):
	current_animation_effects.append(effect_data)
	var effect_type = effect_data.get("type", "unknown")
	ArgodeSystem.log("✨ StatementManager: Animation effect added: %s" % effect_type)

## アニメーションプリセットを設定
func set_message_animation_preset(preset_name: String):
	animation_preset = preset_name
	ArgodeSystem.log("🎭 StatementManager: Animation preset set: %s" % preset_name)

## 現在のアニメーション設定をメッセージレンダラーに適用
func apply_current_animations_to_renderer():
	if not message_renderer:
		return
	
	# アニメーション効果をクリア
	if message_renderer.animation_coordinator and message_renderer.animation_coordinator.character_animation:
		message_renderer.animation_coordinator.character_animation.animation_effects.clear()
		
		# 現在の効果を追加
		for effect_data in current_animation_effects:
			_create_and_add_animation_effect(effect_data)
		
		# プリセットを適用
		if animation_preset != "default":
			message_renderer.set_animation_preset(animation_preset)
		
		ArgodeSystem.log("🎨 StatementManager: Applied %d animation effects to renderer" % current_animation_effects.size())

## アニメーション効果データからエフェクトインスタンスを作成して追加
func _create_and_add_animation_effect(effect_data: Dictionary):
	if not message_renderer or not message_renderer.animation_coordinator or not message_renderer.animation_coordinator.character_animation:
		return
	
	var character_animation = message_renderer.animation_coordinator.character_animation
	var effect_type = effect_data.get("type", "")
	
	# MessageAnimationRegistryを使用してエフェクトを作成
	var animation_effect = ArgodeSystem.MessageAnimationRegistry.create_effect(effect_type)
	if not animation_effect:
		ArgodeSystem.log("⚠️ Unknown animation effect type: %s" % effect_type, 2)
		return
	
	# パラメータを設定
	var duration = effect_data.get("duration", 0.3)
	animation_effect.set_duration(duration)
	
	# エフェクト固有のパラメータを設定
	match effect_type:
		"slide":
			var offset_x = effect_data.get("offset_x", 0.0)
			var offset_y = effect_data.get("offset_y", 0.0)
			if animation_effect.has_method("set_offset"):
				animation_effect.set_offset(offset_x, offset_y)
	
	# エフェクトを追加
	character_animation.add_effect(animation_effect)

## コマンドサポート用メソッド

## 現在のステートメント情報を取得（コマンド用）
func get_current_statement() -> Dictionary:
	"""現在実行中のステートメント情報を返す"""
	if executing_statement.is_empty():
		ArgodeSystem.log("⚠️ No statement currently executing")
		return {}
	
	ArgodeSystem.log("📋 Providing executing statement to command: Type=%s, Name=%s" % [
		executing_statement.get("type", "unknown"),
		executing_statement.get("name", "unknown")
	])
	return executing_statement

## コマンドからの実行結果を処理（汎用インターフェース）
func handle_command_result(result_data: Dictionary):
	"""
	コマンドからの実行結果を受け取って適切に処理する汎用インターフェース
	
	result_data の形式例:
	{
		"type": "statements",  # 実行するステートメント群
		"statements": [...],   # 実行対象のステートメント配列
		"insert_mode": "after_current"  # 挿入位置 ("after_current", "replace_current", "at_end")
	}
	
	{
		"type": "jump",        # ラベルジャンプ
		"label": "label_name"  # ジャンプ先ラベル
	}
	
	{
		"type": "variable",    # 変数設定
		"variable": "result",  # 変数名
		"value": "selected_choice"  # 設定値
	}
	
	{
		"type": "continue"     # 単純に次のステートメントに進む
	}
	"""
	var result_type = result_data.get("type", "continue")
	
	ArgodeSystem.log("✅ Processing command result: %s" % result_type)
	
	match result_type:
		"statements":
			_handle_statements_result(result_data)
		"jump":
			_handle_jump_result(result_data)
		"variable":
			_handle_variable_result(result_data)
		"continue":
			_handle_continue_result()
		_:
			ArgodeSystem.log("⚠️ Unknown command result type: %s" % result_type, 1)
			_handle_continue_result()  # デフォルトは継続

## ステートメント実行結果の処理
func _handle_statements_result(result_data: Dictionary):
	"""ステートメント群を実行キューに追加"""
	var statements = result_data.get("statements", [])
	var insert_mode = result_data.get("insert_mode", "after_current")
	
	if statements.is_empty():
		ArgodeSystem.log("⚠️ No statements provided in result", 1)
		return
	
	ArgodeSystem.log("📝 Adding %d statements to execution queue (mode: %s)" % [statements.size(), insert_mode])
	ArgodeSystem.log("🔍 Current statement index: %d, Total statements: %d" % [current_statement_index, current_statements.size()])
	
	# ステートメントの詳細をログ出力
	for i in range(statements.size()):
		var stmt = statements[i]
		ArgodeSystem.log("📋 Adding statement %d: Type=%s, Name=%s" % [i, stmt.get("type", "unknown"), stmt.get("name", "unknown")])
	
	match insert_mode:
		"after_current":
			# 現在のステートメントの後に挿入
			for i in range(statements.size()):
				current_statements.insert(current_statement_index + 1 + i, statements[i])
			# 挿入されたステートメントから実行を再開するため、現在のインデックスを調整
			# 次のループで最初の挿入されたステートメント（current_statement_index + 1）が実行される
			# skip_index_incrementは使わず、直接インデックスを進める
			ArgodeSystem.log("✅ Inserted %d statements after current index %d (advancing to %d)" % [statements.size(), current_statement_index, current_statement_index + 1])
			
			# 直接インデックスを進めて挿入されたステートメントを実行対象にする
			current_statement_index += 1
			statements_inserted_by_command = true  # コマンドによる挿入フラグを設定
			
			# デバッグ: 挿入後のステートメント配列を確認
			ArgodeSystem.log("🔍 Statement array after insertion:")
			for j in range(current_statements.size()):
				var stmt = current_statements[j]
				var marker = " ← NEW CURRENT" if j == current_statement_index else ""
				var prev_marker = " ← PREVIOUS" if j == current_statement_index - 1 else ""
				ArgodeSystem.log("  [%d]: %s (line %d)%s%s" % [j, stmt.get("name", "unknown"), stmt.get("line", 0), marker, prev_marker])
		
		"replace_current":
			# 現在のステートメントを置き換え
			current_statements[current_statement_index] = statements[0]
			for i in range(1, statements.size()):
				current_statements.insert(current_statement_index + i, statements[i])
			# 置き換えたステートメントを実行するため、インデックスを1つ戻す
			current_statement_index -= 1
		
		"at_end":
			# 最後に追加
			current_statements.append_array(statements)
			# インデックスはstart_execution()のループで自動的に進むのでここでは何もしない
		
		_:
			ArgodeSystem.log("⚠️ Unknown insert mode: %s" % insert_mode, 1)

## ジャンプ結果の処理  
func _handle_jump_result(result_data: Dictionary):
	"""指定ラベルにジャンプ"""
	var label_name = result_data.get("label", "")
	var file_path = result_data.get("file_path", "")
	var label_line = result_data.get("line", 0)
	
	if label_name.is_empty():
		ArgodeSystem.log("⚠️ No label specified for jump", 1)
		return
	
	ArgodeSystem.log("🎯 Executing jump to label: %s" % label_name)
	
	# 同じファイル内のジャンプかチェック
	if file_path != current_file_path:
		# 異なるファイルの場合は新しいファイルを読み込み
		ArgodeSystem.log("📄 Loading new file for jump: %s" % file_path)
		if not load_scenario_file(file_path):
			ArgodeSystem.log("❌ Failed to load scenario file: %s" % file_path, 2)
			return
	
	# ラベル行に対応するステートメントインデックスを検索
	var target_index = _find_statement_index_by_line(label_line)
	if target_index >= 0:
		ArgodeSystem.log("✅ Jump target found at statement index: %d" % target_index)
		# 現在のインデックスを更新
		current_statement_index = target_index
		# ジャンプが発生したことを示すフラグを設定
		skip_index_increment = true
		statements_inserted_by_command = true  # メインループでインデックス増分をスキップ
		
		# ジャンプは実行コンテキストを変更するため、子実行から戻らない
		is_executing_child_statements = false
		execution_context_stack.clear()
		jump_executed = true  # グローバルジャンプフラグを設定
		
		# 全ての実行を停止
		is_executing = false
		is_paused = true  # 実行を一時停止して継続を防ぐ
		
		ArgodeSystem.log("🎯 Jump executed: index=%d, skip_increment=%s" % [current_statement_index, skip_index_increment])
		ArgodeSystem.log("🔄 Jump cleared execution context to prevent return to parent")
		ArgodeSystem.log("🔄 Stopping all execution before jump")
		
		# 次のフレームで新しい実行を開始
		await Engine.get_main_loop().process_frame
		
		# 実行状態をリセットして新しい実行を開始
		is_paused = false
		jump_executed = false
		
		# 新しい位置から実行を開始
		await start_execution()
	else:
		ArgodeSystem.log("❌ Could not find statement for label line %d" % label_line, 2)
		# ジャンプに失敗した場合は単純に次に進む

## 変数設定結果の処理
func _handle_variable_result(result_data: Dictionary):
	"""変数を設定"""
	var variable_name = result_data.get("variable", "")
	var variable_value = result_data.get("value", "")
	
	if variable_name.is_empty():
		ArgodeSystem.log("⚠️ No variable name specified", 1)
		_handle_continue_result()
		return
	
	# 変数設定を実行
	ArgodeSystem.log("📊 Setting variable: %s = %s" % [variable_name, str(variable_value)])
	await _execute_command("set", [variable_name, "=", variable_value])
	_handle_continue_result()

## 継続結果の処理
func _handle_continue_result():
	"""単純に次のステートメントに進む（何もしない）"""
	# インデックスの進行はstart_execution()のループで自動的に行われるため
	# ここでは何もしない
	ArgodeSystem.log("▶️ Command completed, continuing to next statement")

## コマンド実行結果を処理
func _process_command_result():
	"""コマンドが設定したcommand_resultを処理"""
	var result = command_result.get("result", "")
	
	ArgodeSystem.log("🔍 Processing command result: %s" % result)
	
	match result:
		"jump":
			await _handle_jump_result(command_result)
		"return":
			await _handle_return_result(command_result)
		"return_to_child_execution":
			_handle_return_to_child_execution()
		_:
			ArgodeSystem.log("⚠️ Unknown command result: %s" % result, 1)

## Return結果の処理
func _handle_return_result(result_data: Dictionary):
	"""Returnコマンドの結果を処理して戻り先にジャンプ"""
	var return_index = result_data.get("return_index", -1)
	var return_file_path = result_data.get("return_file_path", "")
	
	if return_index == -1 or return_file_path.is_empty():
		ArgodeSystem.log("❌ Invalid return context", 2)
		return
	
	ArgodeSystem.log("🔙 Executing return to index %d in file %s" % [return_index, return_file_path])
	
	# 戻り先のファイルが現在のファイルと異なる場合は、ファイルを切り替える
	if return_file_path != current_file_path:
		ArgodeSystem.log("📄 Loading return file: %s" % return_file_path)
		if not load_scenario_file(return_file_path):
			ArgodeSystem.log("❌ Failed to load return file: %s" % return_file_path, 2)
			return
	
	# インデックスが有効範囲内かチェック
	if return_index >= current_statements.size():
		ArgodeSystem.log("⚠️ Return index %d is beyond statements array size %d - ending execution" % [return_index, current_statements.size()], 1)
		is_executing = false
		return
	
	# 戻り先のインデックスを設定
	current_statement_index = return_index
	skip_index_increment = true  # 次回のインデックス増分をスキップ
	statements_inserted_by_command = true  # メインループでインデックス増分をスキップ
	
	# 実行コンテキストをクリア（Returnは新しい実行フローを開始）
	is_executing_child_statements = false
	execution_context_stack.clear()
	jump_executed = true  # ジャンプ処理と同様にグローバルフラグを設定
	
	# 全ての実行を停止
	is_executing = false
	is_paused = true  # 実行を一時停止して継続を防ぐ
	
	ArgodeSystem.log("🔙 Return executed: index=%d, skip_increment=%s" % [current_statement_index, skip_index_increment])
	ArgodeSystem.log("🔄 Return cleared execution context")
	ArgodeSystem.log("🔄 Stopping all execution before return")
	
	# 次のフレームで新しい実行を開始
	await Engine.get_main_loop().process_frame
	
	# 実行状態をリセットして新しい実行を開始
	is_paused = false
	jump_executed = false
	
	# 戻り先から実行を開始
	await start_execution()

## 子ステートメント実行復帰の処理
func _handle_return_to_child_execution():
	"""子ステートメント実行中のCall/Returnから復帰"""
	ArgodeSystem.log("🔄 Returning to child statement execution context")
	
	# 子ステートメント実行では何もしない（現在のループを継続）
	# Call/Returnは子ステートメント実行内で完結するため、
	# 単純に現在の子ステートメント実行の続きを実行する

## Call/Returnスタック管理

# 現在の実行コンテキストに基づいて正しい戻り位置を計算
func calculate_return_index() -> int:
	if is_executing_child_statements:
		# 子ステートメント実行中の場合は、Return時に特別処理が必要
		# ここでは戻り先情報をCallCommandに任せる
		ArgodeSystem.log("🔄 Child statement execution context - return handling will be managed by Call/Return system")
		return -1  # 特別値：子ステートメント実行中であることを示す
	else:
		# 通常の実行中の場合、現在のインデックス + 1
		var return_index = current_statement_index + 1
		ArgodeSystem.log("🔄 Calculating return index - current_index: %d, return_index: %d" % [current_statement_index, return_index])
		return return_index

func push_call_context(return_index: int, return_file_path: String):
	"""Callの戻り先をスタックにプッシュ"""
	var context = {
		"return_index": return_index,
		"return_file_path": return_file_path
	}
	call_return_stack.push_back(context)
	ArgodeSystem.log("📞 Call context pushed: return to index %d in %s" % [return_index, return_file_path])

func pop_call_context() -> Dictionary:
	"""Returnで戻り先をスタックからポップ"""
	if call_return_stack.is_empty():
		ArgodeSystem.log("❌ Call/Return stack is empty - no return context available", 2)
		return {}
	
	var context = call_return_stack.pop_back()
	ArgodeSystem.log("🔙 Call context popped: returning to index %d in %s" % [context.return_index, context.return_file_path])
	return context

func has_call_context() -> bool:
	"""Call/Returnスタックが空でないかチェック"""
	return not call_return_stack.is_empty()

func clear_call_stack():
	"""Call/Returnスタックをクリア（シナリオ終了時など）"""
	call_return_stack.clear()
	ArgodeSystem.log("🧹 Call/Return stack cleared")
