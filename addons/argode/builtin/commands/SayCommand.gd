extends ArgodeCommandBase
class_name SayCommand

func _ready():
	command_class_name = "SayCommand"
	command_execute_name = "say"
	command_description = "キャラクターのセリフまたはナレーションを表示します"
	command_help = "say [キャラクター名] メッセージ"

func execute(args: Dictionary) -> void:
	# SayCommandは基本的な実行ログのみ
	var character_name = args.get("arg0", "")
	var message_text = args.get("arg1", "")
	
	# arg1がない場合、arg0がメッセージテキスト
	if not args.has("arg1"):
		message_text = character_name
		character_name = ""
	
	ArgodeSystem.log("💬 Say command executed: [%s] %s" % [character_name, message_text])
	
	# 実際の表示処理はStatementManagerに委譲される
