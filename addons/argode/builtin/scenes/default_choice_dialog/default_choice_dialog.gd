extends ArgodeDialogBase
class_name ArgodeDefaultChoiceDialog

@export_node_path var choice_container_path
var choice_container:Control

@export_category("Theme Variation")
@export var choice_button_theme_variation: String = "ChoiceButton"

var _vbox:VBoxContainer
var choices: Array[String]:
	set(value):
		clear_choices()
		choices = value
		for choice in choices:
			add_choice_button(choice)

func _ready() -> void:
	if choice_container_path == null:
		ArgodeSystem.log("❌ Choice container path is not set.", ArgodeSystem.DebugManager.LogLevel.ERROR)
		return

	choice_container = get_node_or_null(choice_container_path)

	if choice_container == null:
		ArgodeSystem.log("❌ Choice container node not found at path: %s" % choice_container_path, ArgodeSystem.DebugManager.LogLevel.ERROR)
		return

	if choice_container.get_child(0) is VBoxContainer:
		_vbox = choice_container.get_child(0)
	else:
		# VboxContainerが存在しない場合は新規に作成
		_vbox = VBoxContainer.new()
		choice_container.add_child(_vbox)

	# choices = ["テスト1", "テスト2", "テスト3"]  # 初期選択肢

func add_choice_button(text: String):
	var button = Button.new()
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.theme_type_variation = choice_button_theme_variation
	button.text = text
	_vbox.add_child(button)

func _on_choice_button_pressed(_button:Button):
	var _context:Dictionary = {
		"id": choices.find(_button.text), 
		"message": _button.text
		}
	ArgodeSystem.log("📚Choice button pressed: %s" % _context)
	emit_signal("button_pressed", _context)

func clear_choices():
	choices.clear()
	# 既存の選択肢をすべて削除
	for child in _vbox.get_children():
		_vbox.remove_child(child)
		child.queue_free()  # メモリを解放
