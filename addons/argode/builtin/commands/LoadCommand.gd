# LoadCommand.gd
# load コマンド実装 - ゲームをロードする
@tool
class_name BuiltinLoadCommand
extends BaseCustomCommand

func _init():
	command_name = "load"
	description = "Load game from specified slot"
	help_text = "load [slot]\nLoad game from slot. Use 0 for auto-save or 1+ for manual saves."

func execute(params: Dictionary, adv_system: Node) -> void:
	print("📂 [load] Executing load command with params:", params)
	
	# 引数解析
	var slot = params.get("slot", 1)  # デフォルトを1に
	
	# スロット番号を文字列から整数に変換
	if typeof(slot) == TYPE_STRING:
		if slot.is_valid_int():
			slot = slot.to_int()
		else:
			push_error("❌ [load] Invalid slot number: " + str(slot))
			return
	
	# SaveLoadManagerから最大スロット数を取得
	var save_manager = adv_system.SaveLoadManager
	if not save_manager:
		push_error("❌ [load] SaveLoadManager not found")
		return
	
	# スロット番号検証（オートセーブ含む）
	if not save_manager.is_valid_save_slot(slot):
		var max_user_slots = save_manager.get_user_save_slots()
		push_error("❌ [load] Slot number must be between 0 (auto-save) or 1-" + str(max_user_slots))
		return
	
	# スロット種別の表示
	var slot_type = "auto-save" if slot == 0 else "manual save"
	print("📂 [load] Loading " + slot_type + " from slot " + str(slot))
	
	var success = save_manager.load_game(slot)
	if success:
		print("✅ [load] Game loaded successfully from slot " + str(slot) + " (" + slot_type + ")")
	else:
		push_error("❌ [load] Failed to load game from slot " + str(slot))
