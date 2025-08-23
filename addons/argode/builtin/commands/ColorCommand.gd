extends ArgodeCommandBase
class_name ColorCommand

func _ready():
	command_class_name = "ColorCommand"
	command_execute_name = "color"
	is_also_tag = true
	has_end_tag = true
	tag_name = "color"
	is_decoration_command = true  # 装飾コマンドとして認識
	command_description = "テキストの色を変更します"
	command_help = "{color=#ff0000}文字色を変更したいテキスト{/color}の形式で使用します"

func execute(args: Dictionary) -> void:
	var is_closing_tag = args.has("_closing") and args["_closing"]
	
	if is_closing_tag:
		# 終了タグの処理
		ArgodeSystem.log("🎨 ColorCommand: Closing tag processed")
	else:
		# 開始タグの処理
		var color_value = ""
		if args.has("color"):
			color_value = args["color"]
		elif args.has("value"):
			color_value = args["value"]
		ArgodeSystem.log("🎨 ColorCommand: Opening tag processed with color: %s" % color_value)
