extends Node

signal script_finished
# v2新機能: カスタムコマンドシグナル発行システム
signal custom_command_executed(command_name: String, parameters: Dictionary, line: String)

var script_lines: PackedStringArray = []
var label_map: Dictionary = {}
var call_stack: Array[Dictionary] = []
var current_script_path: String = ""  # 現在実行中のスクリプトファイルパス
var current_line_index: int = -1
var is_playing: bool = false
var is_waiting_for_choice: bool = false

var regex_label: RegEx
var regex_say: RegEx
var regex_set: RegEx
var regex_if: RegEx
var regex_menu: RegEx
var regex_jump: RegEx
var regex_call: RegEx
var regex_show: RegEx
var regex_scene: RegEx
var regex_define: RegEx
var regex_return: RegEx
var regex_else: RegEx
var regex_choice: RegEx
var regex_hide: RegEx
var regex_jump_file: RegEx

# v2新機能: 定義ステートメント用正規表現
var regex_character_stmt: RegEx
var regex_image_stmt: RegEx
var regex_audio_stmt: RegEx
var regex_shader_stmt: RegEx

# v2新機能: スクリーン関連正規表現
var regex_call_screen: RegEx
var regex_close_screen: RegEx

# v2新機能: カスタムコマンド検出用正規表現
var regex_custom_command: RegEx

# v2新機能: ウィンドウ制御用正規表現
var regex_window: RegEx

# v2: ArgodeSystem統合により、直接参照に変更
var character_manager  # CharacterManager
var ui_manager  # UIManager
var variable_manager  # VariableManager
var transition_player  # TransitionPlayer
var layer_manager  # LayerManager (v2新機能)
var label_registry  # LabelRegistry
var script_manager: Node

func _ready():
	_compile_regex()
	# v2: 参照はArgodeSystemの_setup_manager_references()で設定される
	print("📖 AdvScriptPlayer initialized (v2)")

func _compile_regex():
	regex_label = RegEx.new()
	regex_label.compile("^label\\s+(?<name>\\w+):")  # ラベルはインデントなし
	
	# 全てのコマンドをインデント対応
	regex_say = RegEx.new()
	regex_say.compile("^\\s*(?:(?<char_id>\\w+)\\s+)?\"(?<message>.*)\"")
	
	regex_set = RegEx.new()
	regex_set.compile("^\\s*set\\s+(?<var_name>\\w+)\\s*=\\s*(?<expression>.+)")
	
	regex_if = RegEx.new()
	regex_if.compile("^\\s*if\\s+(?<condition>.+):")
	
	regex_menu = RegEx.new()
	regex_menu.compile("^\\s*menu:")
	
	regex_jump = RegEx.new()
	regex_jump.compile("^\\s*jump\\s+(?<label>\\w+)")
	
	regex_call = RegEx.new()
	regex_call.compile("^\\s*call\\s+(?<label>\\w+)")
	
	regex_show = RegEx.new()
	# show character_id [expression] [at position] [with transition]
	regex_show.compile("^\\s*show\\s+(?<target>\\w+)(?:\\s+(?<param1>\\w+))?(?:\\s+at\\s+(?<position>\\w+))?(?:\\s+with\\s+(?<transition>\\w+))?")
	
	regex_scene = RegEx.new()
	regex_scene.compile("^\\s*scene\\s+(?<scene_name>[\\w\\s]+?)(?:\\s+with\\s+(?<transition>\\w+))?$")
	
	regex_define = RegEx.new()
	regex_define.compile("^\\s*define\\s+(?<id>\\w+)\\s*=\\s*Character\\(\"(?<resource_path>[^\"]+)\"\\)")
	
	regex_return = RegEx.new()
	regex_return.compile("^\\s*return")
	
	regex_else = RegEx.new()
	regex_else.compile("^\\s*else:")
	
	regex_choice = RegEx.new()
	regex_choice.compile("^\\s*\"([^\"]+)\":")  # 選択肢もインデント対応
	
	regex_hide = RegEx.new()
	regex_hide.compile("^\\s*hide\\s+(?<char_id>\\w+)(?:\\s+with\\s+(?<transition>\\w+))?")
	
	regex_jump_file = RegEx.new()
	regex_jump_file.compile("^\\s*jump\\s+(?<file>[\\w_/]+)\\.(?<label>\\w+)")
	
	# v2新機能もインデント対応
	regex_character_stmt = RegEx.new()
	regex_character_stmt.compile("^\\s*character\\s+")
	
	regex_image_stmt = RegEx.new()
	regex_image_stmt.compile("^\\s*image\\s+")
	
	regex_audio_stmt = RegEx.new()
	regex_audio_stmt.compile("^\\s*audio\\s+")
	
	regex_shader_stmt = RegEx.new()
	regex_shader_stmt.compile("^\\s*shader\\s+")
	
	regex_call_screen = RegEx.new()
	regex_call_screen.compile("^\\s*call_screen\\s+(?<screen_path>[^\\s]+)(?:\\s+(?<parameters>.*))?")
	
	regex_close_screen = RegEx.new()
	regex_close_screen.compile("^\\s*close_screen(?:\\s+(?<return_value>.*))?$")
	
	regex_window = RegEx.new()
	regex_window.compile("^\\s*window\\s+(?<action>show|hide|auto)(?:\\s+with\\s+(?<transition>\\w+))?$")
	
	regex_custom_command = RegEx.new()
	regex_custom_command.compile("^\\s*(?<command>\\w+)(?:\\s+(?<parameters>.*))?$")

