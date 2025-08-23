# ArgodeSystem.gd
extends Node

class_name ArgodeSystemCore

## Argodeフレームワーク全体のコアシステム
## オートロード・シングルトンとして機能し、マネージャーやレジストリを統括する。

# GitHub Copilot最適化: ログレベル定数
enum LOG_LEVEL {
	DEBUG = 0,
	WORKFLOW = 1,
	CRITICAL = 2
}

## CommandLineから受け取った引数を格納する
var command_line_args: Dictionary = {}

## 詳細ログモード（文字単位のデバッグログ制御）
var verbose_mode: bool = false

# ArgodeSystemから参照するためのマネージャー定義

var DebugManager:ArgodeDebugManager # デバッグマネージャーのインスタンス
var StatementManager:ArgodeStatementManager # ステートメントマネージャーのインスタンス
var LayerManager:ArgodeLayerManager # レイヤーマネージャーのインスタンス
var VariableManager:ArgodeVariableManager # 変数マネージャーのインスタンス
var UIManager:ArgodeUIManager # UIマネージャーのインスタンス
var Controller:ArgodeController # コントローラーのインスタンス

# レジストリのインスタンス
var CommandRegistry
var DefinitionRegistry  
var LabelRegistry
var MessageAnimationRegistry
var TagRegistry

# ローディング画面
var loading_screen: Control
var loading_scene_path: String = "res://addons/argode/builtin/scenes/argode_loading/argode_loading_screen.tscn"

# 組み込みUI（ランタイム・システム初期化前に指定しなおせばカスタマイズ可能）
var built_in_ui_paths: Dictionary = {
	"choice": "res://addons/argode/builtin/scenes/default_choice_dialog/default_choice_dialog.tscn",
	"confirm": "res://addons/argode/builtin/scenes/default_confirm_dialog/default_confirm_dialog.tscn",
	"notification_screen": "res://addons/argode/builtin/scenes/default_notification_screen/default_notification_screen.tscn"
}

# システム初期化状態
var is_system_ready: bool = false
var is_headless_mode: bool = false  # ヘッドレスモード検出
signal system_ready

func _ready():
	# 詳細ログモードをデフォルトで無効化（パフォーマンス向上）
	verbose_mode = false
	
	# ヘッドレスモードを検出
	is_headless_mode = DisplayServer.get_name() == "headless"
	if is_headless_mode:
		print("🤖 Headless mode detected - auto-play enabled")
	
	# まず生のコマンドライン引数を確認
	var raw_args = OS.get_cmdline_args()
	print("🔍 Raw command line args: " + str(raw_args))
	
	# コマンドライン引数をパース（デバッグビルドでなくても処理する）
	for argument in raw_args:
		print("📝 Processing argument: " + str(argument))
		if argument.begins_with("--"):
			if argument.contains("="):
				var key_value = argument.split("=", false, 1)
				command_line_args[key_value[0].trim_prefix("--")] = key_value[1]
				print("  ✅ Added key-value: %s = %s" % [key_value[0].trim_prefix("--"), key_value[1]])
			else:
				# Options without an argument will be present in the dictionary,
				# with the value set to an empty string.
				command_line_args[argument.trim_prefix("--")] = ""
				print("  ✅ Added flag: %s" % argument.trim_prefix("--"))
	
	# デバッグ: コマンドライン引数を表示
	print("🔍 Parsed command line args: " + str(command_line_args))
	
	# verboseフラグでverbose_modeを有効化
	if command_line_args.has("verbose"):
		verbose_mode = true
		print("🔧 Verbose mode enabled via command line")
	
	# ヘルプが指定されている場合はヘルプを表示
	if command_line_args.has("help") or command_line_args.has("h"):
		_show_help()
		get_tree().quit()
		return
	
	# 基本マネージャーの初期化
	_setup_basic_managers()
	
	# パーサーテストの場合は簡易初期化のみ
	if command_line_args.has("test_parser"):
		await _run_parser_test_with_minimal_setup()
		return
	
	# 通常の初期化処理
	await _initialize_system_with_loading()

	ArgodeSystem.log("ArgodeSystem is ready.")
	# ArgodeSystem.log("All Built-in Command: %s" % str(CommandRegistry.command_dictionary))
	# ArgodeSystem.log("Define Commands: %s" % str(CommandRegistry.get_define_command_names()))
	# ArgodeSystem.log("All Labels: %s" % str(LabelRegistry.label_dictionary))
	# ArgodeSystem.log("All Definitions: %s" % str(DefinitionRegistry.definition_dictionary))
	
	# 自動実行の処理
	await _handle_auto_execution()

