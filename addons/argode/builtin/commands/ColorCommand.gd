extends ArgodeCommandBase
class_name ColorCommand

func _ready():
	command_class_name = "ColorCommand"
	command_execute_name = "color"
	tag_name = "color"
	is_decoration_command = true  # 装飾コマンド→自動的にペアタグ有効化
	command_description = "テキストの色を変更します"
	command_help = "{color=#ff0000}文字色を変更したいテキスト{/color}の形式で使用します"

func execute(args: Dictionary) -> void:
	var is_closing_tag = args.has("_closing") and args["_closing"]
	
	if is_closing_tag:
		# 終了タグの処理
		ArgodeSystem.log("🎨 ColorCommand: Closing tag processed")
		_notify_glyph_system("color_end", {})
	else:
		# 開始タグの処理
		var color_value = ""
		if args.has("color"):
			color_value = args["color"]
		elif args.has("value"):
			color_value = args["value"]
		
		ArgodeSystem.log("🎨 ColorCommand: Opening tag processed with color: %s" % color_value)
		_notify_glyph_system("color_start", {"color": color_value})

func _notify_glyph_system(action: String, params: Dictionary):
	"""GlyphSystemにエフェクト通知を送信"""
	var message_renderer = ArgodeSystem.get_manager("UIManager").get_current_message_renderer()
	if message_renderer and message_renderer.has_method("handle_decoration_command"):
		var command_data = {
			"command": "color",
			"action": action,
			"parameters": params
		}
		message_renderer.handle_decoration_command(command_data)
		ArgodeSystem.log_workflow("🎨 ColorCommand: Notified GlyphSystem with %s" % action)
