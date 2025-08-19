# ArgodeSystem.gd
extends Node

class_name ArgodeSystemCore

## Argodeフレームワーク全体のコアシステム
## オートロード・シングルトンとして機能し、マネージャーやレジストリを統括する。

## CommandLineから受け取った引数を格納する
var command_line_args: Dictionary = {}

# ArgodeSystemから参照するためのマネージャー定義

var DebugManager:ArgodeDebugManager # デバッグマネージャーのインスタンス
var StatementManager:ArgodeStatementManager # ステートメントマネージャーのインスタンス
var LayerManager:ArgodeLayerManager # レイヤーマネージャーのインスタンス
var Controller:ArgodeController # コントローラーのインスタンス

# レジストリのインスタンス
var CommandRegistry
var DefinitionRegistry  
var LabelRegistry

# ローディング画面
var loading_screen: Control
var loading_scene_path: String = "res://addons/argode/builtin/scenes/argode_loading/argode_loading_screen.tscn"

# システム初期化状態
var is_system_ready: bool = false
signal system_ready

func _ready():
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
	
	# コントローラーをシーンツリーに追加（入力処理のため）
	add_child(Controller)
	Controller.name = "ArgodeController"
	
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

	CommandRegistry = CommandRegistryClass.new()
	DefinitionRegistry = DefinitionRegistryClass.new()
	LabelRegistry = LabelRegistryClass.new()
	
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
	
	# StatementManagerを使用して定義コマンドを実行
	var success = await StatementManager.execute_definition_statements(definition_statements)
	if success:
		ArgodeSystem.log("✅ Definition commands execution completed")
	else:
		ArgodeSystem.log("❌ Definition commands execution failed", 2)

## 定義辞書からステートメント形式に変換（廃止予定：DefinitionRegistryに移行）
func _convert_definitions_to_statements() -> Array:
	# この機能はDefinitionRegistry.get_definition_statements()に移行
	return DefinitionRegistry.get_definition_statements()

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

## 各マネージャーとサービスをセットアップする（廃止予定）
func _setup_managers_and_services():
	# マネージャーの生成と登録
	DebugManager = ArgodeDebugManager.new()
	StatementManager = ArgodeStatementManager.new()

## 指定されたパス内のRGDファイルを再帰的に読み込み、辞書として返す
func load_rgd_recursive(path: String) -> Dictionary:
	var result: Dictionary = {}
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				# ディレクトリなら再帰的に呼び出す
				var sub_dir_result = load_rgd_recursive(path.path_join(file_name))
				result.merge(sub_dir_result, true)
			elif file_name.ends_with(".rgd"):
				# RGDファイルなら読み込む
				var file_path = path.path_join(file_name)
				var file_data = _load_rgd_file(file_path)
				result.merge(file_data, true)
			file_name = dir.get_next()
	return result

## RGDファイルを読み込み、辞書としてパースするプライベート関数
func _load_rgd_file(file_path: String) -> Dictionary:
	# ここにRGDファイルのパースロジックを実装する
	# 例: JSONやYAMLのようにパースし、辞書として返す
	return {} # 仮の戻り値

## 汎用的なログ関数
func log(message: String, level: int = 1):
	DebugManager.log(message, level)

func play(_label:String = "start"):
	# 指定されたラベルに基づいてゲームを開始する
	# もしcommand_line_argsにstart_labelキーがあれば、それを優先する
	if command_line_args.has("start_label"):
		_label = command_line_args["start_label"]

	if not LabelRegistry.has_label(_label):
		ArgodeSystem.log("❌ Label not found: " + _label, ArgodeDebugManager.LogLevel.ERROR)
		return

	ArgodeSystem.log("🎬 Play label: " + _label, 1)
	
	# ArgodeStatementManagerを使用してラベルから実行を開始
	var success = await StatementManager.play_from_label(_label)
	if success:
		ArgodeSystem.log("✅ Successfully started playing from label: " + _label, 1)
	else:
		ArgodeSystem.log("❌ Failed to start playing from label: " + _label, 2)

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

## ラベルブロックパースのテスト用関数
func test_label_block_parser(file_path: String, label_name: String):
	ArgodeSystem.log("🧪 Testing label block parser...")
	ArgodeSystem.log("📄 File: %s" % file_path)
	ArgodeSystem.log("🏷️ Label: %s" % label_name)
	
	var parser = ArgodeRGDParser.new()
	parser.set_command_registry(CommandRegistry)
	
	# 指定ラベルブロックのみをパース
	var statements = parser.parse_label_block(file_path, label_name)
	
	ArgodeSystem.log("📊 Parse result: %d statements found" % statements.size())
	
	if statements.size() > 0:
		parser.debug_print_statements(statements)
	else:
		ArgodeSystem.log("⚠️ No statements found in label block '%s'" % label_name, 1)
	
	ArgodeSystem.log("✅ Label block parser test completed")
