# ArgodeCommandRegistry.gd
extends RefCounted

class_name ArgodeCommandRegistry

## Argodeコマンドを登録するレジストリ
## builtin/commands/ と custom_commands/ から .gd ファイルを検索し、
## コマンドクラスとしてArgodeSystemのコマンド辞書に登録する

signal progress_updated(task_name: String, progress: float, total: int, current: int)
signal registry_completed(registry_name: String)

var search_directories: Array[String] = []

var total_files: int = 0
var processed_files: int = 0
var command_dictionary: Dictionary = {}

func _init():
	# プロジェクト設定からディレクトリを取得
	_load_search_directories()

## プロジェクト設定から検索ディレクトリを読み込み
func _load_search_directories():
	search_directories = [
		"res://addons/argode/builtin/commands/"
	]
	
	# プロジェクト設定からカスタムコマンドディレクトリを取得
	var custom_dir = ProjectSettings.get_setting("argode/general/custom_command_directory", "res://custom_commands/")
	if custom_dir != "":
		search_directories.append(custom_dir)

## レジストリ処理を開始
func start_registry():
	total_files = 0
	processed_files = 0
	command_dictionary.clear()
	
	# ファイル総数をカウント
	_count_gd_files()
	
	ArgodeSystem.log("🔄 ArgodeCommandRegistry started. Total files: %d" % total_files)
	
	# コマンドファイルを処理
	await _process_command_files()
	
	# コマンド辞書をArgodeSystemに登録
	_register_commands_to_system()
	
	ArgodeSystem.log("✅ ArgodeCommandRegistry completed. Registered %d commands." % command_dictionary.size())
	registry_completed.emit("ArgodeCommandRegistry")

## 設定されたディレクトリからGDScriptファイルの総数をカウント
func _count_gd_files():
	for directory_path in search_directories:
		if DirAccess.dir_exists_absolute(directory_path):
			total_files += _count_gd_files_recursive(directory_path)

## 再帰的にGDScriptファイルをカウント
func _count_gd_files_recursive(path: String) -> int:
	var count = 0
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir() and not file_name.begins_with("."):
				count += _count_gd_files_recursive(path.path_join(file_name))
			elif file_name.ends_with(".gd"):
				count += 1
			file_name = dir.get_next()
	return count

## コマンドファイルを非同期で処理
func _process_command_files():
	for directory_path in search_directories:
		if DirAccess.dir_exists_absolute(directory_path):
			await _process_directory_recursive(directory_path)

## ディレクトリを再帰的に処理
func _process_directory_recursive(path: String):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir() and not file_name.begins_with("."):
				await _process_directory_recursive(path.path_join(file_name))
			elif file_name.ends_with(".gd"):  # .rgd を .gd に修正
				await _process_command_file(path.path_join(file_name))
			file_name = dir.get_next()

## 個別のコマンドファイルを処理
func _process_command_file(file_path: String):
	processed_files += 1
	var progress = float(processed_files) / float(total_files)
	progress_updated.emit("コマンド登録", progress, total_files, processed_files)
	
	# GDScriptファイルからコマンドクラス情報を抽出
	var command_data = _parse_command_class(file_path)
	if command_data.has("command_name") and command_data.has("class_name"):
		# command_dictionaryに詳細情報を登録
		command_dictionary[command_data.command_name] = {
			"class_name": command_data.class_name,
			"keywords": command_data.command_keywords,
			"file_path": command_data.file_path,
			"script_resource": command_data.script_resource,
			"instance": command_data.command_instance,  # インスタンスをキャッシュ
			"is_define_command": command_data.is_define_command  # 定義コマンドフラグ
		}
		var keywords_str = ", ".join(command_data.command_keywords)
		var define_flag = " [DEFINE]" if command_data.is_define_command else ""
		ArgodeSystem.log("📝 Command registered: %s -> %s [%s]%s" % [command_data.command_name, command_data.class_name, keywords_str, define_flag])

## GDScriptファイルからコマンドクラス情報を抽出
func _parse_command_class(file_path: String) -> Dictionary:
	# ビルド後対応: ClassDBから既にロードされたクラス情報を取得
	var script = load(file_path)
	if not script:
		return {}
	
	# スクリプトから直接クラス名を取得
	var script_class = script.get_global_name()
	if script_class.is_empty():
		# global_nameがない場合、ファイル名から推定
		script_class = file_path.get_file().get_basename()
	
	# コマンドクラスからキーワード配列とインスタンスを取得
	var command_data = _extract_command_keywords(script)
	
	# コマンド名を決定：command_execute_nameが設定されていればそれを使用、なければクラス名から推定
	var command_name: String
	if command_data.has("command_execute_name") and not command_data.command_execute_name.is_empty():
		command_name = command_data.command_execute_name
	else:
		command_name = _derive_command_name(script_class)
	
	return {
		"class_name": script_class,
		"command_name": command_name,
		"command_keywords": command_data.keywords,
		"file_path": file_path,
		"script_resource": script,
		"command_instance": command_data.instance,  # インスタンスを保持
		"is_define_command": command_data.is_define_command  # 定義コマンドフラグを保持
	}

