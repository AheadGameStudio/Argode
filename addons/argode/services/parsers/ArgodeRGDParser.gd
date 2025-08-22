# ArgodeRGDParser
# RGDファイルをパースする機能
# インデントブロックとネスト構造に対応した高度なパーサー
extends RefCounted
class_name ArgodeRGDParser

# パース結果のステートメント辞書キー
const STATEMENT_TYPE = "type"
const STATEMENT_NAME = "name"
const STATEMENT_ARGS = "args"
const STATEMENT_LINE = "line"
const STATEMENT_STATEMENTS = "statements"  # ネストしたステートメント
const STATEMENT_OPTIONS = "options"       # メニューの選択肢

# ステートメントタイプ
const TYPE_COMMAND = "command"
const TYPE_SAY = "say"
const TYPE_COMMENT = "comment"

# インデントブロックを持つコマンド
const BLOCK_COMMANDS = ["label", "if", "elif", "else", "menu"]
# if-elif-elseの連続ブロックコマンド
const IF_BLOCK_COMMANDS = ["if", "elif", "else"]

# コマンドレジストリへの参照（コマンド名の確認に使用）
var command_registry: ArgodeCommandRegistry

# パース中の状態
var current_line_index: int = 0
var lines: Array = []  # Array[String]から変更

# 初期化
func _init():
	# ArgodeSystemが初期化されているかチェック
	if ArgodeSystem and ArgodeSystem.has_method("get") and ArgodeSystem.get("CommandRegistry"):
		command_registry = ArgodeSystem.CommandRegistry

# コマンドレジストリを手動で設定（ArgodeSystemが初期化前の場合）
func set_command_registry(registry: ArgodeCommandRegistry):
	command_registry = registry

# ファイルパスからRGDファイルをパースする
func parse_file(file_path: String) -> Array:
	if not FileAccess.file_exists(file_path):
		push_error("ArgodeRGDParser: ファイルが見つかりません: " + file_path)
		return []
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("ArgodeRGDParser: ファイルを開けませんでした: " + file_path)
		return []
	
	var content = file.get_as_text()
	file.close()
	
	return parse_text(content)

# 指定されたラベルのブロック範囲のみをパースする
func parse_label_block(file_path: String, label_name: String) -> Array:
	if not FileAccess.file_exists(file_path):
		push_error("ArgodeRGDParser: ファイルが見つかりません: " + file_path)
		return []
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("ArgodeRGDParser: ファイルを開けませんでした: " + file_path)
		return []
	
	var content = file.get_as_text()
	file.close()
	
	return parse_label_block_from_text(content, label_name)