## パーサーテスト用の最小限のセットアップ
func _run_parser_test_with_minimal_setup():
	ArgodeSystem.log("🧪 Running parser test in minimal setup mode")
	
	# レジストリをセットアップ（パーサーテストに必要）
	_setup_registries()
	
	# コマンドレジストリのみ初期化
	await CommandRegistry.start_registry()
	
	# パーサーテストを実行
	var test_file = command_line_args.get("test_parser", "")
	if test_file.is_empty():
		test_file = "res://examples/scenarios/debug_scenario/test_all_command.rgd"
	await _run_parser_test(test_file)

## ヘルプを表示
func _show_help():
	print("Argode Framework Command Line Options:")
	print("  --help, --h                    Show this help message")
	print("  --test_parser[=file]           Test RGD parser with specified file")
	print("                                 Default: res://examples/scenarios/debug_scenario/test_all_command.rgd")
	print("  --test_label_parser=file,label Test RGD parser for specific label block")
	print("                                 Example: --test_label_parser=test.rgd,start")
	print("  --test_only                    Exit after running tests")
	print("  --verbose, --debug             Show detailed debug output")
	print("  --auto_play[=label]            Automatically play specified label")
	print("                                 Default: start")
	print("  --start_label=label            Override default start label")
	print("")
	print("Examples:")
	print("  godot --headless -- --test_parser --verbose --test_only")
	print("  godot --headless -- --test_parser=res://test.rgd --debug")
	print("  godot --headless -- --test_label_parser=res://test.rgd,main --test_only")
	print("  godot -- --auto_play=main_menu")
	print("  godot -- --start_label=tutorial")

## パーサーテストを実行
func _run_parser_test(file_path: String):
	ArgodeSystem.log("🧪 Running parser test with file: " + file_path)
	
	var parser = ArgodeRGDParser.new()
	# コマンドレジストリが利用可能な場合は設定
	if CommandRegistry:
		parser.set_command_registry(CommandRegistry)
	
	var parsed_statements = parser.parse_file(file_path)
	
	if parsed_statements.is_empty():
		ArgodeSystem.log("❌ No statements parsed from file", 2)
	else:
		ArgodeSystem.log("✅ Successfully parsed %d top-level statements" % parsed_statements.size())
		
		# デバッグ出力（コマンドライン引数で制御）
		if command_line_args.has("verbose") or command_line_args.has("debug"):
			print("\n=== PARSE RESULTS ===")
			parser.debug_print_statements(parsed_statements)
	
	# テスト専用の場合は終了
	if command_line_args.has("test_only"):
		ArgodeSystem.log("🏁 Test completed. Exiting...")
		get_tree().quit()

## 自動実行を処理
func _handle_auto_execution():
	# test_label_parserが指定されている場合はラベルパーサーテストを実行
	if command_line_args.has("test_label_parser"):
		var test_args = command_line_args.get("test_label_parser", "").split(",")
		if test_args.size() >= 2:
			var file_path = test_args[0].strip_edges()
			var label_name = test_args[1].strip_edges()
			ArgodeSystem.log("🧪 Testing label parser: file=%s, label=%s" % [file_path, label_name])
			await _test_label_parser(file_path, label_name)
		else:
			ArgodeSystem.log("❌ test_label_parser requires file_path,label_name format", 2)
		
		if command_line_args.has("test_only"):
			get_tree().quit()
		return
	
	# auto_playが指定されている場合は自動でゲームを開始
	if command_line_args.has("auto_play"):
		var label = command_line_args.get("auto_play", "start")
		ArgodeSystem.log("🎬 Auto-playing label: " + label)
		await play(label)

