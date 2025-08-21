extends ArgodeCommandBase
class_name ElseCommand

func _ready():
	command_class_name = "ElseCommand"
	command_execute_name = "else"
	command_description = "else条件を処理します（IfCommandによって管理されます）"
	command_help = "else条件は単独では使用せず、if文のブロック内で使用されます"

## 引数検証
func validate_args(args: Dictionary) -> bool:
	# elseは通常IfCommandによって管理されるため、単独実行されることはない
	log_warning("ElseCommand was called independently - this should be handled by IfCommand")
	return true

## コマンド中核処理
func execute_core(args: Dictionary) -> void:
	# elseは実際にはIfCommandによって処理されるため、ここでは何もしない
	log_info("ElseCommand: This command is managed by IfCommand")