func load_script(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("🚫 Script file not found: " + path)
		return
	
	script_lines = file.get_as_text().split("\n")
	file.close()
	_preparse_labels()
	current_line_index = -1
	is_playing = false
	print("📖 Script loaded: ", path)

func _preparse_labels():
	label_map.clear()
	
	# First pass: process all define commands
	for i in range(script_lines.size()):
		var line = script_lines[i].strip_edges()
		var define_match = regex_define.search(line)
		if define_match:
			var char_id = define_match.get_string("id")
			var resource_path = define_match.get_string("resource_path")
			if variable_manager:
				variable_manager.set_character_def(char_id, resource_path)
			else:
				print("⚠️ AdvScriptPlayer: VariableManager not available for define processing")
	
	# Second pass: find all labels
	for i in range(script_lines.size()):
		var line = script_lines[i].strip_edges()
		var label_match = regex_label.search(line)
		if label_match:
			var label_name = label_match.get_string("name")
			label_map[label_name] = i
			print("📍 Found label: ", label_name, " at line ", i)

func play_from_label(label_name: String):
	# まず現在のスクリプト内でラベルを探す
	if label_map.has(label_name):
		current_line_index = label_map[label_name]
		is_playing = true
		is_waiting_for_choice = false
		_tick()
		return
	
	# 現在のスクリプトにない場合、LabelRegistryで全ファイルを検索
	print("🔍 Label '", label_name, "' not found in current file, trying cross-file jump")
	if label_registry and label_registry.has_method("jump_to_label"):
		print("📞 Calling LabelRegistry.jump_to_label(", label_name, ")")
		if label_registry.jump_to_label(label_name, self):
			print("🌟 Cross-file jump successful: ", label_name)
			return
		else:
			print("❌ Cross-file jump failed for: ", label_name)
	else:
		print("⚠️ LabelRegistry not available or missing method")
	
	# どこにも見つからない場合
	push_error("🚫 Label not found anywhere: " + label_name)
	print("❌ Available labels in current file: ", label_map.keys())
	if label_registry and label_registry.has_method("get_registry_stats"):
		var stats = label_registry.get_registry_stats()
		print("❌ Registry contains ", stats.total_labels, " labels across all files")
	print("🛑 Script execution stopped due to missing label")
	is_playing = false

func next():
	if is_playing and not is_waiting_for_choice:
		_tick()

func _tick():
	current_line_index += 1
	if current_line_index >= script_lines.size():
		is_playing = false
		script_finished.emit()
		print("📜 Script finished.")
		return
	
	var line = script_lines[current_line_index].strip_edges()
	
	if line.is_empty() or line.begins_with("#"):
		_tick()
		return
	
	var stop_execution = await _parse_and_execute(line)
	
	if not stop_execution:
		_tick()

func _parse_and_execute(line: String) -> bool:
	var regex_match: RegExMatch
	
	# v2新機能: 定義ステートメント処理
	if regex_character_stmt.search(line):
		_handle_character_statement(line)
		return false
	
	if regex_image_stmt.search(line):
		_handle_image_statement(line)
		return false
	
	if regex_audio_stmt.search(line):
		_handle_audio_statement(line)
		return false
	
	if regex_shader_stmt.search(line):
		_handle_shader_statement(line)
		return false
	
	# label (skip during execution)
	regex_match = regex_label.search(line)
	if regex_match:
		return false
	
	# define (already processed in preparse, skip during execution)
	regex_match = regex_define.search(line)
	if regex_match:
		return false
	
	# say
	regex_match = regex_say.search(line)
	if regex_match:
		var char_id = regex_match.get_string("char_id")
		var message = regex_match.get_string("message")
		# v2新機能: インラインタグ処理は変数展開の前に行う
		# インラインタグ（{tag}）と変数展開（[var]）を区別
		# 注意: インラインタグ処理はUIManager/TypewriterTextで行うため、ここでは変数展開のみ
		message = variable_manager.expand_variables(message)
		
		var char_data = null
		if char_id:
			# v2: ArgodeSystemのCharDefsから定義を取得を試行
			var adv_system = get_node("/root/ArgodeSystem")
			if adv_system and adv_system.CharDefs and adv_system.CharDefs.has_character(char_id):
				char_data = adv_system.CharDefs.get_character_definition(char_id)
			else:
				# v1互換: VariableManagerからの取得
				char_data = variable_manager.get_character_data(char_id)
		
		# v2デバッグ: UIManager接続確認
		if ui_manager:
			print("💬 AdvScriptPlayer: Showing message via UIManager")
			ui_manager.show_message(char_data, message)
		else:
			print("❌ AdvScriptPlayer: ui_manager is null! Message cannot be displayed")
			print("❌ Message was: ", message)
		return true
	
	# set
	regex_match = regex_set.search(line)
	if regex_match:
		var var_name = regex_match.get_string("var_name")
		var expression = regex_match.get_string("expression")
		variable_manager.set_variable(var_name, expression)
		return false
	
	# jump
	regex_match = regex_jump.search(line)
	if regex_match:
		var label_name = regex_match.get_string("label")
		play_from_label(label_name)
		return true
	
	# call
	regex_match = regex_call.search(line)
	if regex_match:
		var label_name = regex_match.get_string("label")
		return _handle_call(label_name)
	
	# return
	regex_match = regex_return.search(line)
	if regex_match:
		return _handle_return()
	
	# if
	regex_match = regex_if.search(line)
	if regex_match:
		var condition = regex_match.get_string("condition")
		var result = variable_manager.evaluate_condition(condition)
		if not result:
			# Skip to else or next label/command
			_skip_to_else_or_end()
		return false
	
	# else
	regex_match = regex_else.search(line)
	if regex_match:
		# Skip else block (we only get here if the if was true)
		_skip_else_block()
		return false
	
	# menu
	regex_match = regex_menu.search(line)
	if regex_match:
		_handle_menu()
		return true
	
	# show
	regex_match = regex_show.search(line)
	if regex_match:
		var char_id = regex_match.get_string("target")
		var expression = regex_match.get_string("param1")
		var position = regex_match.get_string("position")
		var transition = regex_match.get_string("transition")
		
		# Set defaults
		if position.is_empty():
			position = "center"
		if transition.is_empty():
			transition = "none"
		if expression.is_empty():
			expression = "normal"
		
		# v2: LayerManagerを使用したキャラクター表示
		if layer_manager:
			var success = layer_manager.show_character(char_id, expression, position, transition)
			if not success:
				push_warning("⚠️ Failed to show character:", char_id)
		else:
			# フォールバック: 旧CharacterManager方式
			if character_manager:
				await character_manager.show_character(char_id, expression, position, transition)
		
		# Only wait for transition if it's not "none"
		return (transition != "none")
	
	# hide
	regex_match = regex_hide.search(line)
	if regex_match:
		var char_id = regex_match.get_string("char_id")
		var transition = regex_match.get_string("transition")
		
		if transition.is_empty():
			transition = "none"
		
		# v2: LayerManagerを使用したキャラクター非表示
		if layer_manager:
			var success = layer_manager.hide_character(char_id, transition)
			if not success:
				push_warning("⚠️ Failed to hide character:", char_id)
		else:
			# フォールバック: 旧CharacterManager方式
			if character_manager:
				await character_manager.hide_character(char_id, transition)
		
		# Only wait for transition if it's not "none"
		return (transition != "none")
	
	# scene
	regex_match = regex_scene.search(line)
	if regex_match:
		print("🔍 Scene regex matched line: '", line, "'")
		var scene_name = regex_match.get_string("scene_name").strip_edges()
		var transition = regex_match.get_string("transition")
		print("🎬 Parsed scene_name: '", scene_name, "', transition: '", transition, "'")
		
		if transition.is_empty():
			transition = "none"
			print("🔄 Empty transition, set to: ", transition)
		
		# v2: LayerManagerを使用した背景変更
		if layer_manager:
			var bg_path = ""
			
			# まずImageDefinitionManagerから画像定義を取得を試行
			var adv_system = get_node("/root/ArgodeSystem")
			if adv_system and adv_system.ImageDefs:
				bg_path = adv_system.ImageDefs.get_image_path(scene_name)
				print("🔍 ImageDefs lookup for '", scene_name, "': ", bg_path)
			
			# 定義が見つからない場合はデフォルトパス構築
			if bg_path.is_empty():
				bg_path = "res://assets/images/backgrounds/" + scene_name + ".jpg"
				print("🔍 Using default path construction: ", bg_path)
			
			var success = layer_manager.change_background(bg_path, transition)
			if not success:
				push_warning("⚠️ Failed to change background to:", scene_name)
		else:
			# フォールバック: 旧CharacterManager方式
			if character_manager:
				await character_manager.show_scene(scene_name, transition)
		
		# Only wait for transition if it's not "none"
		return (transition != "none")
	
	# call_screen (v2新機能)
	regex_match = regex_call_screen.search(line)
	if regex_match:
		var screen_path = regex_match.get_string("screen_path")
		var parameters_str = regex_match.get_string("parameters")
		
		print("📱 Calling screen: ", screen_path, " with params: ", parameters_str)
		
		# パラメータを辞書に変換（簡易実装）
		var parameters = _parse_screen_parameters(parameters_str)
		
		if ui_manager:
			await ui_manager.call_screen(screen_path, parameters)
		else:
			push_error("❌ UIManager not available for call_screen")
		
		return true
	
	# close_screen (v2新機能)
	regex_match = regex_close_screen.search(line)
	if regex_match:
		var return_value_str = regex_match.get_string("return_value")
		var return_value = null
		
		if not return_value_str.is_empty():
			return_value = _parse_return_value(return_value_str)
		
		print("📱 Closing current screen with return value: ", return_value)
		
		if ui_manager and ui_manager.current_screen:
			ui_manager.current_screen.close_screen(return_value)
		else:
			push_warning("⚠️ No current screen to close")
		
		return true
	
	# window (v2新機能: メッセージウィンドウ制御)
	regex_match = regex_window.search(line)
	if regex_match:
		var action = regex_match.get_string("action")
		var transition = regex_match.get_string("transition")
		print("🪟 Window control: ", action, " with transition: ", transition)
		
		if ui_manager:
			if transition and not transition.is_empty():
				# トランジション効果付きの場合は非同期処理
				await ui_manager.set_message_window_mode_with_transition(action, transition)
				return true  # トランジション完了まで待機
			else:
				# 即座に切り替え
				ui_manager.set_message_window_mode(action)
				return false
		else:
			push_warning("⚠️ UIManager not available for window control")
			return false
	
	# v2新機能: カスタムコマンドとしてシグナル発行を試行
	var custom_match = regex_custom_command.search(line)
	if custom_match:
		var command_name = custom_match.get_string("command")
		var parameters_str = custom_match.get_string("parameters")
		
		print("🔍 Custom command regex matched - command: '", command_name, "', params: '", parameters_str, "'")
		
		# 既知のコマンドはスキップ（重複処理を避ける）
		var known_commands = [
			"label", "say", "set", "if", "else", "menu", "jump", "call", "return",
			"show", "hide", "scene", "define", "character", "image", "audio", "shader",
			"call_screen", "close_screen", "window"
		]
		
		if command_name in known_commands:
			print("⚠️ Unknown syntax for known command: ", line)
			return false
		
		print("✅ Processing as custom command: ", command_name)
		
		# カスタムコマンドとして処理
		var parameters = _parse_custom_command_parameters(parameters_str)
		print("🎯 Custom command detected: '", command_name, "' with parameters: ", parameters)
		
		# 同期が必要なコマンドの場合は待機
		if _is_synchronous_command(command_name):
			print("⏳ [AdvScriptPlayer] Synchronous command detected: ", command_name, " - waiting for completion")
			var custom_handler = get_node("/root/ArgodeSystem").CustomCommandHandler
			if custom_handler:
				print("🔗 [AdvScriptPlayer] CustomCommandHandler found, connecting signal...")
				# シグナルを発行して完了を待機
				print("📡 [AdvScriptPlayer] Emitting custom_command_executed for: ", command_name)
				custom_command_executed.emit(command_name, parameters, line)
				print("⏳ [AdvScriptPlayer] Waiting for synchronous_command_completed signal...")
				
				# 特定のコマンド名でフィルタリングして待機
				var completed_command_name = ""
				while completed_command_name != command_name:
					completed_command_name = await custom_handler.synchronous_command_completed
					print("🔔 [AdvScriptPlayer] Got completion signal for: ", completed_command_name)
					if completed_command_name != command_name:
						print("⏳ [AdvScriptPlayer] Waiting for completion of '", command_name, "', but got '", completed_command_name, "'")
				
				print("✅ [AdvScriptPlayer] Synchronous command completed: ", command_name)
				return false
			else:
				print("❌ CustomCommandHandler not found - executing without sync")
		
		# 通常のカスタムコマンド
		print("📡 Emitting custom_command_executed signal for:", command_name)
		custom_command_executed.emit(command_name, parameters, line)
		print("📡 Signal emitted successfully")
		
		# デフォルトでは実行を停止しない（カスタムコマンドは非同期処理が多いため）
		return false
	
	print("⚠️ Unknown command: ", line)
	return false

func _handle_menu():
	var choices = []
	var choice_targets = []
	
	# Collect choices
	var temp_index = current_line_index
	while temp_index + 1 < script_lines.size():
		temp_index += 1
		var line = script_lines[temp_index]
		var line_trimmed = line.strip_edges()
		
		if line_trimmed.is_empty() or line_trimmed.begins_with("#"):
			continue
			
		var choice_match = regex_choice.search(line)
		if choice_match:
			var choice_text = choice_match.get_string(1)
			choices.append(choice_text)
			
			# Find the target after the colon
			temp_index += 1
			while temp_index < script_lines.size():
				var target_line = script_lines[temp_index]
				var target_trimmed = target_line.strip_edges()
				if not target_trimmed.is_empty() and not target_trimmed.begins_with("#"):
					choice_targets.append(temp_index - 1)
					break
				temp_index += 1
		else:
			# インデントレベルをチェックしてブロック終了を判定
			var indent_level = _get_indent_level(line)
			if indent_level == 0 and not line_trimmed.is_empty():
				break
	
	if choices.size() > 0:
		is_waiting_for_choice = true
		ui_manager.show_choices(choices)
	else:
		print("⚠️ No choices found for menu")

func on_choice_selected(choice_index: int):
	print("🔔 AdvScriptPlayer: Choice selected - index:", choice_index)
	is_waiting_for_choice = false
	
	# Find the target line for this choice
	var choices_found = 0
	var temp_index = current_line_index
	
	while temp_index + 1 < script_lines.size():
		temp_index += 1
		var line = script_lines[temp_index]
		var line_trimmed = line.strip_edges()
		
		if line_trimmed.is_empty() or line_trimmed.begins_with("#"):
			continue
		
		var choice_match = regex_choice.search(line)
		if choice_match:
			if choices_found == choice_index:
				print("🎯 Found target choice at line:", temp_index)
				# Find the first non-empty line after this choice
				temp_index += 1
				while temp_index < script_lines.size():
					var target_line = script_lines[temp_index]
					var target_trimmed = target_line.strip_edges()
					if not target_trimmed.is_empty() and not target_trimmed.begins_with("#"):
						current_line_index = temp_index - 1  # -1 because _tick() will increment
						print("🚀 Jumping to line:", current_line_index + 1, "->", target_trimmed)
						call_deferred("_tick")
						return
					temp_index += 1
				
				# If no valid line found after choice, end menu processing
				print("⚠️ No valid line found after choice")
				current_line_index = temp_index - 1
				call_deferred("_tick")
				return
			
			choices_found += 1
		else:
			# インデントレベルをチェックしてブロック終了を判定
			var indent_level = _get_indent_level(line)
			if indent_level == 0 and not line_trimmed.is_empty():
				print("📋 Menu block ended at line:", temp_index)
				break
	
	print("❌ Choice index", choice_index, "not found. Found", choices_found, "choices total.")

func _get_indent_level(line: String) -> int:
	"""行のインデントレベルを取得（スペース4個 or タブ1個 = レベル1）"""
	var indent = 0
	for i in range(line.length()):
		var c = line[i]
		if c == ' ':
			indent += 1
		elif c == '\t':
			indent += 4  # タブは4スペース相当
		else:
			break
	return indent / 4  # 4スペースで1レベル

func _skip_to_else_or_end():
	"""if文のelse節または終了まで行をスキップ（インデント考慮）"""
	var if_indent_level = _get_indent_level(script_lines[current_line_index])
	
	while current_line_index + 1 < script_lines.size():
		current_line_index += 1
		var line = script_lines[current_line_index]
		var line_trimmed = line.strip_edges()
		
		if line_trimmed.is_empty() or line_trimmed.begins_with("#"):
			continue
			
		var current_indent = _get_indent_level(line)
		
		# if文と同じインデントレベルでelse文が見つかった場合
		if current_indent == if_indent_level and regex_else.search(line):
			return
			
		# if文より浅いインデント（ブロック終了）
		if current_indent < if_indent_level:
			current_line_index -= 1
			return

func _skip_else_block():
	"""else文のブロックをスキップ（インデント考慮）"""
	var else_indent_level = _get_indent_level(script_lines[current_line_index])
	
	while current_line_index + 1 < script_lines.size():
		current_line_index += 1
		var line = script_lines[current_line_index]
		var line_trimmed = line.strip_edges()
		
		if line_trimmed.is_empty() or line_trimmed.begins_with("#"):
			continue
			
		var current_indent = _get_indent_level(line)
		
		# else文より浅いインデント（ブロック終了）
		if current_indent <= else_indent_level:
			current_line_index -= 1
			return

# === v2新機能: 定義ステートメントハンドラー ===

func _handle_character_statement(line: String):
	"""character ステートメントを処理"""
	# ArgodeSystemの CharDefs に委譲
	var adv_system = get_node("/root/ArgodeSystem")
	if adv_system and adv_system.CharDefs:
		adv_system.CharDefs.parse_character_statement(line)
	else:
		push_warning("⚠️ CharacterDefinitionManager not available")

func _handle_image_statement(line: String):
	"""image ステートメントを処理"""
	var adv_system = get_node("/root/ArgodeSystem")
	if adv_system and adv_system.ImageDefs:
		adv_system.ImageDefs.parse_image_statement(line)
	else:
		push_warning("⚠️ ImageDefinitionManager not available")

func _handle_audio_statement(line: String):
	"""audio ステートメントを処理"""
	var adv_system = get_node("/root/ArgodeSystem")
	if adv_system and adv_system.AudioDefs:
		adv_system.AudioDefs.parse_audio_statement(line)
	else:
		push_warning("⚠️ AudioDefinitionManager not available")

func _handle_shader_statement(line: String):
	"""shader ステートメントを処理"""
	var adv_system = get_node("/root/ArgodeSystem")
	if adv_system and adv_system.ShaderDefs:
		adv_system.ShaderDefs.parse_shader_statement(line)
	else:
		push_warning("⚠️ ShaderDefinitionManager not available")

# === v2新機能: スクリーン関連ヘルパーメソッド ===

func _parse_screen_parameters(parameters_str: String) -> Dictionary:
	"""スクリーンパラメータ文字列を辞書に変換"""
	var parameters = {}
	
	if parameters_str.is_empty():
		return parameters
	
	# key=value形式をパース（カンマ区切りまたはスペース区切り対応）
	var pairs = []
	
	# まずカンマ区切りを試行
	if "," in parameters_str:
		pairs = parameters_str.split(",")
	else:
		# スペース区切りでkey=value形式を抽出
		pairs = _parse_space_separated_key_values(parameters_str)
	
	for pair in pairs:
		pair = pair.strip_edges()
		if "=" in pair:
			var parts = pair.split("=", false, 1)
			if parts.size() == 2:
				var key = parts[0].strip_edges()
				var value_str = parts[1].strip_edges()
				parameters[key] = _parse_parameter_value(value_str)
	
	return parameters

func _parse_space_separated_key_values(parameters_str: String) -> Array:
	"""スペース区切りのkey=value形式を解析"""
	var pairs = []
	var tokens = _tokenize_parameters(parameters_str)
	
	for token in tokens:
		if "=" in str(token):
			pairs.append(str(token))
	
	return pairs

func _parse_parameter_value(value_str: String) -> Variant:
	"""パラメータ値を適切な型に変換"""
	value_str = value_str.strip_edges()
	
	# 文字列（クォートあり）
	if value_str.begins_with("\"") and value_str.ends_with("\""):
		return value_str.substr(1, value_str.length() - 2)
	
	# 数値
	if value_str.is_valid_float():
		if "." in value_str:
			return value_str.to_float()
		else:
			return value_str.to_int()
	
	# ブール値
	if value_str.to_lower() in ["true", "false"]:
		return value_str.to_lower() == "true"
	
	# その他は文字列として扱う
	return value_str

func _parse_return_value(return_value_str: String) -> Variant:
	"""リターン値文字列を適切な型に変換"""
	return _parse_parameter_value(return_value_str)

# === v2新機能: カスタムコマンド関連ヘルパーメソッド ===

func _parse_custom_command_parameters(parameters_str: String) -> Dictionary:
	"""カスタムコマンドパラメータ文字列を辞書に変換"""
	var parameters = {}
	
	if parameters_str.is_empty():
		return parameters
	
	# 複数の形式をサポート
	# 1. key=value, key2=value2 形式
	# 2. value1 value2 value3 形式（位置パラメータ）
	# 3. "quoted string" 形式
	
	parameters_str = parameters_str.strip_edges()
	
	# key=value形式をチェック
	if "=" in parameters_str:
		# 混合パラメータ（位置パラメータ + key=value）をサポート
		return _parse_mixed_parameters(parameters_str)
	else:
		# 位置パラメータまたは単純な値の配列として処理
		return _parse_positional_parameters(parameters_str)

func _parse_mixed_parameters(parameters_str: String) -> Dictionary:
	"""混合パラメータ（位置 + key=value）を解析"""
	var parameters = {}
	var tokens = _tokenize_parameters(parameters_str)
	var arg_index = 0
	
	for token in tokens:
		var token_str = str(token)
		if "=" in token_str:
			# key=value形式
			var parts = token_str.split("=", false, 1)
			if parts.size() == 2:
				var key = parts[0].strip_edges()
				var value_str = parts[1].strip_edges()
				parameters[key] = _parse_parameter_value(value_str)
		else:
			# 位置パラメータ
			parameters["arg" + str(arg_index)] = token
			parameters[arg_index] = token
			arg_index += 1
	
	parameters["_count"] = arg_index
	parameters["_raw"] = parameters_str
	
	return parameters

func _parse_positional_parameters(parameters_str: String) -> Dictionary:
	"""位置パラメータを解析"""
	var parameters = {}
	var tokens = _tokenize_parameters(parameters_str)
	
	for i in range(tokens.size()):
		parameters["arg" + str(i)] = tokens[i]
		parameters[i] = tokens[i]  # 数値インデックスでもアクセス可能
	
	parameters["_count"] = tokens.size()
	parameters["_raw"] = parameters_str
	
	return parameters

func _tokenize_parameters(text: String) -> Array:
	"""パラメータ文字列をトークンに分割（クォート対応）"""
	var tokens = []
	var current_token = ""
	var in_quotes = false
	var quote_char = ""
	
	for i in range(text.length()):
		var c = text[i]
		
		if not in_quotes:
			if c == '"' or c == "'":
				in_quotes = true
				quote_char = c
			elif c == ' ' or c == '\t':
				if not current_token.is_empty():
					tokens.append(_parse_parameter_value(current_token))
					current_token = ""
			else:
				current_token += c
		else:
			if c == quote_char:
				in_quotes = false
				tokens.append(current_token)
				current_token = ""
				quote_char = ""
			else:
				current_token += c
	
	# 最後のトークンを追加
	if not current_token.is_empty():
		tokens.append(_parse_parameter_value(current_token))
	
	return tokens

func _is_synchronous_command(command_name: String) -> bool:
	"""同期が必要なコマンドかどうかを判定"""
	print("🔍 [AdvScriptPlayer] Checking if '", command_name, "' is synchronous...")
	
	# CustomCommandHandlerに登録されているコマンドから判定
	var custom_handler = get_node("/root/ArgodeSystem").CustomCommandHandler
	if custom_handler and custom_handler.registered_commands.has(command_name):
		var command = custom_handler.registered_commands[command_name] as BaseCustomCommand
		var is_sync = command.is_synchronous()
		print("🔍 [AdvScriptPlayer] Command '", command_name, "' found in CustomCommandHandler, is_synchronous: ", is_sync)
		return is_sync
	
	# フォールバック：既知の同期コマンド
	var synchronous_commands = ["wait"]
	var is_fallback_sync = command_name in synchronous_commands
	print("🔍 [AdvScriptPlayer] Command '", command_name, "' using fallback check, is_synchronous: ", is_fallback_sync)
	return is_fallback_sync

# === Call/Return 処理メソッド ===

func _handle_call(label_name: String) -> bool:
	"""call コマンドの処理（クロスファイル対応）"""
	# 次の行を保存（戻ってきたときの継続ポイント）
	var return_line = current_line_index + 1
	
	# 現在のファイル情報を保存
	call_stack.append({
		"line": return_line,
		"script_lines": script_lines.duplicate(),  # 現在のスクリプト内容を保存
		"label_map": label_map.duplicate(),        # 現在のラベルマップを保存
		"file_info": "current_script"              # 将来的にファイルパスを保存
	})
	
	print("📞 CALL DEBUG: Calling label '", label_name, "' from line ", current_line_index + 1)
	print("📞 CALL DEBUG: Will return to line ", return_line + 1, " (", script_lines[return_line] if return_line < script_lines.size() else "EOF", ")")
	print("📚 CALL DEBUG: Call stack depth: ", call_stack.size())
	print("📁 CALL DEBUG: Saved current script with ", script_lines.size(), " lines and ", label_map.size(), " labels")
	
	# 指定されたラベルに移動
	play_from_label(label_name)
	return true  # 実行を停止（ラベルジャンプのため）

func _handle_return() -> bool:
	"""return コマンドの処理（クロスファイル対応）"""
	if call_stack.size() > 0:
		var return_info = call_stack.pop_back()
		var return_line = return_info["line"]
		
		print("🔙 RETURN DEBUG: Returning from call stack")
		
		# 保存されたスクリプト情報があるかチェック
		if return_info.has("script_lines") and return_info.has("label_map"):
			print("🔙 RETURN DEBUG: Restoring previous script context")
			# 元のスクリプトコンテキストを復元
			script_lines = return_info["script_lines"]
			label_map = return_info["label_map"]
			print("� RETURN DEBUG: Restored script with ", script_lines.size(), " lines and ", label_map.size(), " labels")
		
		print("�🔙 RETURN DEBUG: Return line: ", return_line, " (", script_lines[return_line] if return_line < script_lines.size() else "EOF", ")")
		print("🔙 RETURN DEBUG: Remaining stack depth: ", call_stack.size())
		
		# 戻り先の行に移動（-1しておくことで、_tick()の+1と合わせて正確な行に到達）
		current_line_index = return_line - 1
		print("🔙 RETURN DEBUG: Set current_line_index to: ", current_line_index)
		
		# 実行状態をリセット
		is_playing = true
		is_waiting_for_choice = false
		
		return false  # 実行を継続（戻った行から処理を続ける）
	else:
		print("ℹ️ return called with empty call stack (likely from jump command)")
		print("🛑 No call to return from - stopping script execution")
		is_playing = false
		return true  # 実行を停止

# === 公開API for ArgodeUIScene ===

func call_label(label_name: String):
	"""外部からラベルをcall（ArgodeUIScene用）"""
	print("📞 [ArgodeScriptPlayer] External call to label:", label_name)
	_handle_call(label_name)

func return_from_call():
	"""外部からreturn（ArgodeUIScene用）"""
	print("↩️ [ArgodeScriptPlayer] External return from call")
	_handle_return()