# テキストから指定されたラベルのブロック範囲のみをパースする
func parse_label_block_from_text(text: String, label_name: String) -> Array:
	lines = text.split("\n")
	current_line_index = 0
	
	ArgodeSystem.log_workflow("🔧 RGDParser: Searching for label '%s' in %d lines" % [label_name, lines.size()])
	
	# 指定されたラベルを探す
	var label_start_line = -1
	var label_indent = -1
	
	while current_line_index < lines.size():
		var line = lines[current_line_index]
		var clean_line = line.strip_edges()
		
		ArgodeSystem.log_debug_detail("  Line %d: '%s'" % [current_line_index + 1, clean_line])
		
		# ラベル行をチェック
		if clean_line.begins_with("label "):
			var label_line = clean_line.substr(6).strip_edges()
			var found_label_name = label_line
			
			# コロンがある場合は除去
			if label_line.ends_with(":"):
				found_label_name = label_line.substr(0, label_line.length() - 1).strip_edges()
			
			ArgodeSystem.log_workflow("🔧 Found label '%s' at line %d" % [found_label_name, current_line_index + 1])
			
			if found_label_name == label_name:
				label_start_line = current_line_index
				label_indent = _get_line_indent(line)
				current_line_index += 1
				ArgodeSystem.log_workflow("🔧 Target label found! Start line: %d, indent: %d" % [label_start_line + 1, label_indent])
				break
		
		current_line_index += 1
	
	# ラベルが見つからない場合
	if label_start_line == -1:
		push_warning("ArgodeRGDParser: ラベル '%s' が見つかりません" % label_name)
		return []
	
	# ラベルブロックの終端を探す（同じインデントレベルの次のラベルまで）
	var block_end_line = lines.size() - 1
	var last_content_line = -1  # 最後の有効なコンテンツ行を記録
	
	ArgodeSystem.log_workflow("🔧 Searching for block end from line %d" % (current_line_index + 1))
	
	while current_line_index < lines.size():
		var line = lines[current_line_index]
		var line_indent = _get_line_indent(line)
		var clean_line = line.strip_edges()
		
		ArgodeSystem.log_debug_detail("  Block scan line %d: indent=%d, content='%s'" % [current_line_index + 1, line_indent, clean_line])
		
		# 空行やコメント行はスキップするが、その前に有効なコンテンツがあったことを記録
		if clean_line.is_empty() or clean_line.begins_with("#"):
			current_line_index += 1
			continue
		
		# 同じインデントレベルで別のラベルが見つかったら終了
		if line_indent <= label_indent and clean_line.begins_with("label "):
			# 最後の有効なコンテンツ行を終端とする
			block_end_line = last_content_line if last_content_line != -1 else current_line_index - 1
			ArgodeSystem.log_workflow("🔧 Block end found at line %d (next label found, last content at line %d)" % [block_end_line + 1, last_content_line + 1])
			break
		
		# 有効なコンテンツ行を記録
		last_content_line = current_line_index
		current_line_index += 1
	
	# ファイル終端の場合、最後の有効なコンテンツ行を使用
	if current_line_index >= lines.size() and last_content_line != -1:
		block_end_line = last_content_line
		ArgodeSystem.log_workflow("🔧 Block end at file end: line %d" % (block_end_line + 1))
	
	# ラベルブロック部分のテキストを抽出
	var block_lines = []
	for i in range(label_start_line, block_end_line + 1):
		block_lines.append(lines[i])
		ArgodeSystem.log_debug_detail("  Block content line %d: '%s'" % [i + 1, lines[i]])
	
	var block_text = "\n".join(block_lines)
	ArgodeSystem.log_workflow("🔧 Extracted block text (%d lines):\n%s" % [block_lines.size(), block_text])
	
	# ブロック部分をパース
	return parse_text(block_text)

# テキストからステートメントリストを生成する（高度なパーサー）
func parse_text(text: String) -> Array:
	lines = text.split("\n")
	current_line_index = 0
	
	var statements = []
	
	# ラベルブロック内では最初のラベル行をスキップして、その子ステートメントを処理する
	var skip_first_label = false
	if lines.size() > 0:
		var first_line = lines[0].strip_edges()
		if first_line.begins_with("label "):
			skip_first_label = true
			# ラベル自体をステートメントとして追加
			var label_tokens = _tokenize_line(first_line)
			if label_tokens.size() >= 2:
				var label_statement = {
					STATEMENT_TYPE: TYPE_COMMAND,
					STATEMENT_NAME: label_tokens[0],
					STATEMENT_ARGS: [label_tokens[1].rstrip(":")],
					STATEMENT_LINE: 1
				}
				statements.append(label_statement)
			current_line_index = 1
	
	while current_line_index < lines.size():
		# ラベルブロック内では、インデントレベル1以上の行を処理
		var target_indent = 1 if skip_first_label else 0
		var statement = _parse_next_statement(target_indent)
		if statement and not statement.is_empty():
			statements.append(statement)
		elif current_line_index < lines.size():
			# インデントが合わない場合は次の行へ
			current_line_index += 1
	
	return statements

