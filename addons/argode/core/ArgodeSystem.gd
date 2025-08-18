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

# レジストリのインスタンス
var CommandRegistry
var DefinitionRegistry  
var LabelRegistry

# ローディング画面
var loading_screen
var loading_scene_path: String = "res://addons/argode/builtin/scenes/argode_loading/argode_loading_screen.tscn"

# システム初期化状態
var is_system_ready: bool = false
var initialization_thread: Thread


func _ready():
	if OS.is_debug_build():
		for argument in OS.get_cmdline_args():
			if argument.contains("="):
				var key_value = argument.split("=")
				command_line_args[key_value[0].trim_prefix("--")] = key_value[1]
			else:
				# Options without an argument will be present in the dictionary,
				# with the value set to an empty string.
				command_line_args[argument.trim_prefix("--")] = ""
	
	# 基本マネージャーの初期化
	_setup_basic_managers()
	
	# ローディング画面表示とレジストリ処理開始
	await _initialize_system_with_loading()

	ArgodeSystem.log("ArgodeSystem is ready.")

## 基本マネージャーをセットアップする（レジストリ処理前に必要なもの）
func _setup_basic_managers():
	DebugManager = ArgodeDebugManager.new()
	StatementManager = ArgodeStatementManager.new()

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

## ローディング画面を表示
func _show_loading_screen():
	var loading_scene = preload("res://addons/argode/builtin/scenes/argode_loading/argode_loading_screen.tscn")
	loading_screen = loading_scene.instantiate()
	
	# 親ノードがビジー状態でないことを確認してから追加
	get_tree().root.add_child.call_deferred(loading_screen)
	
	# ローディング画面の追加と_ready()が完了するまで待機
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

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

## レジストリを順次実行（依存関係に配慮）
func _run_registries_sequential():
	ArgodeSystem.log("🚀 Starting registry initialization...")
	
	# 1. コマンドレジストリ（最優先）
	if loading_screen:
		loading_screen.on_registry_started("ArgodeCommandRegistry")
	await CommandRegistry.start_registry()
	
	# 2. 定義レジストリ（コマンドが必要）
	if loading_screen:
		loading_screen.on_registry_started("ArgodeDefinitionRegistry")
	await DefinitionRegistry.start_registry()
	
	# 3. ラベルレジストリ
	if loading_screen:
		loading_screen.on_registry_started("ArgodeLabelRegistry")
	await LabelRegistry.start_registry()
	
	ArgodeSystem.log("✅ All registries completed!")

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
	ArgodeSystem.log("✅ %s completed" % registry_name)

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
	ArgodeSystem.log("🎬Playing label: " + _label, 1)

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
