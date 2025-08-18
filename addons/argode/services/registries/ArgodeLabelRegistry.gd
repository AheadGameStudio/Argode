# ArgodeLabelRegistry.gd
extends RefCounted

class_name ArgodeLabelRegistry

## Argodeラベルを登録するレジストリ
## scenarios/ から .rgd ファイルを検索し、
## labelステートメントを抽出してラベル名・ファイルパス・行番号を登録

signal progress_updated(task_name: String, progress: float, total: int, current: int)
signal registry_completed(registry_name: String)

var search_directories: Array[String] = []

var total_files: int = 0
var processed_files: int = 0
var label_dictionary: Dictionary = {}
var label_names: PackedStringArray = []

func _init():
	# プロジェクト設定からディレクトリを取得
	_load_search_directories()

## プロジェクト設定から検索ディレクトリを読み込み
func _load_search_directories():
	# プロジェクト設定からシナリオディレクトリを取得
	var scenario_dir = ProjectSettings.get_setting("argode/general/scenario_directory", "res://scenarios/")
	if scenario_dir != "":
		search_directories = [scenario_dir]

## レジストリ処理を開始
func start_registry():
	total_files = 0
	processed_files = 0
	label_dictionary.clear()
	label_names.clear()
	
	# ファイル総数をカウント
	_count_rgd_files()
	
	ArgodeSystem.log("🔄 ArgodeLabelRegistry started. Total files: %d" % total_files)
	
	# シナリオファイルを処理
	await _process_scenario_files()
	
	ArgodeSystem.log("✅ ArgodeLabelRegistry completed. Registered %d labels." % label_dictionary.size())
	registry_completed.emit("ArgodeLabelRegistry")

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

## シナリオファイルを非同期で処理
func _process_scenario_files():
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
				await _process_scenario_file(path.path_join(file_name))
			file_name = dir.get_next()

## 個別のシナリオファイルを処理
func _process_scenario_file(file_path: String):
	processed_files += 1
	var progress = float(processed_files) / float(total_files)
	progress_updated.emit("ラベル検索", progress, total_files, processed_files)
	
	# RGDファイルからラベルを抽出
	_extract_labels_from_file(file_path)
	
	# 処理の重さをシミュレート
	await ArgodeSystem.get_tree().process_frame

## RGDファイルからラベルを抽出
func _extract_labels_from_file(file_path: String):
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var line_number = 0
		while not file.eof_reached():
			var line = file.get_line().strip_edges()
			line_number += 1
			
			# コメント行や空行をスキップ
			if line.is_empty() or line.begins_with("#"):
				continue
			
			# labelコマンドかチェック
			if line.begins_with("label "):
				var label_name = line.substr(6).strip_edges()
				_register_label(label_name, file_path, line_number)
		file.close()

## ラベルを登録
func _register_label(label_name: String, file_path: String, line_number: int):
# ラベルの重複チェック
	if label_dictionary.has(label_name):
		ArgodeSystem.log("❌ Error: Label '%s' already exists at %s:%d. Duplicate found at %s:%d" % [
			label_name,
			label_dictionary[label_name].path,
			label_dictionary[label_name].line,
			file_path,
			line_number
		], 2)
		return	# ラベル登録
	var label_data = {
		"label": label_name,
		"path": file_path,
		"line": line_number
	}
	
	label_dictionary[label_name] = label_data
	label_names.append(label_name)
	
	ArgodeSystem.log("🏷️ Label registered: %s at %s:%d" % [label_name, file_path, line_number])

## ラベル辞書を取得
func get_label_dictionary() -> Dictionary:
	return label_dictionary

## ラベル名配列を取得
func get_label_names() -> PackedStringArray:
	return label_names