## 基本マネージャーをセットアップする（レジストリ処理前に必要なもの）
func _setup_basic_managers():
	DebugManager = ArgodeDebugManager.new()
	StatementManager = ArgodeStatementManager.new()
	Controller = ArgodeController.new()
	LayerManager = ArgodeLayerManager.new()
	VariableManager = ArgodeVariableManager.new()
	UIManager = ArgodeUIManager.new()

	# コントローラーをシーンツリーに追加（入力処理のため）
	add_child(Controller)
	Controller.name = "ArgodeController"
	
	# StatementManagerのサービス初期化
	StatementManager.initialize_services()
	
	ArgodeSystem.log("🎮 ArgodeController initialized and added to scene tree")

## ラベルパーサーをテストする
func _test_label_parser(file_path: String, label_name: String):
	ArgodeSystem.log("🧪 Starting label parser test...")
	ArgodeSystem.log("📁 File: %s" % file_path)
	ArgodeSystem.log("🏷️ Label: %s" % label_name)
	
	# RGDパーサーを作成
	var parser = ArgodeRGDParser.new()
	parser.set_command_registry(CommandRegistry)
	
	# ファイル全体をパース
	ArgodeSystem.log("📄 Parsing entire file...")
	var all_statements = parser.parse_file(file_path)
	ArgodeSystem.log("✅ Found %d statements in entire file" % all_statements.size())
	
	# 指定ラベルのブロックのみをパース
	ArgodeSystem.log("🎯 Parsing label block: %s" % label_name)
	var label_statements = parser.parse_label_block(file_path, label_name)
	ArgodeSystem.log("✅ Found %d statements in label block" % label_statements.size())
	
	# デバッグ出力
	if command_line_args.has("verbose"):
		ArgodeSystem.log("📊 Label block statements:")
		parser.debug_print_statements(label_statements)
	
	ArgodeSystem.log("🏁 Label parser test completed")

## ローディング画面を表示してシステム初期化を行う
func _initialize_system_with_loading():
	# プロジェクト設定でローディング画面の表示が有効かチェック
	var show_loading = ProjectSettings.get_setting("argode/general/show_loading_screen", true)
	
	if show_loading:
		# ローディング画面を表示
		await _show_loading_screen()
	
	# レジストリを初期化
	_setup_registries()
	
	# 各レジストリを順次実行
	await _run_registries_sequential()
	
	# システム準備完了
	is_system_ready = true
	emit_signal("system_ready")

## ローディング画面を表示
func _show_loading_screen():
	var loading_scene = preload("res://addons/argode/builtin/scenes/argode_loading/argode_loading_screen.tscn")
	loading_screen = loading_scene.instantiate()
	
	# 親ノードがビジー状態でないことを確認してから追加
	get_tree().root.add_child.call_deferred(loading_screen)
	
	# LoadingScreenが確実にシーンツリーに追加されるまで待機
	await loading_screen.ready
	# await get_tree().process_frame
	

## レジストリインスタンスを作成
func _setup_registries():
	# レジストリクラスをプリロードして作成
	var CommandRegistryClass = preload("res://addons/argode/services/registries/ArgodeCommandRegistry.gd")
	var DefinitionRegistryClass = preload("res://addons/argode/services/registries/ArgodeDefinitionRegistry.gd")
	var LabelRegistryClass = preload("res://addons/argode/services/registries/ArgodeLabelRegistry.gd")
	var MessageAnimationRegistryClass = preload("res://addons/argode/services/registries/ArgodeMessageAnimationRegistry.gd")
	var TagRegistryClass = preload("res://addons/argode/services/tags/ArgodeTagRegistry.gd")

	CommandRegistry = CommandRegistryClass.new()
	DefinitionRegistry = DefinitionRegistryClass.new()
	LabelRegistry = LabelRegistryClass.new()
	MessageAnimationRegistry = MessageAnimationRegistryClass.new()
	TagRegistry = TagRegistryClass.new()
	
	# シグナル接続
	_connect_registry_signals()

## レジストリのシグナルを接続
func _connect_registry_signals():
	# CommandRegistry
	CommandRegistry.progress_updated.connect(_on_registry_progress_updated)
	CommandRegistry.registry_completed.connect(_on_registry_completed)
	
	# DefinitionRegistry
	DefinitionRegistry.progress_updated.connect(_on_registry_progress_updated)
	DefinitionRegistry.registry_completed.connect(_on_registry_completed)
	
	# LabelRegistry
	LabelRegistry.progress_updated.connect(_on_registry_progress_updated)
	LabelRegistry.registry_completed.connect(_on_registry_completed)