## クラス名からコマンド名を推定（例: "SayCommand" -> "say"）
func _derive_command_name(extracted_class_name: String) -> String:
	# "Command"サフィックスを削除
	if extracted_class_name.ends_with("Command"):
		var base_name = extracted_class_name.substr(0, extracted_class_name.length() - 7)  # "Command" = 7文字
		return base_name.to_lower()
	else:
		return extracted_class_name.to_lower()

## コマンドクラスからキーワード配列を抽出し、インスタンスも保持
func _extract_command_keywords(script: Script) -> Dictionary:
	# コマンドクラスのインスタンスを作成
	var command_instance:ArgodeCommandBase = script.new()
	
	# _ready()メソッドを手動で呼び出してプロパティを初期化
	if command_instance.has_method("_ready"):
		command_instance._ready()
	
	var keywords: Array[String] = []
	var is_define_command: bool = false
	
	# コマンドクラスにget_command_keywords()メソッドがあるかチェック
	if command_instance.has_method("get_command_keywords"):
		var result = command_instance.get_command_keywords()
		if result is Array:
			keywords = result
	
	# is_define_commandフラグを取得（プロパティが存在するかget()でチェック）
	var define_flag = command_instance.get("is_define_command")
	if define_flag != null:
		is_define_command = define_flag
	
	# command_execute_nameを取得（設定されている場合）
	var execute_name = command_instance.get("command_execute_name")
	
	return {
		"keywords": keywords,
		"instance": command_instance,
		"is_define_command": is_define_command,
		"command_execute_name": execute_name
	}

## コマンドをArgodeSystemに登録
func _register_commands_to_system():
	# コマンド辞書はRegistryが管理し、必要に応じて他のコンポーネントから参照される
	ArgodeSystem.log("🔗 Command registry prepared with %d commands" % command_dictionary.size())
	
	# 将来的にStatementManagerと連携する場合は、ここで通知を送る
	# 例: ArgodeSystem.StatementManager.notify_commands_ready()

## 特定のコマンドを取得
func get_command(command_name: String) -> Dictionary:
	if command_dictionary.has(command_name):
		return command_dictionary[command_name]
	return {}

## コマンドが存在するかチェック
func has_command(command_name: String) -> bool:
	return command_dictionary.has(command_name)

## 全コマンド名のリストを取得
func get_command_names() -> PackedStringArray:
	var names: PackedStringArray = []
	for command_name in command_dictionary.keys():
		names.append(command_name)
	return names

## キーワードでコマンドを検索
func find_command_by_keyword(keyword: String) -> Dictionary:
	for command_name in command_dictionary:
		var command_data = command_dictionary[command_name]
		if command_data.has("command_keywords"):
			var keywords: Array = command_data.command_keywords
			if keyword in keywords:
				return command_data
	return {}

## 全コマンドのキーワード一覧を取得
func get_all_keywords() -> Array[String]:
	var all_keywords: Array[String] = []
	for command_name in command_dictionary:
		var command_data = command_dictionary[command_name]
		if command_data.has("keywords"):
			var keywords: Array = command_data.keywords
			for keyword in keywords:
				if keyword not in all_keywords:
					all_keywords.append(keyword)
	return all_keywords

## 定義コマンドのみを取得
func get_define_commands() -> Dictionary:
	var define_commands: Dictionary = {}
	for command_name in command_dictionary:
		var command_data = command_dictionary[command_name]
		if command_data.has("is_define_command") and command_data.is_define_command:
			define_commands[command_name] = command_data
	return define_commands

## 定義コマンド名のリストを取得
func get_define_command_names() -> PackedStringArray:
	var names: PackedStringArray = []
	for command_name in command_dictionary:
		var command_data = command_dictionary[command_name]
		if command_data.has("is_define_command") and command_data.is_define_command:
			names.append(command_name)
	return names

## 指定されたコマンドが定義コマンドかチェック
func is_define_command(command_name: String) -> bool:
	if not has_command(command_name):
		return false
	
	var command_data = command_dictionary.get(command_name, {})
	return command_data.has("is_define_command") and command_data.is_define_command
