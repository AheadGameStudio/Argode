extends ArgodeCommand
class_name VolumeCommand

func get_command_name() -> String:
	return "volume"

func get_command_description() -> String:
	return "音量の調整を行うコマンド"

func get_usage() -> String:
	return """volume [type] [value]
	
type (省略可):
  master  - マスターボリューム (0.0-1.0)
  bgm     - BGMボリューム (0.0-1.0) 
  se      - SE音量 (0.0-1.0)
  voice   - ボイス音量 (0.0-1.0)

value: 音量値 (0.0-1.0, 省略時は現在値を表示)

例:
  volume              - 全音量を表示
  volume master       - マスター音量を表示
  volume bgm 0.7      - BGM音量を0.7に設定
  volume master 0.8   - マスター音量を0.8に設定"""

func get_argument_definition() -> Array[String]:
	return ["type?", "value?"]

func execute(args: Array) -> int:
	var save_manager = ArgodeSystem.get_manager("save_load")
	if not save_manager:
		error("SaveLoadManagerが見つかりません")
		return COMMAND_ERROR
	
	# 引数なしの場合は全音量を表示
	if args.size() == 0:
		return _show_all_volumes(save_manager)
	
	var type = args[0].to_lower()
	
	# 音量値の指定なしの場合は現在値を表示
	if args.size() == 1:
		return _show_volume(save_manager, type)
	
	# 音量設定
	var value_str = args[1]
	if not value_str.is_valid_float():
		error("音量値は0.0から1.0の数値で指定してください")
		return COMMAND_ERROR
	
	var volume = value_str.to_float()
	if volume < 0.0 or volume > 1.0:
		error("音量値は0.0から1.0の範囲で指定してください")
		return COMMAND_ERROR
	
	return _set_volume(save_manager, type, volume)

func _show_all_volumes(save_manager: SaveLoadManager) -> int:
	print("🔊 === 現在の音量設定 ===")
	print("  マスター: " + "%.1f" % save_manager.get_master_volume())
	print("  BGM:     " + "%.1f" % save_manager.get_bgm_volume()) 
	print("  SE:      " + "%.1f" % save_manager.get_se_volume())
	print("  ボイス:   " + "%.1f" % save_manager.get_setting("audio", "voice_volume", 1.0))
	return COMMAND_SUCCESS

func _show_volume(save_manager: SaveLoadManager, type: String) -> int:
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
			error("不明な音量タイプ: " + type)
			return COMMAND_ERROR
	
	print("🔊 " + name + "音量: " + "%.1f" % volume)
	return COMMAND_SUCCESS

func _set_volume(save_manager: SaveLoadManager, type: String, volume: float) -> int:
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
			error("不明な音量タイプ: " + type)
			return COMMAND_ERROR
	
	if success:
		print("✅ " + name + "音量を " + "%.1f" % volume + " に設定しました")
		return COMMAND_SUCCESS
	else:
		error(name + "音量の設定に失敗しました")
		return COMMAND_ERROR
