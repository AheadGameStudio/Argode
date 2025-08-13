@tool
extends BaseCustomCommand

func _init():
	super._init()
	command_name = "textspeed"
	description = "テキスト表示速度の調整を行うコマンド"
	help_text = """textspeed [speed]
	
speed: テキスト速度 (0.1-5.0, 省略時は現在値を表示)
  - 1.0: 通常速度
  - 2.0: 2倍速
  - 0.5: 半分の速度

例:
  textspeed        - 現在の速度を表示
  textspeed 1.5    - 1.5倍速に設定
  textspeed 0.8    - 0.8倍速に設定"""

func execute(parameters: Dictionary, adv_system: Node) -> void:
	var args = parameters.get("args", [])
	var save_manager = adv_system.get_manager("save_load")
	
	if not save_manager:
		log_error("SaveLoadManagerが見つかりません")
		return
	
	# 引数なしの場合は現在値を表示
	if args.size() == 0:
		var current_speed = save_manager.get_text_speed()
		print("📝 現在のテキスト速度: " + "%.1f" % current_speed + "倍速")
		return
	
	# 速度設定
	var speed_str = args[0]
	if not speed_str.is_valid_float():
		log_error("速度は0.1から5.0の数値で指定してください")
		return
	
	var speed = speed_str.to_float()
	if speed < 0.1 or speed > 5.0:
		log_error("速度は0.1から5.0の範囲で指定してください")
		return
	
	if save_manager.set_text_speed(speed):
		print("✅ テキスト速度を " + "%.1f" % speed + "倍速に設定しました")
	else:
		log_error("テキスト速度の設定に失敗しました")
