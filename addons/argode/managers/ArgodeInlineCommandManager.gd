# インラインコマンド管理
# ステートメント内で直接実行されるコマンドを管理
# ArgodeSystemの一部として、他のマネージャーやサービスと連携する

# 1. raw_textを受け取る。
# 2. TagTokenizerを呼び出し、テキストをトークンに分解させる。
# 3. トークンを一つずつループ処理する。
# 4. トークンが特殊タグであれば、TagRegistryに問い合わせ、対応するコマンドクラス（RubyCommandなど）を取得する。
# 5. そのコマンドを実行し、RichTextConverterに処理を委譲する。
# 6. RichTextConverterが返したBBCodeを結合して、最終的なRichTextLabel用のテキストを返す。

extends RefCounted
class_name ArgodeInlineCommandManager

var _raw_text: String
var tag_tokenizer: ArgodeTagTokenizer
var tag_registry: ArgodeTagRegistry
var rich_text_converter: ArgodeRichTextConverter

# 位置ベース処理のためのデータ構造
var position_commands: Array[Dictionary] = []  # 位置ごとのコマンドリスト
var display_text: String = ""                 # 表示用の加工済みテキスト
var character_positions: Array[int] = []      # 表示文字位置のマッピング

func _init():
	tag_tokenizer = ArgodeTagTokenizer.new()
	tag_registry = ArgodeTagRegistry.new()

## メインの処理関数：テキストを解析して表示用テキストと位置ベースコマンドを生成
func process_text(raw_text: String) -> Dictionary:
	# エスケープされた改行文字を実際の改行文字に前処理で変換
	_raw_text = raw_text.replace("\\n", "\n")
	position_commands.clear()
	character_positions.clear()
	
	# テキストをトークンに分解
	var tokens = tag_tokenizer.tokenize(_raw_text)
	
	# トークンから表示用テキストとコマンドリストを生成
	var result = _build_display_text_and_commands(tokens)
	
	# 結果をインスタンス変数に保存
	position_commands = result.position_commands
	display_text = result.display_text
	character_positions = result.character_positions
	
	ArgodeSystem.log("📋 InlineCommandManager: Processed %d commands at various positions" % position_commands.size())
	for cmd in position_commands:
		ArgodeSystem.log("  📍 Command '%s' at position %d" % [cmd.command_name, cmd.display_position])
	
	return {
		"display_text": result.display_text,
		"position_commands": result.position_commands,
		"character_positions": result.character_positions
	}

## トークンから表示用テキストと位置ベースコマンドを構築
func _build_display_text_and_commands(tokens: Array[ArgodeTagTokenizer.TokenData]) -> Dictionary:
	var display_builder: Array[String] = []
	var commands: Array[Dictionary] = []
	var char_positions: Array[int] = []
	var current_display_pos = 0
	
	for token in tokens:
		match token.type:
			ArgodeTagTokenizer.TokenType.TEXT:
				# 通常テキストは表示用テキストに追加
				display_builder.append(token.display_text)
				for i in range(token.display_text.length()):
					char_positions.append(token.start_position + i)
				current_display_pos += token.display_text.length()
			
			ArgodeTagTokenizer.TokenType.TAG:
				# タグの場合、コマンドを位置に登録（表示位置はコマンド実行タイミング）
				var command_info = _create_tag_command(token, current_display_pos)
				if not command_info.is_empty():
					commands.append(command_info)
			
			ArgodeTagTokenizer.TokenType.VARIABLE:
				# 変数の場合、表示用テキストに変数値を挿入（後で置換）
				var var_value = _get_variable_value(token.command_data.variable_name)
				display_builder.append(var_value)
				for i in range(var_value.length()):
					char_positions.append(token.start_position + i)
				current_display_pos += var_value.length()
			
			ArgodeTagTokenizer.TokenType.RUBY:
				# ルビの場合、ベーステキストのみ表示用に追加
				display_builder.append(token.display_text)  # base_text
				var ruby_command = _create_ruby_command(token, current_display_pos)
				if not ruby_command.is_empty():
					commands.append(ruby_command)
				
				for i in range(token.display_text.length()):
					char_positions.append(token.start_position + i)
				current_display_pos += token.display_text.length()
	
	return {
		"display_text": "".join(display_builder),
		"position_commands": commands,
		"character_positions": char_positions
	}

