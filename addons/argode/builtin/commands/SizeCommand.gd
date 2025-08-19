extends ArgodeCommandBase
class_name SizeCommand

func _ready():
	command_class_name = "SizeCommand"
	command_execute_name = "size"
	is_also_tag = true
	has_end_tag = true
	tag_name = "size"
	command_description = "テキストのサイズを変更します"
	command_help = "{size=24}大きな文字{/size} または {size=12}小さな文字{/size}の形式で使用します"

func execute(args: Dictionary) -> void:
	var is_closing_tag = args.has("_closing") and args["_closing"]
	
	if is_closing_tag:
		# 終了タグの処理
		ArgodeSystem.log("📏 SizeCommand: Closing tag processed")
	else:
		# 開始タグの処理
		var size_value = ""
		if args.has("size"):
			size_value = args["size"]
		elif args.has("value"):
			size_value = args["value"]
		ArgodeSystem.log("📏 SizeCommand: Opening tag processed with size: %s" % size_value)
