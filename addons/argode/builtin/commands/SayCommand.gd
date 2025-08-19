extends ArgodeCommandBase
class_name SayCommand

func _ready():
	command_class_name = "SayCommand"
	command_execute_name = "say"
	command_description = "キャラクターのセリフまたはナレーションを表示します"
	command_help = "say [キャラクター名] メッセージ"

## 引数検証（Stage 3共通基盤）
func validate_args(args: Dictionary) -> bool:
	# Sayコマンドは最低限1つの引数（メッセージ）が必要
	if not args.has("arg0"):
		log_error("メッセージが指定されていません")
		return false
	return true

## コマンド中核処理（Stage 3共通基盤）
func execute_core(args: Dictionary) -> void:
	var character_name = get_optional_arg(args, "arg0", "")
	var message_text = get_optional_arg(args, "arg1", "")
	
	# arg1がない場合、arg0がメッセージテキスト
	if not args.has("arg1"):
		message_text = character_name
		character_name = ""
	
	log_info("Say実行: [%s] %s" % [character_name, message_text])
	
	# 実際の表示処理はStatementManagerに委譲される