## レジストリを効率的に実行（依存関係に配慮した協調的処理）
func _run_registries_sequential():
	ArgodeSystem.log("🚀 Starting registry initialization...")
	
	# 1. コマンドレジストリ（最優先、他が依存するため先に完了させる）
	if loading_screen:
		loading_screen.on_registry_started("ArgodeCommandRegistry")
	await CommandRegistry.start_registry()
	
	# 1.2. TagRegistry（CommandRegistryに依存するため、直後に実行）
	if loading_screen:
		loading_screen.on_registry_started("ArgodeTagRegistry")
	TagRegistry.initialize_from_command_registry(CommandRegistry)
	
	# 1.5. メッセージアニメーションレジストリ（コマンドと併行実行可能）
	if loading_screen:
		loading_screen.on_registry_started("ArgodeMessageAnimationRegistry")
	await MessageAnimationRegistry.start_registry()
	
	# 2. 定義レジストリとラベルレジストリを順次実行（依存関係なし）
	# 将来的に並行処理が可能な場合は、ここで並行実行を実装
	if loading_screen:
		loading_screen.on_registry_started("ArgodeDefinitionRegistry")
	await DefinitionRegistry.start_registry()
	
	# 3. 定義コマンドを実行
	await _execute_definition_commands()
	
	# 4. ラベルレジストリを実行
	if loading_screen:
		loading_screen.on_registry_started("ArgodeLabelRegistry")
	await LabelRegistry.start_registry()
	
	ArgodeSystem.log("✅ All registries completed!")

## 定義コマンドを実行
func _execute_definition_commands():
	ArgodeSystem.log("🔧 Starting definition commands execution...")
	
	if not DefinitionRegistry.has_definitions():
		ArgodeSystem.log("ℹ️ No definitions to execute", 1)
		return
	
	# DefinitionRegistryから定義ステートメントを取得
	var definition_statements = DefinitionRegistry.get_definition_statements()
	
	if definition_statements.is_empty():
		ArgodeSystem.log("⚠️ No definition statements created", 1)
		return
	
	# DefinitionServiceを使用して定義コマンドを実行
	var definition_service = ArgodeDefinitionService.new()
	var success = await definition_service.execute_definition_statements(definition_statements, StatementManager)
	if success:
		ArgodeSystem.log("✅ Definition commands execution completed")
	else:
		ArgodeSystem.log("❌ Definition commands execution failed", 2)

## レジストリ進捗更新時のコールバック
func _on_registry_progress_updated(task_name: String, progress: float, total: int, current: int):
	if loading_screen:
		loading_screen.on_registry_progress_updated(task_name, progress, total, current)
	else:
		# ローディング画面が無効の場合はログで進捗を報告
		var show_loading = ProjectSettings.get_setting("argode/general/show_loading_screen", true)
		if not show_loading:
			ArgodeSystem.log("📊 %s: %d/%d (%.1f%%)" % [task_name, current, total, progress * 100])

## レジストリ完了時のコールバック
func _on_registry_completed(registry_name: String):
	if loading_screen:
		loading_screen.on_registry_completed(registry_name)
	# 重複ログを削除（レジストリ自体が既にログを出力しているため）

## 汎用的なログ関数（従来互換性維持）
func log(message: String, level: int = 1):
	DebugManager.log(message, level)

# =============================================================================
# GitHub Copilot効率化ログAPI
# =============================================================================

## 🚨 CRITICAL: エラー・重大問題（GitHub Copilot最重要）
func log_critical(message: String) -> void:
	DebugManager.log_critical(message)

## 🎬 WORKFLOW: ワークフロー重要ポイント（実行フロー把握用）
func log_workflow(message: String) -> void:
	DebugManager.log_workflow(message)

## 🔍 DEBUG: 詳細情報（開発時のみ）
func log_debug_detail(message: String) -> void:
	DebugManager.log_debug_detail(message)

## GitHub Copilot用ログレベル設定
func set_copilot_log_level(level: int) -> void:
	DebugManager.set_copilot_log_level(level)

# サービスレジストリ（最小限実装）
var _services: Dictionary = {}

