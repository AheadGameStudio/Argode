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

## コマンド中核処理
func execute_core(args: Dictionary) -> void:
	log_info("SayCommand execute_core started with args: %s" % str(args))
	
	var character_name = get_optional_arg(args, "0", "")
	var message_text = get_optional_arg(args, "1", "")
	
	# "1"がない場合、"0"がメッセージテキスト
	if not args.has("1"):
		message_text = character_name
		character_name = ""
	
	log_info("SayCommand parsed - character: '%s', message: '%s'" % [character_name, message_text])
	
	# StatementManagerを通じてメッセージを表示
	var statement_manager = args.get("statement_manager")
	if statement_manager and statement_manager.has_method("show_message_via_service"):
		log_info("SayCommand calling show_message_via_service (Phase 1 Step 1-1B)")
		statement_manager.show_message_via_service(message_text, character_name)
		log_info("メッセージ表示: キャラクター='%s', テキスト='%s'" % [character_name, message_text])
		
		# ExecutionServiceの入力待ち状態を設定
		var execution_service = statement_manager.execution_service
		if execution_service:
			var is_auto_play = ArgodeSystem.is_auto_play_mode()
			log_info("SayCommand: Auto-play mode check: %s" % is_auto_play)
			
			if is_auto_play:
				log_info("SayCommand: AUTO-PLAY MODE - スキップして自動進行")
				# ヘッドレスモードでは少し待ってから自動進行
				await Engine.get_main_loop().create_timer(0.1).timeout
			else:
				# 通常モードでは入力待ち
				execution_service.set_waiting_for_input(true)
				log_info("SayCommand: 入力待ち状態に設定しました")
		
	elif statement_manager and statement_manager.has_method("show_message"):
		log_info("SayCommand calling show_message (fallback)")
		statement_manager.show_message(message_text, character_name)
		log_info("メッセージ表示: キャラクター='%s', テキスト='%s'" % [character_name, message_text])
		
		# ExecutionServiceの入力待ち状態を設定（フォールバック時も同様処理）
		var execution_service = statement_manager.execution_service
		if execution_service:
			var is_auto_play = ArgodeSystem.is_auto_play_mode()
			if is_auto_play:
				await Engine.get_main_loop().create_timer(0.1).timeout
			else:
				execution_service.set_waiting_for_input(true)
		
	else:
		log_error("StatementManagerのメッセージ表示メソッドが見つかりません")
