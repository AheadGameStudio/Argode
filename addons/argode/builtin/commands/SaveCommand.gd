# SaveCommand.gd
# save コマンド実装 - ゲームをセーブする
@tool
class_name BuiltinSaveCommand
extends BaseCustomCommand

func _init():
	command_name = "save"
	description = "Save game to specified slot"
	help_text = "save [slot] [save_name]\nSave game to slot (1+). Slot 0 is reserved for auto-save. Optional save_name for custom name."

func execute(params: Dictionary, adv_system: Node) -> void:
	print("💾 [save] Executing save command with params:", params)
	
	# 引数解析
	var slot = params.get("slot", 1)  # デフォルトを1に（0はオートセーブ専用）
	var save_name = params.get("save_name", "")
	
	# スロット番号を文字列から整数に変換
	if typeof(slot) == TYPE_STRING:
		if slot.is_valid_int():
			slot = slot.to_int()
		else:
			push_error("❌ [save] Invalid slot number: " + str(slot))
			return
	
	# SaveLoadManagerから最大スロット数を取得
	var save_manager = adv_system.SaveLoadManager
	if not save_manager:
		push_error("❌ [save] SaveLoadManager not found")
		return
	
	# スロット番号検証（オートセーブスロット0は除く）
	if slot == 0:
		push_error("❌ [save] Slot 0 is reserved for auto-save. Use slots 1 and up for manual saves.")
		return
	
	if not save_manager.is_valid_save_slot(slot):
		var max_user_slots = save_manager.get_user_save_slots()
		push_error("❌ [save] Slot number must be between 1-" + str(max_user_slots))
		return
	
	print("💾 [save] Saving to slot " + str(slot) + ((" with name: " + save_name) if save_name != "" else ""))
	
	var success = save_manager.save_game(slot, save_name)
	if success:
		print("✅ [save] Game saved successfully to slot " + str(slot))
	else:
		push_error("❌ [save] Failed to save game")
