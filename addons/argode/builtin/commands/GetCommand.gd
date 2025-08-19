extends ArgodeCommandBase
class_name GetCommand

func _ready():
	command_class_name = "GetCommand"
	command_execute_name = "get"
	is_also_tag = true
	tag_name = "get"  # 変数表示用のタグとしても使用