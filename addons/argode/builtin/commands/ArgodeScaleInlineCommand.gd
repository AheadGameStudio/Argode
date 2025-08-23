extends ArgodeCommandBase
class_name ScaleCommand

## スケールエフェクト用インラインコマンド
## 使用例: {scale=1.5,0.3}テキスト{/scale}

func _ready():
	command_class_name = "ScaleCommand"
	command_execute_name = "scale"
	is_also_tag = true
	has_end_tag = true
	tag_name = "scale"
	is_decoration_command = true  # 装飾コマンドとして認識
	command_description = "テキストにスケールエフェクトを適用します"
	command_help = "{scale=スケール値,時間}拡大縮小したいテキスト{/scale}の形式で使用します"

func execute(args: Dictionary) -> void:
	var is_closing_tag = args.has("_closing") and args["_closing"]
	
	if is_closing_tag:
		# 終了タグの処理
		ArgodeSystem.log("🎨 ScaleCommand: Closing tag processed")
	else:
		# 開始タグの処理
		var scale_value = ""
		if args.has("scale"):
			scale_value = args["scale"]
		elif args.has("value"):
			scale_value = args["value"]
		ArgodeSystem.log("🎨 ScaleCommand: Opening tag processed with scale: %s" % scale_value)