# 次のステートメントをパース（指定されたインデントレベルで）
func _parse_next_statement(expected_indent: int) -> Dictionary:
	# 空行やコメント行をスキップ
	_skip_empty_and_comment_lines()
	
	if current_line_index >= lines.size():
		return {}
	
	var line = lines[current_line_index]
	var line_number = current_line_index + 1
	var actual_indent = _get_line_indent(line)
	var clean_line = line.strip_edges()
	
	# ラベルブロック内では、期待されるインデント以上であれば処理を続行
	# ただし、より深いインデントは子ブロックとして扱う
	if expected_indent > 0:  # ラベルブロック内の場合
		if actual_indent < expected_indent:
			return {}  # インデントが足りない場合は終了
		# actual_indent >= expected_indent の場合は処理続行
	else:  # トップレベルの場合
		if actual_indent != expected_indent:
			return {}
	
	current_line_index += 1
	
	# 空行の場合は次へ
	if clean_line.is_empty():
		return _parse_next_statement(expected_indent)
	
	# セリフ行の検出
	if clean_line.begins_with('"') and clean_line.ends_with('"'):
		return _create_say_statement(clean_line, line_number)
	
	# トークン化
	var tokens = _tokenize_line(clean_line)
	if tokens.is_empty():
		return {}
	
	var first_token = tokens[0]
	
	# コロン記法の処理（コマンド名にコロンが付いている場合）
	var potential_command = first_token
	if first_token.ends_with(":"):
		potential_command = first_token.substr(0, first_token.length() - 1)
	
	# 登録されているコマンドかチェック（コロン記法も含む）
	if command_registry and (command_registry.has_command(first_token) or command_registry.has_command(potential_command)):
		return _parse_command_statement(tokens, line_number, expected_indent)
	
	# デバッグ: labelコマンド検出の問題をデバッグ
	if first_token == "label" or potential_command == "label":
		if not command_registry:
			push_warning("🔧 RGDParser Debug: command_registry is null")
		else:
			var has_label = command_registry.has_command("label")
			push_warning("🔧 RGDParser Debug: label command registered = %s" % has_label)
			if has_label:
				# labelが登録されているなら強制的にコマンドとして処理
				return _parse_command_statement(tokens, line_number, expected_indent)
	
	# キャラクターエイリアス + セリフの形式をチェック
	if tokens.size() >= 2:
		var potential_message = _reconstruct_message_from_tokens(tokens, 1)
		if potential_message.begins_with('"') and potential_message.ends_with('"'):
			return _create_say_statement_with_character(first_token, potential_message, line_number)
	
	# 不明な行の場合はワーニング
	push_warning("ArgodeRGDParser: 解析できない行です (行 " + str(line_number) + "): " + clean_line)
	return {}

# コマンドステートメントをパース（ブロック構造対応）
func _parse_command_statement(tokens: Array, line_number: int, current_indent: int) -> Dictionary:
	var command_name = tokens[0]
	var args = _extract_args_from_tokens(tokens, 1)
	
	# コロン記法への対応（例: "label test:" → "label", ["test"]）
	var has_colon = false
	
	# コマンド名自体がコロンで終わっている場合
	if command_name.ends_with(":"):
		command_name = command_name.substr(0, command_name.length() - 1)
		has_colon = true
	# 最後の引数がコロンで終わっている場合
	elif not args.is_empty():
		var last_arg = args[-1]
		if str(last_arg).ends_with(":"):
			# 最後の引数からコロンを除去
			args[-1] = str(last_arg).substr(0, str(last_arg).length() - 1)
			has_colon = true
	
	var statement = {
		STATEMENT_TYPE: TYPE_COMMAND,
		STATEMENT_NAME: command_name,
		STATEMENT_ARGS: args,
		STATEMENT_LINE: line_number
	}
	
	# ブロックコマンドまたはコロン記法の場合は子ステートメントを解析
	if command_name in BLOCK_COMMANDS or has_colon:
		if command_name == "menu":
			statement[STATEMENT_OPTIONS] = _parse_menu_options(current_indent + 1)
		elif command_name == "if":
			_parse_if_block(statement, current_indent + 1)
		elif command_name in ["elif", "else"]:
			# elif/elseはifブロック内でのみ処理されるべき
			# 単独で現れた場合はコマンドとして処理（エラーは呼び出し元で判定）
			pass
		else:
			statement[STATEMENT_STATEMENTS] = _parse_block_statements(current_indent + 1)
	
	return statement

