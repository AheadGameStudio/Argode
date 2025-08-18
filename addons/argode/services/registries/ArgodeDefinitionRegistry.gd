# ArgodeDefinitionRegistry.gd
extends RefCounted

class_name ArgodeDefinitionRegistry

## Argode定義コマンドを処理するレジストリ
## builtin/definitions/ と definitions/ から .rgd ファイルを検索し、
## 定義コマンドを抽出して実際にArgodeSystemに定義処理を行う

signal progress_updated(task_name: String, progress: float, total: int, current: int)
signal registry_completed(registry_name: String)

var search_directories: Array[String] = []

var definition_commands_list: Array[String] = [
	"character",
	"set",
	"define_position"
]

var total_files: int = 0
var processed_files: int = 0
var definitions_processed: int = 0

func _init():
	# プロジェクト設定からディレクトリを取得
	_load_search_directories()

## プロジェクト設定から検索ディレクトリを読み込み
func _load_search_directories():
	search_directories = [
		"res://addons/argode/builtin/definitions/"
	]
	
	# プロジェクト設定から定義ディレクトリを取得
	var definition_dir = ProjectSettings.get_setting("argode/general/definition_directory", "res://definitions/")
	if definition_dir != "":
		search_directories.append(definition_dir)

## レジストリ処理を開始
func start_registry():
	total_files = 0
	processed_files = 0
	definitions_processed = 0
	
	# ファイル総数をカウント
	_count_rgd_files()
	
	ArgodeSystem.log("🔄 ArgodeDefinitionRegistry started. Total files: %d" % total_files)
	
	# 定義ファイルを処理
	await _process_definition_files()
	
	ArgodeSystem.log("✅ ArgodeDefinitionRegistry completed. Processed %d definitions." % definitions_processed)
	registry_completed.emit("ArgodeDefinitionRegistry")

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

## 定義ファイルを非同期で処理
func _process_definition_files():
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
				await _process_definition_file(path.path_join(file_name))
			file_name = dir.get_next()

## 個別の定義ファイルを処理
func _process_definition_file(file_path: String):
	processed_files += 1
	var progress = float(processed_files) / float(total_files)
	progress_updated.emit("定義処理", progress, total_files, processed_files)
	
	# RGDファイルから定義コマンドを抽出して実行
	var definitions = _extract_definition_commands(file_path)
	for definition in definitions:
		await _execute_definition_command(definition)
		definitions_processed += 1
	
	# 処理の重さをシミュレート
	await ArgodeSystem.get_tree().process_frame

## RGDファイルから定義コマンドを抽出
func _extract_definition_commands(file_path: String) -> Array:
	var definitions = []
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var line_number = 0
		while not file.eof_reached():
			var line = file.get_line().strip_edges()
			line_number += 1
			
			# コメント行や空行をスキップ
			if line.is_empty() or line.begins_with("#"):
				continue
			
			# 定義コマンドかチェック
			for command in definition_commands_list:
				if line.begins_with(command + " "):
					definitions.append({
						"command": command,
						"line": line,
						"file_path": file_path,
						"line_number": line_number
					})
					break
		file.close()
	return definitions

## 定義コマンドを実行
func _execute_definition_command(definition: Dictionary):
	ArgodeSystem.log("🏗️ Executing definition: %s at %s:%d" % [definition.command, definition.file_path, definition.line_number])
	
	# TODO: 実際の定義コマンド実行処理を実装
	match definition.command:
		"character":
			_process_character_definition(definition.line)
		"set":
			_process_variable_definition(definition.line)
		"define_position":
			_process_position_definition(definition.line)

## キャラクター定義を処理
func _process_character_definition(line: String):
	# character alice "アリス" color "#ffcc00" image_prefix "alice" voice_prefix "alice"
	# TODO: 実際のキャラクター定義処理
	pass

## 変数定義を処理
func _process_variable_definition(line: String):
	# set player_name = "プレイヤー"
	# TODO: 実際の変数定義処理
	pass

## ポジション定義を処理
func _process_position_definition(line: String):
	# define_position center x=640 y=360
	# TODO: 実際のポジション定義処理
	pass
