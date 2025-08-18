# ArgodeDefinitionRegistry.gd
extends RefCounted

class_name ArgodeDefinitionRegistry

## Argode定義コマンドを登録するレジストリ
## .rgd ファイルから定義コマンドの位置情報を抽出し、辞書として保存
## ArgodeCommandRegistryと連携して定義コマンドを識別
## 実際のパースと実行は将来のRGDパーサーとArgodeStatementManagerが担当

signal progress_updated(task_name: String, progress: float, total: int, current: int)
signal registry_completed(registry_name: String)

var search_directories: Array[String] = []
var total_files: int = 0
var processed_files: int = 0

# 定義コマンドの位置情報を保存する辞書
var definition_dictionary: Dictionary = {}

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
	
	# デバッグ情報を出力
	ArgodeSystem.log("🔍 DefinitionRegistry search directories: %s" % str(search_directories))
	ArgodeSystem.log("� Project setting definition_directory: '%s'" % definition_dir)

## レジストリ処理を開始
func start_registry():
	total_files = 0
	processed_files = 0
	definition_dictionary.clear()
	
	# ファイル総数をカウント
	_count_rgd_files()
	
	ArgodeSystem.log("🔄 ArgodeDefinitionRegistry started. Total files: %d" % total_files)
	
	# ファイルがない場合の進捗表示
	if total_files == 0:
		progress_updated.emit("定義検索", 1.0, 1, 1)
	else:
		# 定義ファイルを処理
		await _process_definition_files()
	
	# 定義辞書をレジストリに登録
	_register_definitions_to_system()
	
	ArgodeSystem.log("✅ ArgodeDefinitionRegistry completed. Registered %d definitions." % definition_dictionary.size())
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
	progress_updated.emit("定義検索", progress, total_files, processed_files)
	
	ArgodeSystem.log("📄 Processing definition file: %s" % file_path)
	
	# RGDファイルから定義コマンドを抽出して登録
	_extract_definition_commands(file_path)

## RGDファイルから定義コマンドを抽出（ArgodeRGDParserを使用）
func _extract_definition_commands(file_path: String):
	# ArgodeRGDParserを使用してファイルをパース
	var parser = ArgodeRGDParser.new()
	# コマンドレジストリを手動で設定
	parser.set_command_registry(ArgodeSystem.CommandRegistry)
	
	var statements = parser.parse_file(file_path)
	
	if statements.is_empty():
		ArgodeSystem.log("⚠️ No statements found in definition file: %s" % file_path, 1)
		return
	
	# ArgodeCommandRegistryから定義コマンド名のリストを取得
	var define_command_names = ArgodeSystem.CommandRegistry.get_define_command_names()
	ArgodeSystem.log("🔍 Available define commands: %s" % str(define_command_names))
	ArgodeSystem.log("📄 Parsed %d statements from %s" % [statements.size(), file_path])
	
	# 各ステートメントをチェックして定義コマンドのみを抽出
	for statement in statements:
		if statement.get("type") == "command":
			var command_name = statement.get("name", "")
			if command_name in define_command_names:
				var line_content = _reconstruct_line_from_statement(statement)
				var line_number = statement.get("line", 0)
				_register_definition(command_name, line_content, file_path, line_number)

## ステートメント辞書から元の行を再構築
func _reconstruct_line_from_statement(statement: Dictionary) -> String:
	var line = statement.get("name", "")
	var args = statement.get("args", [])
	
	for arg in args:
		line += " "
		# 引数にスペースが含まれている場合はクォートで囲む
		if str(arg).find(" ") != -1:
			line += '"' + str(arg) + '"'
		else:
			line += str(arg)
	
	return line

## 定義コマンドを登録
func _register_definition(command_name: String, line_content: String, file_path: String, line_number: int):
	# 定義のユニークキーを生成
	var definition_key = "%s:%d:%s" % [file_path.get_file().get_basename(), line_number, command_name]
	
	# 定義データを作成
	var definition_data = {
		"command_name": command_name,
		"line_content": line_content,
		"file_path": file_path,
		"line_number": line_number,
		"command_info": ArgodeSystem.CommandRegistry.get_command(command_name)  # コマンド詳細情報
	}
	
	definition_dictionary[definition_key] = definition_data
	
	ArgodeSystem.log("📝 Definition registered: %s at %s:%d" % [command_name, file_path, line_number])

## 定義辞書をArgodeSystemに登録
func _register_definitions_to_system():
	# 定義辞書はRegistryが管理し、必要に応じて他のコンポーネントから参照される
	ArgodeSystem.log("🔗 Definition registry prepared with %d definitions" % definition_dictionary.size())

## 定義辞書を取得
func get_definition_dictionary() -> Dictionary:
	return definition_dictionary

## 特定のコマンド名の定義を取得
func get_definitions_by_command(command_name: String) -> Array[Dictionary]:
	var definitions: Array[Dictionary] = []
	for definition_key in definition_dictionary:
		var definition_data = definition_dictionary[definition_key]
		if definition_data.command_name == command_name:
			definitions.append(definition_data)
	return definitions

## ファイルパスで定義を検索
func find_definitions_in_file(file_path: String) -> Array[Dictionary]:
	var definitions: Array[Dictionary] = []
	for definition_key in definition_dictionary:
		var definition_data = definition_dictionary[definition_key]
		if definition_data.file_path == file_path:
			definitions.append(definition_data)
	return definitions

## 定義が存在するかチェック
func has_definitions() -> bool:
	return definition_dictionary.size() > 0

## 定義をステートメント形式で取得（StatementManager用）
func get_definition_statements() -> Array:
	var statements = []
	
	for definition_key in definition_dictionary:
		var definition_data = definition_dictionary[definition_key]
		var command_name = definition_data.get("command_name", "")
		var line_content = definition_data.get("line_content", "")
		var line_number = definition_data.get("line_number", 0)
		
		# RGDパーサーを使用して行をパース
		var parser = ArgodeRGDParser.new()
		# コマンドレジストリを手動で設定
		parser.set_command_registry(ArgodeSystem.CommandRegistry)
		
		var parsed_statements = parser.parse_text(line_content)
		
		# パースした結果をステートメントリストに追加
		for statement in parsed_statements:
			# 行番号を元の定義ファイルの行番号に設定
			statement["line"] = line_number
			# 定義情報も追加
			statement["definition_key"] = definition_key
			statement["source_file"] = definition_data.get("file_path", "")
			statements.append(statement)
	
	ArgodeSystem.log("📝 Converted %d definitions to %d statements" % [definition_dictionary.size(), statements.size()])
	return statements