# ifブロック全体を解析（if-elif-else連続ブロック対応）
func _parse_if_block(if_statement: Dictionary, block_indent: int):
	# if文の子ステートメントを解析
	if_statement[STATEMENT_STATEMENTS] = _parse_block_statements(block_indent)
	
	# elif/elseブロックを探す
	var elif_else_blocks = []
	
	while current_line_index < lines.size():
		# 次の行をプレビュー（インデックスは進めない）
		var preview_line = lines[current_line_index]
		var preview_indent = _get_line_indent(preview_line)
		var preview_clean = preview_line.strip_edges()
		
		# インデントが合わない場合は終了（if文と同じレベルのものを探す）
		if preview_indent != block_indent - 1:  # if文と同じレベル
			break
		
		var preview_tokens = _tokenize_line(preview_clean)
		if preview_tokens.is_empty():
			break
		
		var preview_command = preview_tokens[0]
		# コロン記法への対応
		if preview_command.ends_with(":"):
			preview_command = preview_command.substr(0, preview_command.length() - 1)
		
		# elif/elseではない場合は終了
		if preview_command not in ["elif", "else"]:
			break
		
		# elif/elseブロックを解析
		var elif_else_statement = _parse_next_statement(block_indent - 1)
		if elif_else_statement and not elif_else_statement.is_empty():
			elif_else_statement[STATEMENT_STATEMENTS] = _parse_block_statements(block_indent)
			elif_else_blocks.append(elif_else_statement)
	
	# elif/elseブロックがある場合は親のif文に追加
	if not elif_else_blocks.is_empty():
		if_statement["elif_else_blocks"] = elif_else_blocks

# ブロック内のステートメントを解析
func _parse_block_statements(block_indent: int) -> Array:
	var statements = []
	
	while current_line_index < lines.size():
		var statement = _parse_next_statement(block_indent)
		if statement and not statement.is_empty():
			statements.append(statement)
		else:
			break
	
	return statements

# メニューの選択肢を解析
func _parse_menu_options(option_indent: int) -> Array:
	var options = []
	
	while current_line_index < lines.size():
		_skip_empty_and_comment_lines()
		
		if current_line_index >= lines.size():
			break
		
		var line = lines[current_line_index]
		var line_number = current_line_index + 1
		var actual_indent = _get_line_indent(line)
		var clean_line = line.strip_edges()
		
		# インデントが一致しない場合は終了
		if actual_indent != option_indent:
			break
		
		# 選択肢テキストはクォートで囲まれている、またはコロンで終わる
		var option_text = ""
		var is_option = false
		
		if clean_line.begins_with('"') and clean_line.ends_with('":'):
			# "テキスト": 形式
			option_text = clean_line.substr(1, clean_line.length() - 3)
			is_option = true
		elif clean_line.begins_with('"') and clean_line.ends_with('"'):
			# "テキスト" 形式（従来）
			option_text = clean_line.substr(1, clean_line.length() - 2)
			is_option = true
		
		if is_option:
			current_line_index += 1
			
			var option = {
				"text": option_text,
				"line": line_number,
				"statements": _parse_block_statements(option_indent + 1)
			}
			
			options.append(option)
		else:
			push_warning("ArgodeRGDParser: Invalid menu option format (line %d): %s" % [line_number, clean_line])
			current_line_index += 1
	
	return options

# 空行とコメント行をスキップ
func _skip_empty_and_comment_lines():
	while current_line_index < lines.size():
		var line = lines[current_line_index].strip_edges()
		if line.is_empty() or line.begins_with("#"):
			current_line_index += 1
		else:
			break

# 行のインデントレベルを取得
func _get_line_indent(line: String) -> int:
	var indent = 0
	for i in range(line.length()):
		if line[i] == '\t':
			# タブは1インデントレベル
			indent += 1
		elif line[i] == ' ':
			# スペース1つは1インデントレベル（簡略化）
			indent += 1
		else:
			break
	return indent

# 行をトークンに分割（クォート内のスペースを保持）
func _tokenize_line(line: String) -> Array:
	var tokens = []
	var current_token = ""
	var in_quotes = false
	var i = 0
	
	while i < line.length():
		var char = line[i]
		
		if char == '"':
			in_quotes = not in_quotes
			current_token += char
		elif char == ' ' and not in_quotes:
			if not current_token.is_empty():
				tokens.append(current_token)
				current_token = ""
		else:
			current_token += char
		
		i += 1
	
	# 最後のトークンを追加
	if not current_token.is_empty():
		tokens.append(current_token)
	
	return tokens

