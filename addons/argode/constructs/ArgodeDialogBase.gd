extends ArgodeViewBase
class_name ArgodeDialogBase

signal button_pressed(_value: Dictionary)
@export_node_path var buttons_container_path:NodePath
var buttons_container: BoxContainer # VboxContainer/HBoxContainer

func _ready():
	if buttons_container_path == null:
		ArgodeSystem.log("⚠️ Buttons container path is not set.")
		return
	
	buttons_container = get_node(buttons_container_path)