extends ArgodeCommandBase
class_name MoveCommand

## 移動エフェクト用インラインコマンド
## 使用例: {move=10,5,0.5}テキスト{/move}

func _ready():
	command_class_name = "MoveCommand"
	command_execute_name = "move"
	is_also_tag = true
	has_end_tag = true
	tag_name = "move"
	is_decoration_command = true  # 装飾コマンドとして認識
	command_description = "テキストに移動エフェクトを適用します"
	command_help = "{move=X移動量,Y移動量,時間}移動させたいテキスト{/move}の形式で使用します"

func execute(args: Dictionary) -> void:
	var is_closing_tag = args.has("_closing") and args["_closing"]
	
	if is_closing_tag:
		# 終了タグの処理
		ArgodeSystem.log("🎨 MoveCommand: Closing tag processed")
		_notify_glyph_system("move_end", {})
	else:
		# 開始タグの処理
		var move_value = ""
		if args.has("move"):
			move_value = args["move"]
		elif args.has("value"):
			move_value = args["value"]
		
		ArgodeSystem.log("🎨 MoveCommand: Opening tag processed with move: %s" % move_value)
		_notify_glyph_system("move_start", {"move": move_value})

func _notify_glyph_system(action: String, params: Dictionary):
	"""GlyphSystemにエフェクト通知を送信"""
	var message_renderer = ArgodeSystem.get_manager("UIManager").get_current_message_renderer()
	if message_renderer and message_renderer.has_method("handle_decoration_command"):
		var command_data = {
			"command": "move",
			"action": action,
			"parameters": params
		}
		message_renderer.handle_decoration_command(command_data)
		ArgodeSystem.log_workflow("🎨 MoveCommand: Notified GlyphSystem with %s" % action)
