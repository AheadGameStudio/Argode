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

# RGDパーサーのインスタンス
var rgd_parser: ArgodeRGDParser

func _init():
	rgd_parser = ArgodeRGDParser.new()

## ファイルパスからRGDファイルを読み込んで実行準備
func load_scenario_file(file_path: String) -> bool:
	if not FileAccess.file_exists(file_path):
		ArgodeSystem.log("❌ Scenario file not found: %s" % file_path, 2)
		return false
	
	ArgodeSystem.log("📖 Loading scenario file: %s" % file_path)
	
	# RGDファイルをパース
	current_statements = rgd_parser.parse_file(file_path)
	
	if current_statements.is_empty():
		ArgodeSystem.log("⚠️ No statements parsed from file: %s" % file_path, 1)
		return false
	
	# デバッグ出力
	ArgodeSystem.log("✅ Loaded %d statements from %s" % [current_statements.size(), file_path])
	if ArgodeSystem.debug_manager.is_debug_mode():
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
		"say":
			await _execute_say_command(statement_args)
		_:
			ArgodeSystem.log("⚠️ Unknown statement type: %s" % statement_type, 1)

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

## Sayコマンドを実行
func _execute_say_command(args: Array):
	# SayCommandを直接実行
	await _execute_command("say", args)

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
