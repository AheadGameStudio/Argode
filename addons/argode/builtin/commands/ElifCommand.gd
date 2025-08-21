extends ArgodeCommandBase
class_name ElifCommand

func _ready():
	command_class_name = "ElifCommand"
	command_execute_name = "elif"
	command_description = "else if条件を処理します（IfCommandによって管理されます）"
	command_help = "elif条件は単独では使用せず、if文のブロック内で使用されます"

## 引数検証
func validate_args(args: Dictionary) -> bool:
	# elifは通常IfCommandによって管理されるため、単独実行されることはない
	log_warning("ElifCommand was called independently - this should be handled by IfCommand")
	return true

## コマンド中核処理
func execute_core(args: Dictionary) -> void:
	# elifは実際にはIfCommandによって処理されるため、ここでは何もしない
	log_info("ElifCommand: This command is managed by IfCommand")