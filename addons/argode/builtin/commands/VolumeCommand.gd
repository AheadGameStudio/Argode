@tool
extends BaseCustomCommand

func _init():
	super._init()
	command_name = "volume"
	description = "音量の調整を行うコマンド"
	help_text = """volume [type] [value]
	
type (省略可):
  master  - マスターボリューム (0.0-1.0)
  bgm     - BGMボリューム (0.0-1.0) 
  se      - SE音量 (0.0-1.0)
  voice   - ボイス音量 (0.0-1.0)

value: 音量値 (0.0-1.0, 省略時は現在値を表示)

例:
  volume              - 全音量を表示
  volume master       - マスター音量を表示
  volume bgm 0.7      - BGM音量を0.7に設定"""

func execute(parameters: Dictionary, adv_system: Node) -> void:
	var args = parameters.get("args", [])
	var save_manager = adv_system.get_manager("save_load")
	
	if not save_manager:
		log_error("SaveLoadManagerが見つかりません")
		return
	
	# 引数なしの場合は全音量を表示
	if args.size() == 0:
		_show_all_volumes(save_manager)
		return
	
	var type = args[0].to_lower()
	
	# 音量値の指定なしの場合は現在値を表示
	if args.size() == 1:
		_show_volume(save_manager, type)
		return
	
	# 音量設定
	var value_str = args[1]
	if not value_str.is_valid_float():
		log_error("音量値は0.0から1.0の数値で指定してください")
		return
	
	var volume = value_str.to_float()
	if volume < 0.0 or volume > 1.0:
		log_error("音量値は0.0から1.0の範囲で指定してください")
		return
	
	_set_volume(save_manager, type, volume)

func _show_all_volumes(save_manager: Node):
	print("🔊 === 現在の音量設定 ===")
	print("  マスター: " + "%.1f" % save_manager.get_master_volume())
	print("  BGM:     " + "%.1f" % save_manager.get_bgm_volume()) 
	print("  SE:      " + "%.1f" % save_manager.get_se_volume())
	print("  ボイス:   " + "%.1f" % save_manager.get_setting("audio", "voice_volume", 1.0))

func _show_volume(save_manager: Node, type: String):
	var volume: float
	var name: String
	
	match type:
		"master":
			volume = save_manager.get_master_volume()
			name = "マスター"
		"bgm":
			volume = save_manager.get_bgm_volume()
			name = "BGM"
		"se":
			volume = save_manager.get_se_volume()
			name = "SE"
		"voice":
			volume = save_manager.get_setting("audio", "voice_volume", 1.0)
			name = "ボイス"
		_:
			log_error("不明な音量タイプ: " + type)
			return
	
	print("🔊 " + name + "音量: " + "%.1f" % volume)

func _set_volume(save_manager: Node, type: String, volume: float):
	var success = false
	var name: String
	
	match type:
		"master":
			success = save_manager.set_master_volume(volume)
			name = "マスター"
		"bgm":
			success = save_manager.set_bgm_volume(volume)
			name = "BGM"
		"se":
			success = save_manager.set_se_volume(volume)
			name = "SE"
		"voice":
			success = save_manager.apply_setting("audio", "voice_volume", volume)
			name = "ボイス"
		_:
			log_error("不明な音量タイプ: " + type)
			return
	
	if success:
		print("✅ " + name + "音量を " + "%.1f" % volume + " に設定しました")
	else:
		log_error(name + "音量の設定に失敗しました")