## Service Layer Pattern: サービス取得（将来の拡張用）
func get_service(service_name: String) -> RefCounted:
	"""
	Get a service instance by name.
	Returns null for non-existent services in current implementation.
	This method is prepared for future Service Layer Pattern expansion.
	"""
	if _services.has(service_name):
		return _services[service_name]
	
	log_debug_detail("Service requested: %s (not found)" % service_name)
	return null

## Service Layer Pattern: サービス登録
func register_service(service_name: String, service_instance: RefCounted) -> void:
	"""
	Register a service instance with a name.
	This enables get_service() to retrieve the service later.
	"""
	_services[service_name] = service_instance
	log_debug_detail("Service registered: %s" % service_name)

## Service Layer Pattern: サービス削除
func unregister_service(service_name: String) -> bool:
	"""
	Unregister a service by name.
	Returns true if the service was found and removed, false otherwise.
	"""
	if _services.has(service_name):
		_services.erase(service_name)
		log_debug_detail("Service unregistered: %s" % service_name)
		return true
	else:
		log_debug_detail("Service unregister failed: %s (not found)" % service_name)
		return false

## Service Layer Pattern: 全サービス取得（デバッグ用）
func get_all_services() -> Dictionary:
	"""
	Get all registered services.
	Returns a copy of the services dictionary for debugging purposes.
	"""
	return _services.duplicate()

func play(_label:String = "start"):
	# 指定されたラベルに基づいてゲームを開始する
	# もしcommand_line_argsにstart_labelキーがあれば、それを優先する
	if command_line_args.has("start_label"):
		_label = command_line_args["start_label"]

	if not LabelRegistry.has_label(_label):
		ArgodeSystem.log("❌ Label not found: " + _label, ArgodeDebugManager.LogLevel.ERROR)
		return

	ArgodeSystem.log("🎬 Play label: " + _label, 1)
	
	# ラベルのステートメントを取得
	var label_statements = StatementManager.get_label_statements(_label)
	if label_statements.is_empty():
		ArgodeSystem.log("❌ No statements found in label: " + _label, 2)
		return
	
	# StatementManagerでブロック実行（ラベル名を渡して連続実行を有効化）
	StatementManager.execute_block(label_statements, _label)
	ArgodeSystem.log("✅ Successfully started playing from label: " + _label, 1)

func add_message_window_scene(_path:String):
	ArgodeSystem.log("🪄Adding message window scene: " + _path, 1)

## システムが準備完了かチェック
func is_ready() -> bool:
	return is_system_ready

## ラベル辞書を取得（システム準備完了後）
func get_label_dictionary() -> Dictionary:
	if not is_system_ready or not LabelRegistry:
		ArgodeSystem.log("❌ System not ready or LabelRegistry not available", 2)
		return {}
	return LabelRegistry.get_label_dictionary()

## ラベル名配列を取得（システム準備完了後）
func get_label_names() -> PackedStringArray:
	if not is_system_ready or not LabelRegistry:
		ArgodeSystem.log("❌ System not ready or LabelRegistry not available", 2)
		return PackedStringArray()
	return LabelRegistry.get_label_names()

## コマンド辞書を取得（システム準備完了後）
func get_command_dictionary() -> Dictionary:
	if not is_system_ready or not CommandRegistry:
		ArgodeSystem.log("❌ System not ready or CommandRegistry not available", 2)
		return {}
	return CommandRegistry.command_dictionary

## システム初期化完了まで待機
func wait_for_system_ready():
	while not is_system_ready:
		await get_tree().process_frame

## ヘッドレスモードかどうかを判定
static func is_headless() -> bool:
	return DisplayServer.get_name() == "headless"

## オートプレイモードかどうかを判定（ヘッドレスモード or テストフラグ）
static func is_auto_play_mode() -> bool:
	return is_headless() or OS.has_feature("debug") and OS.get_cmdline_args().has("--auto-play")

## 詳細ログモードを設定
func set_verbose_mode(enabled: bool):
	verbose_mode = enabled
	ArgodeSystem.log("🔧 Verbose mode: %s" % ("ON" if enabled else "OFF"))

## 詳細ログモードかどうかを判定
func is_verbose_mode() -> bool:
	return verbose_mode

