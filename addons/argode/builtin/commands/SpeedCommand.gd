extends ArgodeCommandBase
class_name SpeedCommand

func _ready():
	command_class_name = "SpeedCommand"
	command_execute_name = "speed"
	is_also_tag = true
	tag_name = "speed"  # {speed=0.02}のように使用
	command_description = "テキスト表示速度を一時的に変更"
	command_help = "{speed=0.02}高速表示テキスト{/speed} または {speed=0.1}低速表示テキスト{/speed}"

func execute(args: Dictionary) -> void:
	var new_speed: float = 0.02
	var is_closing_tag: bool = false
	
	# 終了タグかチェック
	if args.has("/speed") or args.has("_closing"):
		is_closing_tag = true
	
	if is_closing_tag:
		# 終了タグ: 速度を復元
		pop_typewriter_speed()
		ArgodeSystem.log("📋 SpeedCommand: Speed restored to previous value")
	else:
		# 開始タグ: 新しい速度を設定
		if args.has("speed"):
			new_speed = float(args["speed"])
		elif args.has("0"):  # 無名引数として渡された場合
			new_speed = float(args["0"])
		
		var current_speed = get_current_typewriter_speed()
		push_typewriter_speed(new_speed)
		ArgodeSystem.log("⚡ SpeedCommand: Speed changed from %.3f to %.3f" % [current_speed, new_speed])
