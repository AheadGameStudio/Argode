# ArgodeCommandRegistry.gd
extends RefCounted

class_name ArgodeCommandRegistry

## Argodeコマンドを登録するレジストリ
## builtin/commands/ と custom_commands/ から .rgd ファイルを検索し、
## コマンドとしてArgodeStatementManagerに登録する

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
	_count_rgd_files()
	
	ArgodeSystem.log("🔄 ArgodeCommandRegistry started. Total files: %d" % total_files)
	
	# コマンドファイルを処理
	await _process_command_files()
	
	# コマンド辞書をArgodeSystemに登録
	_register_commands_to_system()
	
	ArgodeSystem.log("✅ ArgodeCommandRegistry completed. Registered %d commands." % command_dictionary.size())
	registry_completed.emit("ArgodeCommandRegistry")

## 設定されたディレクトリからRGDファイルの総数をカウント
func _count_rgd_files():
	for directory_path in search_directories:
		if DirAccess.dir_exists_absolute(directory_path):
			total_files += _count_rgd_files_recursive(directory_path)

## 再帰的にRGDファイルをカウント
func _count_rgd_files_recursive(path: String) -> int:
	var count = 0
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir() and not file_name.begins_with("."):
				count += _count_rgd_files_recursive(path.path_join(file_name))
			elif file_name.ends_with(".rgd"):
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
			elif file_name.ends_with(".rgd"):
				await _process_command_file(path.path_join(file_name))
			file_name = dir.get_next()

## 個別のコマンドファイルを処理
func _process_command_file(file_path: String):
	processed_files += 1
	var progress = float(processed_files) / float(total_files)
	progress_updated.emit("コマンド登録", progress, total_files, processed_files)
	
	# RGDファイルからコマンド情報を抽出
	var command_data = _parse_command_file(file_path)
	if command_data.has("command_name"):
		command_dictionary[command_data.command_name] = command_data
		ArgodeSystem.log("📝 Command registered: %s" % command_data.command_name)
	
	# 処理の重さをシミュレート（実際の処理に置き換え）
	await ArgodeSystem.get_tree().process_frame

## RGDファイルからコマンド情報をパース（仮実装）
func _parse_command_file(file_path: String) -> Dictionary:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		
		# ファイル名からコマンド名を推定（仮実装）
		var command_name = file_path.get_file().get_basename()
		return {
			"command_name": command_name,
			"file_path": file_path,
			"content": content
		}
	return {}

## コマンドをArgodeSystemに登録
func _register_commands_to_system():
	# TODO: ArgodeStatementManagerにコマンド辞書を渡す
	pass
