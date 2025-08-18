extends ArgodeCommandBase
class_name CharacterDefinePositionCommand

func _ready():
	command_class_name = "CharacterDefinePositionCommand"
	command_execute_name = "character_define_position"
	is_define_command = true
