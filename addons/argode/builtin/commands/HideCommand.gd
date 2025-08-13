# HideCommand.gd
# hide コマンド実装 - Ren'Pyスタイルのキャラクター非表示
@tool
class_name BuiltinHideCommand
extends BaseCustomCommand

func _init():
	command_name = "hide"
	description = "Hide character sprites"
	help_text = """hide <character> [with <transition>]

Examples:
- hide aya
- hide aya with fadeout
- hide akane with moveout_right

Transitions: fadeout, moveout_left, moveout_right, none (default)"""

	# パラメータ定義
	set_parameter_info("character", "string", true, "", "Character name to hide")
	set_parameter_info("transition", "string", false, "none", "Transition effect")

func execute(params: Dictionary, adv_system: Node) -> void:
	# 構文解析: "hide character [with transition]"
	var raw_params = params.get("_raw", "")
	print("🎭 HideCommand: Raw params: '", raw_params, "'")
	
	var character_name = ""
	var transition = "none"
	
	if raw_params.is_empty():
		# Dictionary形式の場合
		character_name = get_param_value(params, "character", -1, "")
		transition = get_param_value(params, "transition", -1, "none")
	else:
		# 構文解析: "hide aya with fadeout"
		var parts = raw_params.split(" ", false)
		if parts.size() == 0:
			log_error("No character specified")
			return
		
		character_name = parts[0]
		
		# "with transition"を探す
		var current_index = 1
		while current_index < parts.size():
			if parts[current_index] == "with" and current_index + 1 < parts.size():
				transition = parts[current_index + 1]
				current_index += 2
			else:
				current_index += 1
	
	# 引数チェック
	if character_name.is_empty():
		log_error("No character name specified")
		return
	
	print("🎭 HideCommand: Hiding character '", character_name, "' with transition '", transition, "'")
	
	# CharacterManagerを取得
	var character_manager = adv_system.CharacterManager
	if not character_manager:
		log_error("CharacterManager not found")
		return
	
	# キャラクターを非表示
	character_manager.hide_character(character_name, transition)
