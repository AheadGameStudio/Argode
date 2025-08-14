extends CanvasLayer
class_name ArgodeDebugScreen

@onready var console_vbox:VBoxContainer = %ConsoleVBox
@onready var input_line:LineEdit = %InputLine
@onready var send_button:Button = %SendButton
@onready var scroll_container:ScrollContainer = %ScrollContainer

var _line_focused:bool = false
var _line_mouse_entered:bool = false

func _ready():
	print("📺 [ArgodeDebugScreen] ready")
	visible = false
	input_line.mouse_exited.connect(_on_input_line_mouse_exited)
	input_line.mouse_entered.connect(_on_input_line_mouse_entered)
	input_line.focus_entered.connect(_on_input_line_focus_entered)
	input_line.focus_exited.connect(_on_input_line_focus_exited)
	send_button.pressed.connect(_on_send_button_pressed)

func _on_input_line_focus_entered():
	# print("📺 [ArgodeDebugScreen] Input line focus entered")
	_line_focused = true

func _on_input_line_focus_exited():
	# print("📺 [ArgodeDebugScreen] Input line focus exited")
	_line_focused = false

func _on_input_line_mouse_entered():
	# print("📺 [ArgodeDebugScreen] Input line mouse entered")
	_line_mouse_entered = true

func _on_input_line_mouse_exited():
	# print("📺 [ArgodeDebugScreen] Input line mouse exited")
	_line_mouse_entered = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_F3:
			visible = not visible

	if not visible:
		return  # 画面が非表示の場合は何もしない
	
	if event is InputEventKey:
		if not _line_focused:
			input_line.grab_focus()
		if input_line.text != "" and event.keycode == KEY_ENTER:
			# Enterキーで送信
			_on_send_button_pressed()
			input_line.grab_focus()
		# if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# 	# マウスクリックでフォーカスを外す
		# 	if not _line_mouse_entered and not _line_focused:
		# 		input_line.release_focus()

func _on_send_button_pressed():
	var text = input_line.text.strip_edges()
	if text.begins_with("/"):
		# コマンド判定
		_handle_command(text)
	else:
		_add_text_to_console("> " + text)
	input_line.clear()
	await get_tree().create_timer(0.01).timeout
	scroll_container.set_deferred("scroll_vertical", console_vbox.size.y)
	if console_vbox.get_child_count() >= 2048:
		console_vbox.remove_child(console_vbox.get_child(0))
	
	input_line.grab_focus()

func _add_text_to_console(message:Variant):
	if message != "":
		var label:RichTextLabel = RichTextLabel.new()
		label.bbcode_enabled = true
		label.fit_content = true
		label.text = str(message)
		label.set_autowrap_mode(TextServer.AUTOWRAP_WORD_SMART)
		console_vbox.add_child(label)
		return OK


func _handle_command(cmd_text: String):
	# 例: /vars で変数一覧表示
	if cmd_text == "/vars":
		var vars:Dictionary = ArgodeSystem.VariableManager.get_all_variables()
		_add_text_to_console("[変数一覧]")
		if vars.size() == 0:
			_add_text_to_console("  変数はありません")
		for _key in vars:
			_add_text_to_console(str(_key) + " : " + str(vars[_key]))
			await get_tree().create_timer(0.01).timeout
	elif cmd_text == "/settings":
		_add_text_to_console("[設定一覧]")
		var settings:Dictionary = ArgodeSystem.SaveLoadManager.export_settings()
		for _key in settings:
			_add_text_to_console(str(_key) + " : " + str(settings[_key]))
			await get_tree().create_timer(0.01).timeout
	elif cmd_text == "/clear":
		for child in console_vbox.get_children():
			console_vbox.remove_child(child)
	else:
		_add_text_to_console("[コマンド未対応] " + cmd_text)
