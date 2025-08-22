# インラインコマンド管理
# ステートメント内で直接実行されるコマンドを管理
# ArgodeSystemの一部として、他のマネージャーやサービスと連携する

# 1. raw_textを受け取る。
# 2. TagTokenizerを呼び出し、テキストをトークンに分解させる。
# 3. トークンを一つずつループ処理する。
# 4. トークンが特殊タグであれば、TagRegistryに問い合わせ、対応するコマンドクラス（RubyCommandなど）を取得する。
# 5. そのコマンドを実行し、RichTextConverterに処理を委譲する。

extends RefCounted
class_name ArgodeInlineCommandManager

var _raw_text: String
var tag_tokenizer: ArgodeTagTokenizer
var tag_registry: ArgodeTagRegistry
var variable_resolver: ArgodeVariableResolver

# 位置ベース処理のためのデータ構造
var position_commands: Array[Dictionary] = []  # 位置ごとのコマンドリスト
var display_text: String = ""                 # 表示用の加工済みテキスト
var character_positions: Array[int] = []      # 表示文字位置のマッピング

func _init():
	tag_tokenizer = ArgodeTagTokenizer.new()
	tag_registry = ArgodeTagRegistry.new()
	
	# TagRegistryをCommandRegistryから初期化
	if ArgodeSystem and ArgodeSystem.CommandRegistry:
		tag_registry.initialize_from_command_registry(ArgodeSystem.CommandRegistry)
		ArgodeSystem.log_debug_detail("🏷️ InlineCommandManager: TagRegistry initialized with %d tags" % tag_registry.get_tag_names().size())
	else:
		ArgodeSystem.log_critical("🚨 InlineCommandManager: CommandRegistry not available for tag initialization")
	
	# VariableResolverを初期化
	if ArgodeSystem and ArgodeSystem.VariableManager:
		variable_resolver = ArgodeVariableResolver.new(ArgodeSystem.VariableManager)

## メインの処理関数：テキストを解析して表示用テキストと位置ベースコマンドを生成
func process_text(raw_text: String) -> Dictionary:
	# VariableResolverが初期化されていない場合の保険
	if not variable_resolver and ArgodeSystem and ArgodeSystem.VariableManager:
		variable_resolver = ArgodeVariableResolver.new(ArgodeSystem.VariableManager)
	
	# TagRegistryが初期化されていない場合の保険
	if tag_registry.get_tag_names().is_empty() and ArgodeSystem and ArgodeSystem.CommandRegistry:
		tag_registry.initialize_from_command_registry(ArgodeSystem.CommandRegistry)
		ArgodeSystem.log_debug_detail("🏷️ InlineCommandManager: TagRegistry late-initialized with %d tags" % tag_registry.get_tag_names().size())
	
	# エスケープされた改行文字を実際の改行文字に前処理で変換
	_raw_text = raw_text.replace("\\n", "\n")
	
	# 変数解決を先に実行
	if variable_resolver:
		_raw_text = variable_resolver.resolve_text(_raw_text)
	
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
				# 変数の場合は既にresolve_textで処理済みのため、通常テキストとして扱う
				display_builder.append(token.display_text)
				for i in range(token.display_text.length()):
					char_positions.append(token.start_position + i)
				current_display_pos += token.display_text.length()
			
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
	ArgodeSystem.log("🔍 Available tags: %s" % str(tag_registry.get_tag_names()))
	
	# 終了タグの処理（例: /color）
	if tag_command.begins_with("/"):
		var base_command = tag_command.substr(1)  # "/"を除去
		ArgodeSystem.log("🔍 Processing closing tag for base command: %s" % base_command)
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
	ArgodeSystem.log("🔍 Processing opening tag: %s" % tag_command)
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
		# WaitCommandのような待機を伴うコマンドの場合は軽量な待機処理
		if command_info.command_name == "wait" or command_info.command_name == "w":
			ArgodeSystem.log("⏸️ Executing inline wait: %s" % command_info.command_name)
			# インライン用の軽量な待機処理（ログのみ）
			_execute_inline_wait(command_info.args)
		else:
			# 通常のインラインコマンド（色、サイズなど）は同期実行
			command_instance.execute(command_info.args)
		ArgodeSystem.log("✅ Command executed successfully: %s" % command_info.command_name)
	else:
		ArgodeSystem.log("❌ Command instance is null for: %s" % command_info.command_name)
	
	return {
		"success": command_instance != null,
		"command_name": command_info.command_name,
		"position": command_info.display_position
	}

## Wait系のコマンドを非同期実行
func _execute_wait_command_async(command_instance: ArgodeCommandBase, args: Dictionary):
	ArgodeSystem.log("⏱️ Starting async wait command execution")
	# WaitCommandを非同期で実行
	await command_instance.execute(args)
	ArgodeSystem.log("⏱️ Async wait command completed")

## インライン用の軽量な待機処理（ログのみ）
func _execute_inline_wait(args: Dictionary):
	var wait_time: float = 1.0
	
	# 引数から待機時間を取得
	if args.has("w"):
		wait_time = float(args["w"])
	elif args.has("value"):
		wait_time = float(args["value"])
	elif args.has("0"):
		wait_time = float(args["0"])
	
	ArgodeSystem.log("⏸️ Inline wait: %.1f seconds - pausing typewriter" % wait_time)
	
	# ヘッドレスモードでは短縮
	if ArgodeSystem.is_auto_play_mode():
		wait_time = 0.1
	
	# TypewriterServiceを一時停止
	var typewriter_service = ArgodeSystem.get_service("TypewriterService")
	if not typewriter_service:
		# 別の名前で試行
		typewriter_service = ArgodeSystem.get_service("ArgodeTypewriterService")
	
	if typewriter_service:
		typewriter_service.pause_typing()
		ArgodeSystem.log("⏸️ Typewriter paused for inline wait")
		
		# 指定時間待機
		await Engine.get_main_loop().create_timer(wait_time).timeout
		
		# TypewriterServiceを再開
		typewriter_service.resume_typing()
		ArgodeSystem.log("▶️ Typewriter resumed after %.1f seconds" % wait_time)
	else:
		ArgodeSystem.log("⚠️ TypewriterService not found for inline wait - checking available services")
		var services = ArgodeSystem.get_all_services()
		for service_name in services:
			ArgodeSystem.log("📋 Available service: " + service_name)
		await Engine.get_main_loop().create_timer(wait_time).timeout
	
	ArgodeSystem.log("⏱️ Inline wait completed: %.1f seconds" % wait_time)

## TagRegistryの初期化（CommandRegistryから）
func initialize_tag_registry(command_registry: ArgodeCommandRegistry):
	tag_registry.initialize_from_command_registry(command_registry)
