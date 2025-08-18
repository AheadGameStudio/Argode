extends ArgodeCommandBase
class_name ImageCommand

func _ready():
	command_class_name = "ImageCommand"
	command_execute_name = "image"
	is_define_command = true
