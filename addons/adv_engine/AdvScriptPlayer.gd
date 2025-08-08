extends Node

signal script_finished

var script_lines: PackedStringArray = []
var label_map: Dictionary = {}
var call_stack: Array[Dictionary] = []
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

var variable_manager: Node
var ui_manager: Node
var script_manager: Node
var label_registry: Node

func _ready():
	_compile_regex()
	variable_manager = get_node("/root/VariableManager")
	ui_manager = get_node("/root/UIManager")
	
	# LabelRegistryをautoloadから取得
	label_registry = get_node_or_null("/root/LabelRegistry")
	if label_registry:
		print("✅ LabelRegistry connected")
	else:
		print("⚠️ LabelRegistry not found - cross-file jumps disabled")
	
	print("📖 AdvScriptPlayer initialized")

func _compile_regex():
	regex_label = RegEx.new()
	regex_label.compile("^label\\s+(?<name>\\w+):")
	
	regex_say = RegEx.new()
	regex_say.compile("^(?:(?<char_id>\\w+)\\s+)?\"(?<message>.*)\"")
	
	regex_set = RegEx.new()
	regex_set.compile("^set\\s+(?<var_name>\\w+)\\s*=\\s*(?<expression>.+)")
	
	regex_if = RegEx.new()
	regex_if.compile("^if\\s+(?<condition>.+):")
	
	regex_menu = RegEx.new()
	regex_menu.compile("^menu:")
	
	regex_jump = RegEx.new()
	regex_jump.compile("^jump\\s+(?<label>\\w+)")
	
	regex_call = RegEx.new()
	regex_call.compile("^call\\s+(?<label>\\w+)")
	
	regex_show = RegEx.new()
	regex_show.compile("^show\\s+(?<char_id>\\w+)\\s+(?<expression>\\w+)(?:\\s+at\\s+(?<position>\\w+))?(?:\\s+with\\s+(?<transition>\\w+))?")
	
	regex_scene = RegEx.new()
	regex_scene.compile("^scene\\s+(?<scene_name>\\w+)(?:\\s+with\\s+(?<transition>\\w+))?")
	
	regex_define = RegEx.new()
	regex_define.compile("^define\\s+(?<id>\\w+)\\s*=\\s*Character\\(\"(?<resource_path>[^\"]+)\"\\)")
	
	regex_return = RegEx.new()
	regex_return.compile("^return")
	
	regex_else = RegEx.new()
	regex_else.compile("^else:")
	
	regex_choice = RegEx.new()
	regex_choice.compile("^\\s+\"([^\"]+)\":\\s*$")
	
	regex_hide = RegEx.new()
	regex_hide.compile("^hide\\s+(?<char_id>\\w+)(?:\\s+with\\s+(?<transition>\\w+))?")
	
	regex_jump_file = RegEx.new()
	regex_jump_file.compile("^jump_to\\s+(?<filename>[\\w.]+)\\s+(?<label>\\w+)")

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
			variable_manager.set_character_def(char_id, resource_path)
	
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
		message = variable_manager.expand_variables(message)
		
		var char_data = null
		if char_id:
			char_data = variable_manager.get_character_data(char_id)
		
		ui_manager.show_message(char_data, message)
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
		call_stack.append({"line": current_line_index})
		play_from_label(label_name)
		return true
	
	# return
	regex_match = regex_return.search(line)
	if regex_match:
		if call_stack.size() > 0:
			var return_info = call_stack.pop_back()
			current_line_index = return_info["line"]
			print("🔙 Returning to line: ", current_line_index + 1)
			return false  # Continue execution from return point
		else:
			push_warning("⚠️ return called with empty call stack")
			is_playing = false
			return true
	
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
		var char_id = regex_match.get_string("char_id")
		var expression = regex_match.get_string("expression")
		var position = regex_match.get_string("position")
		var transition = regex_match.get_string("transition")
		
		# Set defaults
		if position.is_empty():
			position = "center"
		if transition.is_empty():
			transition = "none"
		
		var character_manager = get_node("/root/CharacterManager")
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
		
		var character_manager = get_node("/root/CharacterManager")
		if character_manager:
			await character_manager.hide_character(char_id, transition)
		
		# Only wait for transition if it's not "none"
		return (transition != "none")
	
	# scene
	regex_match = regex_scene.search(line)
	if regex_match:
		print("🔍 Scene regex matched line: '", line, "'")
		var scene_name = regex_match.get_string("scene_name")
		var transition = regex_match.get_string("transition")
		print("🎬 Parsed scene_name: '", scene_name, "', transition: '", transition, "'")
		
		if transition.is_empty():
			transition = "none"
			print("🔄 Empty transition, set to: ", transition)
		
		var character_manager = get_node("/root/CharacterManager")
		if character_manager:
			await character_manager.show_scene(scene_name, transition)
		
		# Only wait for transition if it's not "none"
		return (transition != "none")
	
	print("⚠️ Unknown command: ", line)
	return false

func _skip_to_else_or_end():
	var depth = 1
	while current_line_index + 1 < script_lines.size():
		current_line_index += 1
		var line = script_lines[current_line_index].strip_edges()
		
		if line.is_empty() or line.begins_with("#"):
			continue
		
		if regex_if.search(line):
			depth += 1
		elif regex_else.search(line) and depth == 1:
			return  # Found matching else
		elif regex_label.search(line):
			current_line_index -= 1  # Back up one line
			return

func _skip_else_block():
	while current_line_index + 1 < script_lines.size():
		current_line_index += 1
		var line = script_lines[current_line_index].strip_edges()
		
		if line.is_empty() or line.begins_with("#"):
			continue
		
		if regex_label.search(line):
			current_line_index -= 1  # Back up one line
			return

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
				var target_line = script_lines[temp_index].strip_edges()
				if not target_line.is_empty() and not target_line.begins_with("#"):
					choice_targets.append(temp_index - 1)
					break
				temp_index += 1
		else:
			# No more choices, but check if it's indented content
			if not line.begins_with("    ") and not line.begins_with("\t"):
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
			var choice_text = choice_match.get_string(1)
			print("🔍 Found choice #", choices_found, ": '", choice_text, "'")
			if choices_found == choice_index:
				print("✅ Matched selected choice:", choice_index)
				# Skip to the action line (like "jump increase_score")
				temp_index += 1
				while temp_index < script_lines.size():
					var action_line = script_lines[temp_index].strip_edges()
					if not action_line.is_empty() and not action_line.begins_with("#"):
						print("🎯 Executing action:", action_line)
						current_line_index = temp_index - 1  # Set to line before action
						_tick()  # This will process the action line
						return
					temp_index += 1
				return
			choices_found += 1
		else:
			# Check if we've moved beyond the menu block
			if not line.begins_with("    ") and not line.begins_with("\t"):
				break
	
	print("⚠️ Choice index out of range: ", choice_index)