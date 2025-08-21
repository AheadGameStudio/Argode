# ArgodeLabelRegistry.gd
extends RefCounted

class_name ArgodeLabelRegistry

## Argodeラベルを登録するレジストリ
## scenarios/ から .rgd ファイルを検索し、
## labelステートメントを抽出してラベル名・ファイルパス・行番号を登録
## .rgdファイルはプレーンテキストとしてビルド後も利用可能

signal progress_updated(task_name: String, progress: float, total: int, current: int)
signal registry_completed(registry_name: String)

var search_directories: Array[String] = []

var total_files: int = 0
var processed_files: int = 0
var label_dictionary: Dictionary = {}

func _init():
	# プロジェクト設定からディレクトリを取得
	_load_search_directories()

## プロジェクト設定から検索ディレクトリを読み込み
func _load_search_directories():
	search_directories = []
	
	# プロジェクト設定からシナリオディレクトリを取得
	var scenario_dir = ProjectSettings.get_setting("argode/general/scenario_directory", "res://scenarios/")
	if scenario_dir != "":
		search_directories.append(scenario_dir)
	
	# カスタムシナリオディレクトリがあれば追加
	var custom_scenario_dir = ProjectSettings.get_setting("argode/general/custom_scenario_directory", "")
	if custom_scenario_dir != "" and custom_scenario_dir != scenario_dir:
		search_directories.append(custom_scenario_dir)
	
	# デバッグ情報を出力
	ArgodeSystem.log("🔍 LabelRegistry search directories: %s" % str(search_directories))
	ArgodeSystem.log("� Project setting scenario_directory: '%s'" % scenario_dir)

## レジストリ処理を開始
func start_registry():
	total_files = 0
	processed_files = 0
	label_dictionary.clear()
	
	# ファイル総数をカウント
	_count_rgd_files()
	
	# 🎬 WORKFLOW: Registry開始（GitHub Copilot重要情報）
	ArgodeSystem.log_workflow("LabelRegistry starting: %d scenario files to process" % total_files)
	
	# ファイルがない場合の進捗表示
	if total_files == 0:
		progress_updated.emit("ラベル検索", 1.0, 1, 1)
	else:
		# シナリオファイルを処理
		await _process_scenario_files()
	
	# ラベル辞書をレジストリに登録
	_register_labels_to_system()
	
	# 🎬 WORKFLOW: Registry完了（GitHub Copilot重要情報）  
	ArgodeSystem.log_workflow("LabelRegistry completed: %d labels registered" % label_dictionary.size())
	registry_completed.emit("ArgodeLabelRegistry")

## 設定されたディレクトリからRGDファイルの総数をカウント
func _count_rgd_files():
	for directory_path in search_directories:
		# 🔍 DEBUG: ディレクトリチェック詳細（通常は非表示）
		ArgodeSystem.log_debug_detail("Checking directory: %s" % directory_path)
		if DirAccess.dir_exists_absolute(directory_path):
			var count = _count_rgd_files_recursive(directory_path)
			total_files += count
			# 🔍 DEBUG: ファイル数詳細（通常は非表示）
			ArgodeSystem.log_debug_detail("Found %d .rgd files in %s" % [count, directory_path])
		else:
			# 🚨 CRITICAL: 重要なエラー（GitHub Copilot重要情報）
			ArgodeSystem.log_critical("Directory does not exist: %s" % directory_path)

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
	
	# 🔍 DEBUG: ファイル処理詳細（通常は非表示）
	ArgodeSystem.log_debug_detail("Processing scenario file: %s" % file_path)
	
	# RGDファイルからラベルを抽出
	_extract_labels_from_file(file_path)

## RGDファイルからラベルを抽出（ビルド後対応でFileAccessを使用）
func _extract_labels_from_file(file_path: String):
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		# 🚨 CRITICAL: 重要なエラー（GitHub Copilot重要情報）
		ArgodeSystem.log_critical("Failed to open scenario file: %s" % file_path)
		return
	
	var line_number = 0
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		line_number += 1
		
		# コメント行や空行をスキップ
		if line.is_empty() or line.begins_with("#"):
			continue
		
		# labelコマンドかチェック（コロン付きまたはなし）
		if line.begins_with("label "):
			var label_line = line.substr(6).strip_edges()
			var label_name = label_line
			
			# コロンがある場合は除去
			if label_line.ends_with(":"):
				label_name = label_line.substr(0, label_line.length() - 1).strip_edges()
			
			_register_label(label_name, file_path, line_number)
	
	file.close()

## ラベルを登録
func _register_label(label_name: String, file_path: String, line_number: int):
	# ラベルの重複チェック
	if label_dictionary.has(label_name):
		# 🚨 CRITICAL: 重要なエラー（GitHub Copilot重要情報）
		ArgodeSystem.log_critical("Label '%s' already exists at %s:%d. Duplicate found at %s:%d" % [
			label_name,
			label_dictionary[label_name].path,
			label_dictionary[label_name].line,
			file_path,
			line_number
		])
		return
		
	# ラベル登録
	var label_data = {
		"label": label_name,
		"path": file_path,
		"line": line_number,
		"file_resource": null  # 将来的なキャッシュ用
	}
	
	label_dictionary[label_name] = label_data
	
	# 🔍 DEBUG: ラベル発見詳細（通常は非表示）
	ArgodeSystem.log_debug_detail("Label registered: %s at %s:%d" % [label_name, file_path, line_number])

## ラベル辞書をArgodeSystemに登録
func _register_labels_to_system():
	# ラベル辞書はRegistryが管理し、必要に応じて他のコンポーネントから参照される
	# 🔍 DEBUG: Registry準備詳細（通常は非表示）
	ArgodeSystem.log_debug_detail("Label registry prepared with %d labels" % label_dictionary.size())

## ラベル辞書を取得
func get_label_dictionary() -> Dictionary:
	return label_dictionary

## ラベル名配列を取得（動的生成）
func get_label_names() -> PackedStringArray:
	var names: PackedStringArray = []
	for label_name in label_dictionary.keys():
		names.append(label_name)
	return names

## 特定のラベルを取得
func get_label(label_name: String) -> Dictionary:
	if label_dictionary.has(label_name):
		return label_dictionary[label_name]
	return {}

## ラベルが存在するかチェック
func has_label(label_name: String) -> bool:
	return label_dictionary.has(label_name)

## ファイルパスでラベルを検索
func find_labels_in_file(file_path: String) -> Array[Dictionary]:
	var labels: Array[Dictionary] = []
	for label_name in label_dictionary:
		var label_data = label_dictionary[label_name]
		if label_data.path == file_path:
			labels.append(label_data)
	return labels
