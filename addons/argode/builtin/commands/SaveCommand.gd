# SaveCommand.gd
# save コマンド実装 - ゲームをセーブする
@tool
class_name BuiltinSaveCommand
extends BaseCustomCommand

func _init():
	command_name = "save"
	description = "Save game to specified slot"
	help_text = "save [slot] [save_name]\nSave game to slot (0-9). Optional save_name for custom name."

func execute(params: Dictionary, adv_system: Node) -> void:
	print("💾 [save] Executing save command with params:", params)
	
	# 引数解析
	var slot = params.get("slot", 0)
	var save_name = params.get("save_name", "")
	
	# スロット番号を文字列から整数に変換
	if typeof(slot) == TYPE_STRING:
		if slot.is_valid_int():
			slot = slot.to_int()
		else:
			push_error("❌ [save] Invalid slot number: " + str(slot))
			return
	
	# スロット番号検証
	if slot < 0 or slot >= 10:
		push_error("❌ [save] Slot number must be between 0-9")
		return
	
	print("💾 [save] Saving to slot " + str(slot) + ((" with name: " + save_name) if save_name != "" else ""))
	
	var success = adv_system.save_game(slot, save_name)
	if success:
		print("✅ [save] Game saved successfully to slot " + str(slot))
	else:
		push_error("❌ [save] Failed to save game")
