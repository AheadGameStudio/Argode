extends ArgodeCommand
class_name TextSpeedCommand

func get_command_name() -> String:
	return "textspeed"

func get_command_description() -> String:
	return "テキスト表示速度の調整を行うコマンド"

func get_usage() -> String:
	return """textspeed [speed]
	
speed: テキスト速度 (0.1-5.0, 省略時は現在値を表示)
  - 1.0: 通常速度
  - 2.0: 2倍速
  - 0.5: 半分の速度

例:
  textspeed        - 現在の速度を表示
  textspeed 1.5    - 1.5倍速に設定
  textspeed 0.8    - 0.8倍速に設定"""

func get_argument_definition() -> Array[String]:
	return ["speed?"]

func execute(args: Array) -> int:
	var save_manager = ArgodeSystem.get_manager("save_load")
	if not save_manager:
		error("SaveLoadManagerが見つかりません")
		return COMMAND_ERROR
	
	# 引数なしの場合は現在値を表示
	if args.size() == 0:
		var current_speed = save_manager.get_text_speed()
		print("📝 現在のテキスト速度: " + "%.1f" % current_speed + "倍速")
		return COMMAND_SUCCESS
	
	# 速度設定
	var speed_str = args[0]
	if not speed_str.is_valid_float():
		error("速度は0.1から5.0の数値で指定してください")
		return COMMAND_ERROR
	
	var speed = speed_str.to_float()
	if speed < 0.1 or speed > 5.0:
		error("速度は0.1から5.0の範囲で指定してください")
		return COMMAND_ERROR
	
	if save_manager.set_text_speed(speed):
		print("✅ テキスト速度を " + "%.1f" % speed + "倍速に設定しました")
		return COMMAND_SUCCESS
	else:
		error("テキスト速度の設定に失敗しました")
		return COMMAND_ERROR
