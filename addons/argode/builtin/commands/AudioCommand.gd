extends ArgodeCommandBase
class_name AudioCommand

func _ready():
	command_class_name = "AudioCommand"
	command_execute_name = "audio"
	is_also_tag = true
	tag_name = "audio"