# トークンから引数を抽出
func _extract_args_from_tokens(tokens: Array, start_index: int) -> Array:
	var args = []
	
	# set文の特別な処理（= 演算子で分割）
	if tokens.size() > start_index and tokens[0] == "set":
		# トークンを結合して引数文字列を作成
		var arg_string = ""
		for i in range(start_index, tokens.size()):
			if i > start_index:
				arg_string += " "
			arg_string += tokens[i]
		
		# "set player.name = value" や "set player.affection += 10" の形式
		var equals_pos = arg_string.find("=")
		if equals_pos != -1:
			var variable_part = arg_string.substr(0, equals_pos).strip_edges()
			var value_part = arg_string.substr(equals_pos + 1).strip_edges()
			
			# 複合演算子のチェック (+=, -=, など)
			if equals_pos > 0 and arg_string[equals_pos - 1] in ["+", "-", "*", "/"]:
				# 複合演算子の場合、演算子部分も含めて処理
				var operator_pos = equals_pos - 1
				var operator_char = arg_string[operator_pos]
				variable_part = arg_string.substr(0, operator_pos).strip_edges()
				value_part = operator_char + "= " + value_part  # 演算子と値を結合
			
			# クォートを除去
			if value_part.begins_with('"') and value_part.ends_with('"'):
				value_part = value_part.substr(1, value_part.length() - 2)
			
			args.append(variable_part)
			args.append(value_part)
			return args
	
	# 通常の引数抽出（トークンを個別に処理）
	for i in range(start_index, tokens.size()):
		var token = tokens[i]
		# クォートを除去して引数として追加
		if token.begins_with('"') and token.ends_with('"'):
			args.append(token.substr(1, token.length() - 2))
		else:
			args.append(token)
	
	return args

# トークンからメッセージを再構築
func _reconstruct_message_from_tokens(tokens: Array, start_index: int) -> String:
	var message = ""
	
	for i in range(start_index, tokens.size()):
		if i > start_index:
			message += " "
		message += tokens[i]
	
	return message

# sayステートメントを作成（クォート付きテキストのみ）
func _create_say_statement(line: String, line_number: int) -> Dictionary:
	var cleaned_text = line.substr(1, line.length() - 2) # クォートを除去
	
	return {
		STATEMENT_TYPE: TYPE_SAY,
		STATEMENT_NAME: "say",
		STATEMENT_ARGS: [cleaned_text],
		STATEMENT_LINE: line_number
	}

# sayステートメントを作成（キャラクター + メッセージ）
func _create_say_statement_with_character(character: String, message: String, line_number: int) -> Dictionary:
	var cleaned_message = message.substr(1, message.length() - 2) # クォートを除去
	
	return {
		STATEMENT_TYPE: TYPE_SAY,
		STATEMENT_NAME: "say",
		STATEMENT_ARGS: [character, cleaned_message],
		STATEMENT_LINE: line_number
	}

# デバッグ用：パース結果を表示
func debug_print_statements(statements: Array, indent_level: int = 0):
	var indent = "  ".repeat(indent_level)
	
	if indent_level == 0:
		print("ArgodeRGDParser: パース結果 (" + str(statements.size()) + " ステートメント)")
	
	for statement in statements:
		var line = statement.get(STATEMENT_LINE, 0)
		var type = statement.get(STATEMENT_TYPE, "unknown")
		var name = statement.get(STATEMENT_NAME, "")
		var args = statement.get(STATEMENT_ARGS, [])
		
		print(indent + "行 " + str(line) + ": " + type + " - " + name + " " + str(args))
		
		# 子ステートメントがある場合は再帰的に表示
		if statement.has(STATEMENT_STATEMENTS):
			debug_print_statements(statement[STATEMENT_STATEMENTS], indent_level + 1)
		
		# elif/elseブロックがある場合は表示
		if statement.has("elif_else_blocks"):
			print(indent + "  elif/else blocks:")
			debug_print_statements(statement["elif_else_blocks"], indent_level + 2)
		
		# メニューオプションがある場合は表示
		if statement.has(STATEMENT_OPTIONS):
			print(indent + "  menu options:")
			for option in statement[STATEMENT_OPTIONS]:
				print(indent + "    " + str(option.get("text", "")) + " (行 " + str(option.get("line", 0)) + ")")
				if option.has("statements"):
					debug_print_statements(option["statements"], indent_level + 3)