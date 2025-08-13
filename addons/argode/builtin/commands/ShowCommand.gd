# ShowCommand.gd
# show コマンド実装 - Ren'Pyスタイルのキャラクター立ち絵表示
@tool
class_name BuiltinShowCommand
extends BaseCustomCommand

func _init():
	command_name = "show"
	description = "Show character sprites"
	help_text = """show <character> [expression] [at <position>] [with <transition>]

Examples:
- show aya normal
- show aya happy at left
- show akane normal at right with fadein
- show aya sad at center with movein_left

Ren'Py Style:
- show aya normal        # aya_normal.png
- show aya happy         # aya_happy.png

Legacy Style (compatible):
- show aya_normal        # same as above

Positions: left, center, right, far_left, far_right
Transitions: fadein, movein_left, movein_right, none (default)"""

	# パラメータ定義
	set_parameter_info("character", "string", true, "", "Character name (e.g., aya)")
	set_parameter_info("expression", "string", false, "normal", "Character expression (e.g., normal, happy, sad)")
	set_parameter_info("position", "string", false, "center", "Position on screen")
	set_parameter_info("transition", "string", false, "none", "Transition effect")

func execute(params: Dictionary, adv_system: Node) -> void:
	# Ren'Pyスタイル構文解析: "show character [expression] [at position] [with transition]"
	var raw_params = params.get("_raw", "")
	print("🎭 ShowCommand: Raw params: '", raw_params, "'")
	
	var character_name = ""
	var expression = "normal"
	var position = "center"
	var transition = "none"
	
	if raw_params.is_empty():
		# Dictionary形式の場合のフォールバック
		var legacy_character_id = get_param_value(params, "character_id", -1, "")
		if legacy_character_id.is_empty():
			legacy_character_id = get_param_value(params, "character", -1, "")
		
		position = get_param_value(params, "position", -1, "center") 
		transition = get_param_value(params, "transition", -1, "none")
		expression = get_param_value(params, "expression", -1, "normal")
		
		# legacy_character_idを分解
		if legacy_character_id.contains("_"):
			var parts = legacy_character_id.split("_", false, 1)
			character_name = parts[0]
			if parts.size() > 1:
				expression = parts[1]
		else:
			character_name = legacy_character_id
	else:
		# Ren'Pyスタイル構文解析: "show aya normal at left with fadein"
		var parts = raw_params.split(" ", false)
		if parts.size() == 0:
			log_error("No character specified")
			return
		
		character_name = parts[0]
		
		# 2番目のパラメータがexpressionかキーワード("at"/"with")かを判定
		var current_index = 1
		if current_index < parts.size() and parts[current_index] != "at" and parts[current_index] != "with":
			expression = parts[current_index]
			current_index += 1
		
		# "at position"を探す
		while current_index < parts.size():
			if parts[current_index] == "at" and current_index + 1 < parts.size():
				position = parts[current_index + 1]
				current_index += 2
			elif parts[current_index] == "with" and current_index + 1 < parts.size():
				transition = parts[current_index + 1]
				current_index += 2
			else:
				current_index += 1
	
	# 引数チェック
	if character_name.is_empty():
		log_error("No character name specified")
		return
	
	print("🎭 ShowCommand: Showing character '", character_name, "' expression '", expression, "' at '", position, "' with transition '", transition, "'")
	
	# 互換性のためcharacter_idを構築
	var character_id = character_name + "_" + expression
	
	# CharacterManagerを取得
	var character_manager = adv_system.CharacterManager
	if not character_manager:
		log_error("CharacterManager not found")
		return

	# Ren'Pyスタイル: まず完全一致、次にベースキャラクターをチェック
	var is_char_defined = false
	if character_manager.is_character_defined(character_id):
		# 完全一致（従来の aya_normal 定義）
		is_char_defined = true
		print("🎭 Found exact character definition: ", character_id)
	elif character_manager.is_character_defined(character_name):
		# ベースキャラクター定義（新しい aya + normal 自動検出）
		is_char_defined = true
		print("🎭 Found base character definition: ", character_name, " with expression: ", expression)
	
	if not is_char_defined:
		log_error("Character not defined: " + character_id + " (tried both '" + character_id + "' and base '" + character_name + "')")
		return

	print("🎭 Parsed: char_name='", character_name, "', expression='", expression, "'")
	
	# キャラクターを表示
	character_manager.show_character(character_name, expression, position, transition)
