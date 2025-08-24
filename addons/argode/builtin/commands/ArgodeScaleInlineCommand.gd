extends ArgodeCommandBase
class_name ScaleCommand

## スケールエフェクト用インラインコマンド
## 使用例: {scale=1.5,0.3}テキスト{/scale}

func _ready():
	command_class_name = "ScaleCommand"
	command_execute_name = "scale"
	tag_name = "scale"
	is_decoration_command = true  # 装飾コマンド→自動的にペアタグ有効化
	command_description = "テキストにスケールエフェクトを適用します"
	command_help = "{scale=スケール値,時間}拡大縮小したいテキスト{/scale}の形式で使用します"

func execute(args: Dictionary) -> void:
	var is_closing_tag = args.has("_closing") and args["_closing"]
	
	if is_closing_tag:
		# 終了タグの処理
		ArgodeSystem.log("🎨 ScaleCommand: Closing tag processed")
		_notify_glyph_system("scale_end", {})
	else:
		# 開始タグの処理
		var scale_value = ""
		if args.has("scale"):
			scale_value = args["scale"]
		elif args.has("value"):
			scale_value = args["value"]
		
		ArgodeSystem.log("🎨 ScaleCommand: Opening tag processed with scale: %s" % scale_value)
		_notify_glyph_system("scale_start", {"scale": scale_value})

func _notify_glyph_system(action: String, params: Dictionary):
	"""GlyphSystemにエフェクト通知を送信"""
	var message_renderer = ArgodeSystem.get_manager("UIManager").get_current_message_renderer()
	if message_renderer and message_renderer.has_method("handle_decoration_command"):
		var command_data = {
			"command": "scale",
			"action": action,
			"parameters": params
		}
		message_renderer.handle_decoration_command(command_data)
		ArgodeSystem.log_workflow("🎨 ScaleCommand: Notified GlyphSystem with %s" % action)
