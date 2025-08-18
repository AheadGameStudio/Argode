extends ArgodeCommandBase
class_name SetCommand

func _ready():
	command_class_name = "SetCommand"
	command_execute_name = "set"
	is_define_command = true
