extends ArgodeCommandBase
class_name CharacterCommand

func _ready():
	command_class_name = "CharacterCommand"
	command_execute_name = "character"
	is_define_command = true