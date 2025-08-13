# LoadCommand.gd
# load コマンド実装 - ゲームをロードする
@tool
class_name BuiltinLoadCommand
extends BaseCustomCommand

func _init():
	command_name = "load"
	description = "Load game from specified slot"
	help_text = "load [slot]\nLoad game from slot (0-9)."

func execute(params: Dictionary, adv_system: Node) -> void:
	print("📂 [load] Executing load command with params:", params)
	
	# 引数解析
	var slot = params.get("slot", 0)
	
	# スロット番号を文字列から整数に変換
	if typeof(slot) == TYPE_STRING:
		if slot.is_valid_int():
			slot = slot.to_int()
		else:
			push_error("❌ [load] Invalid slot number: " + str(slot))
			return
	
	# スロット番号検証
	if slot < 0 or slot >= 10:
		push_error("❌ [load] Slot number must be between 0-9")
		return
	
	print("📂 [load] Loading from slot " + str(slot))
	
	var success = adv_system.load_game(slot)
	if success:
		print("✅ [load] Game loaded successfully from slot " + str(slot))
	else:
		push_error("❌ [load] Failed to load game from slot " + str(slot))
