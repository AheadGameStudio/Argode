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
	
	# Universal Block Execution: 直接UIManagerにメッセージ表示を依頼
	var ui_manager = ArgodeSystem.UIManager
	if not ui_manager:
		log_error("UIManager not available")
		return
	
	log_info("SayCommand calling UIManager.show_message directly")
	ui_manager.show_message(character_name, message_text)
	log_info("メッセージ表示: キャラクター='%s', テキスト='%s'" % [character_name, message_text])
	
	# 入力待ちの処理
	var is_auto_play = ArgodeSystem.is_auto_play_mode()
	log_info("SayCommand: Auto-play mode check: %s" % is_auto_play)
	
	if is_auto_play:
		log_info("SayCommand: AUTO-PLAY MODE - スキップして自動進行")
		# ヘッドレスモードでは少し待ってから自動進行
		await Engine.get_main_loop().create_timer(0.1).timeout
	else:
		# 通常モードでは入力待ち
		log_info("SayCommand: Waiting for user input")
		await ui_manager.wait_for_input()
		log_info("SayCommand: User input received, continuing")
