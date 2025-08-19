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
# 実行状態フラグ
var is_executing: bool = false
var is_paused: bool = false
var is_waiting_for_input: bool = false
var is_skipped: bool = false  # スキップされたかのフラグ

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
	# 入力待ち状態での処理
	if is_waiting_for_input:
		match action_name:
			"argode_advance":
				# タイプライター効果が実行中の場合はスキップ
				if message_renderer and message_renderer.typewriter_service and message_renderer.typewriter_service.is_currently_typing():
					message_renderer.complete_typewriter()
					is_skipped = true  # スキップフラグを設定
					ArgodeSystem.log("⏭️ Typewriter effect skipped - waiting for completion")
					# ここではis_waiting_for_inputをfalseにしない
					# タイプライター完了後に_on_typing_finishedで処理される
				else:
					# タイプライター完了済み、または動作していない場合は次へ進む
					is_waiting_for_input = false
					is_skipped = false
					ArgodeSystem.log("⏭️ User input received, continuing execution")
			
			"argode_skip":
				# スキップアクション（Ctrl、右クリック）でも同様の処理
				if message_renderer and message_renderer.typewriter_service and message_renderer.typewriter_service.is_currently_typing():
					message_renderer.complete_typewriter()
					is_skipped = true  # スキップフラグを設定
					ArgodeSystem.log("⏭️ Typewriter effect force skipped with skip key")
				else:
					# 即座に次へ進む
					is_waiting_for_input = false
					is_skipped = false
					ArgodeSystem.log("⏭️ Skip input received, continuing execution")

## タイプライター完了時のコールバック
func _on_typing_finished():
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
	# コントローラーがない場合は再取得を試行
	if not controller:
		_setup_input_controller()
	
	if not controller:
		# コントローラーがない場合は即座に続行
		ArgodeSystem.log("⚠️ No controller available, skipping input wait", 1)
		return
	
	ArgodeSystem.log("⏸️ Waiting for user input...")
	is_waiting_for_input = true
	
	# 入力があるまで待機
	while is_waiting_for_input and is_executing:
		await Engine.get_main_loop().process_frame

## タイプライター完了時のコールバック
func _on_typewriter_completed():
	# タイプライター完了後、入力待ち状態の場合は次へ進む準備完了
	if is_waiting_for_input:
		ArgodeSystem.log("✅ Typewriter completed - ready for next input")
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
	
	# デバッグ出力
	ArgodeSystem.log("✅ Loaded %d statements from %s" % [current_statements.size(), file_path])
	if ArgodeSystem.DebugManager.is_debug_mode():
		rgd_parser.debug_print_statements(current_statements)
	
	# 実行インデックスをリセット
	current_statement_index = 0
	
	return true

## 定義コマンドリストを実行（起動時の定義処理用）
func execute_definition_statements(statements: Array) -> bool:
	if statements.is_empty():
		ArgodeSystem.log("⚠️ No definition statements to execute", 1)
		return true
	
	ArgodeSystem.log("🔧 Executing %d definition statements" % statements.size())
	
	# 定義コマンドのみを順次実行
	for statement in statements:
		if statement.get("type") == "command":
			var command_name = statement.get("name", "")
			
			# 定義コマンドかチェック
			if ArgodeSystem.CommandRegistry.is_define_command(command_name):
				await _execute_single_statement(statement)
			else:
				ArgodeSystem.log("⚠️ Skipping non-definition command: %s" % command_name, 1)
	
	ArgodeSystem.log("✅ Definition statements execution completed")
	return true

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
	
	is_executing = true
	is_paused = false
	
	ArgodeSystem.log("▶️ Starting statement execution from index %d" % current_statement_index)
	
	# ステートメントを順次実行
	while current_statement_index < current_statements.size() and is_executing and not is_paused:
		var statement = current_statements[current_statement_index]
		await _execute_single_statement(statement)
		current_statement_index += 1
	
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
	
	ArgodeSystem.log("🎯 Executing statement: %s (line %d)" % [statement_name, statement_line])
	
	match statement_type:
		"command":
			await _execute_command(statement_name, statement_args)
			
			# 子ステートメントがある場合は実行
			if statement.has("statements") and statement.statements.size() > 0:
				await _execute_child_statements(statement.statements)
		"say":
			# Sayコマンドは特別にStatementManagerで処理
			await _handle_say_command(statement_args)
		_:
			ArgodeSystem.log("⚠️ Unknown statement type: %s" % statement_type, 1)

## 子ステートメントを実行
func _execute_child_statements(child_statements: Array):
	for child_statement in child_statements:
		await _execute_single_statement(child_statement)

## Sayコマンドの特別処理
func _handle_say_command(args: Array):
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
	
	# InlineCommandManagerでテキストを前処理
	var processed_data = inline_command_manager.process_text(message_text)
	var display_text = processed_data.display_text
	var position_commands = processed_data.position_commands
	
	# MessageRendererに表示用テキストと位置ベースコマンドを渡して表示
	if message_renderer:
		message_renderer.render_message_with_position_commands(
			character_name, 
			display_text, 
			position_commands,
			inline_command_manager
		)
	
	# ユーザー入力を待つ
	await _wait_for_user_input()

## コマンドを実行
func _execute_command(command_name: String, args: Array):
	if not ArgodeSystem.CommandRegistry.has_command(command_name):
		ArgodeSystem.log("❌ Command not found: %s" % command_name, 2)
		return
	
	# コマンドデータを取得し、インスタンスを抽出
	var command_data = ArgodeSystem.CommandRegistry.get_command(command_name)
	if command_data.is_empty():
		ArgodeSystem.log("❌ Command data not found: %s" % command_name, 2)
		return
	
	var command_instance = command_data.get("instance")
	if command_instance and command_instance.has_method("execute"):
		# 引数をArrayからDictionaryに変換
		var args_dict = _convert_args_to_dict(args)
		await command_instance.execute(args_dict)
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
	for i in range(current_statements.size()):
		var statement = current_statements[i]
		var statement_line = statement.get("line", 0)
		if statement_line >= target_line:
			return i
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
	current_statement_index = 0
	ArgodeSystem.log("⏹️ Statement execution stopped")

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
	
	# 初期状態では非表示
	message_window.visible = false
	
	ArgodeSystem.log("✅ StatementManager: Message window initialized")

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

