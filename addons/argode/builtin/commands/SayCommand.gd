extends ArgodeCommandBase
class_name SayCommand

func _ready():
	command_class_name = "SayCommand"
	command_execute_name = "say"
	command_description = "キャラクターのセリフまたはナレーションを表示します"
	command_help = "say [キャラクター名] メッセージ"

## 引数検証
func validate_args(args: Dictionary) -> bool:
	# 最低限1つの引数が必要（メッセージテキスト）
	if not args.has("0"):
		log_error("メッセージテキストが指定されていません")
		return false
	return true

## Universal Block Execution対応のコマンド中核処理
func execute_core(args: Dictionary) -> void:
	log_info("SayCommand execute_core started with args: %s" % str(args))
	
	var character_name = get_optional_arg(args, "0", "")
	var message_text = get_optional_arg(args, "1", "")
	
	# "1"がない場合、"0"がメッセージテキスト
	if not args.has("1"):
		message_text = character_name
		character_name = ""
	
	log_info("SayCommand parsed - character: '%s', message: '%s'" % [character_name, message_text])
	
	# Universal Block Execution: 直接UIManagerを使用（メッセージウィンドウ自動作成）
	var ui_manager = get_ui_manager()  # ヘルパー関数使用
	if not ui_manager:
		return
	
	log_info("SayCommand calling UIManager.show_message (auto-create window)")
	await ui_manager.show_message_with_auto_create(message_text, character_name)
	log_info("メッセージ表示: キャラクター='%s', テキスト='%s'" % [character_name, message_text])
	
	# オートプレイ対応の統一入力待ち
	await wait_for_input_with_autoplay()  # ヘルパー関数使用
