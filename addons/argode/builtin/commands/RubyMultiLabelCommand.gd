# RubyMultiLabelCommand.gd
# 複数Label方式でルビ表示を行うカスタムコマンド
@tool
extends BaseCustomCommand

func get_command_name() -> String:
	return "ruby_multi_label"

func get_description() -> String:
	return "複数Label方式でルビ付きメッセージを表示"

func get_usage() -> String:
	return "ruby_multi_label <character_name> <message_with_ruby>"

# func execute(args: Array, adv_system) -> bool:
# 	if args.size() < 2:
# 		push_error("ruby_multi_label: 引数が不足しています。使用法: " + get_usage())
# 		return false
	
# 	var character_name = args[0]
# 	var message = args[1]
	
# 	# キャラクター名が"none"の場合は空文字に
# 	if character_name.to_lower() == "none":
# 		character_name = ""
	
# 	print("🏷️ [ruby_multi_label] Showing message with multi-label ruby system")
# 	print("   Character: ", character_name)
# 	print("   Message: ", message)
	
# 	# UIManagerを通してメッセージ表示（ArgodeScreenのshow_messageを呼び出し）
# 	var ui_manager = adv_system.UIManager
# 	if ui_manager and ui_manager.current_screen:
# 		var current_screen = ui_manager.current_screen
# 		if current_screen.has_method("show_message"):
# 			# 第4引数でmulti-label方式を指定
# 			current_screen.show_message(character_name, message, Color.WHITE, true)
# 			return true
# 		else:
# 			push_error("ruby_multi_label: current_screen doesn't have show_message method")
# 			return false
# 	else:
# 		push_error("ruby_multi_label: UIManager or current_screen not available")
# 		return false