## タグコマンドの作成
func _create_tag_command(token: ArgodeTagTokenizer.TokenData, display_position: int) -> Dictionary:
	var tag_command = token.command_data.get("command", "")
	
	ArgodeSystem.log("🏷️ Creating tag command: '%s' at display_position %d" % [tag_command, display_position])
	
	# 終了タグの処理（例: /color）
	if tag_command.begins_with("/"):
		var base_command = tag_command.substr(1)  # "/"を除去
		if tag_registry.has_tag(base_command):
			var command_data = tag_registry.get_tag_command(base_command)
			var closing_args = token.command_data.duplicate()
			closing_args["_closing"] = true
			var result = {
				"type": "tag",
				"display_position": display_position,
				"original_position": token.start_position,
				"command_name": base_command,  # 基本コマンド名を使用
				"command_data": command_data,
				"args": closing_args,  # 終了フラグを追加
				"token": token
			}
			ArgodeSystem.log("✅ Closing tag command created: %s" % str(result))
			return result
		else:
			ArgodeSystem.log("❌ Base command not found for closing tag: %s" % base_command)
			return {}
	
	# 開始タグの処理
	if tag_registry.has_tag(tag_command):
		var command_data = tag_registry.get_tag_command(tag_command)
		var result = {
			"type": "tag",
			"display_position": display_position,
			"original_position": token.start_position,
			"command_name": tag_command,
			"command_data": command_data,
			"args": token.command_data,
			"token": token
		}
		ArgodeSystem.log("✅ Tag command created: %s" % str(result))
		return result
	else:
		ArgodeSystem.log("❌ Tag command not found: %s" % tag_command)
	
	return {}

## ルビコマンドの作成
func _create_ruby_command(token: ArgodeTagTokenizer.TokenData, display_position: int) -> Dictionary:
	# ルビコマンドの場合
	if tag_registry.has_tag("ruby"):
		var command_data = tag_registry.get_tag_command("ruby")
		return {
			"type": "ruby",
			"display_position": display_position,
			"original_position": token.start_position,
			"command_name": "ruby",
			"command_data": command_data,
			"args": {
				"base_text": token.command_data.base_text,
				"ruby_text": token.command_data.ruby_text
			},
			"token": token
		}
	
	return {}

## 変数値の取得（ArgodeVariableManagerと連携）
func _get_variable_value(variable_name: String) -> String:
	if ArgodeSystem and ArgodeSystem.has_method("get") and ArgodeSystem.get("VariableManager"):
		var variable_manager = ArgodeSystem.get("VariableManager")
		var value = variable_manager.get_variable(variable_name)
		return str(value) if value != null else "[" + variable_name + "]"
	return "[" + variable_name + "]"

## 指定された表示位置のコマンドを実行
func execute_commands_at_position(position: int) -> Array[Dictionary]:
	var executed_commands: Array[Dictionary] = []
	
	ArgodeSystem.log("🎯 Executing commands at position %d (total commands: %d)" % [position, position_commands.size()])
	
	for command_info in position_commands:
		if command_info.display_position == position:
			ArgodeSystem.log("🔍 Found command to execute: %s at position %d" % [command_info.command_name, command_info.display_position])
			var result = _execute_command(command_info)
			executed_commands.append({
				"command_info": command_info,
				"result": result
			})
	
	if executed_commands.is_empty():
		ArgodeSystem.log("⚠️ No commands found at position %d" % position)
	
	return executed_commands

## 指定された表示位置以下のコマンドを実行
func execute_commands_up_to_position(position: int) -> Array[Dictionary]:
	var executed_commands: Array[Dictionary] = []
	
	for command_info in position_commands:
		if command_info.display_position <= position:
			var result = _execute_command(command_info)
			executed_commands.append({
				"command_info": command_info,
				"result": result
			})
	
	return executed_commands

## 個別コマンドの実行
func _execute_command(command_info: Dictionary) -> Dictionary:
	var command_data = command_info.command_data
	var command_instance: ArgodeCommandBase = command_data.instance
	
	ArgodeSystem.log("🎯 Executing inline command: %s at position %d" % [command_info.command_name, command_info.display_position])
	ArgodeSystem.log("📋 Command args: %s" % str(command_info.args))
	
	# コマンドを実行
	if command_instance:
		command_instance.execute(command_info.args)
		ArgodeSystem.log("✅ Command executed successfully: %s" % command_info.command_name)
	else:
		ArgodeSystem.log("❌ Command instance is null for: %s" % command_info.command_name)
	
	return {
		"success": command_instance != null,
		"command_name": command_info.command_name,
		"position": command_info.display_position
	}

## TagRegistryの初期化（CommandRegistryから）
func initialize_tag_registry(command_registry: ArgodeCommandRegistry):
	tag_registry.initialize_from_command_registry(command_registry)
