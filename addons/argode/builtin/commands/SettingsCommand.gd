extends ArgodeCommand
class_name SettingsCommand

func get_command_name() -> String:
	return "settings"

func get_command_description() -> String:
	return "ゲーム設定の変更・取得を行うコマンド"

func get_usage() -> String:
	return """settings <action> [category] [key] [value]
	
アクション:
  get <category> <key>         - 設定値を取得して表示
  set <category> <key> <value> - 設定値を変更
  reset                        - 全設定をデフォルトに戻す
  save                         - 現在の設定を保存
  load                         - 設定を再読み込み
  print                        - 全設定をコンソールに出力

例:
  settings get audio master_volume
  settings set audio bgm_volume 0.7
  settings set text text_speed 1.5
  settings reset"""

func get_argument_definition() -> Array[String]:
	return ["action", "category?", "key?", "value?"]

func execute(args: Array) -> int:
	if args.size() < 1:
		error("使用法: " + get_usage())
		return COMMAND_ERROR
	
	var action = args[0].to_lower()
	var save_manager = ArgodeSystem.get_manager("save_load")
	
	if not save_manager:
		error("SaveLoadManagerが見つかりません")
		return COMMAND_ERROR
	
	match action:
		"get":
			return _handle_get_setting(args, save_manager)
		"set":
			return _handle_set_setting(args, save_manager)
		"reset":
			return _handle_reset_settings(save_manager)
		"save":
			return _handle_save_settings(save_manager)
		"load":
			return _handle_load_settings(save_manager)
		"print":
			return _handle_print_settings(save_manager)
		_:
			error("不明なアクション: " + action)
			return COMMAND_ERROR

func _handle_get_setting(args: Array, save_manager: SaveLoadManager) -> int:
	if args.size() < 3:
		error("使用法: settings get <category> <key>")
		return COMMAND_ERROR
	
	var category = args[1]
	var key = args[2]
	var value = save_manager.get_setting(category, key, "未設定")
	
	print("⚙️ " + category + "." + key + " = " + str(value))
	return COMMAND_SUCCESS

func _handle_set_setting(args: Array, save_manager: SaveLoadManager) -> int:
	if args.size() < 4:
		error("使用法: settings set <category> <key> <value>")
		return COMMAND_ERROR
	
	var category = args[1]
	var key = args[2]
	var value_str = args[3]
	
	# 値の型を推測して変換
	var value = _parse_value(value_str)
	
	if save_manager.apply_setting(category, key, value):
		print("✅ " + category + "." + key + " を " + str(value) + " に設定しました")
		return COMMAND_SUCCESS
	else:
		error("設定の保存に失敗しました")
		return COMMAND_ERROR

func _handle_reset_settings(save_manager: SaveLoadManager) -> int:
	save_manager.reset_settings_to_default()
	print("✅ 全ての設定をデフォルトに戻しました")
	return COMMAND_SUCCESS

func _handle_save_settings(save_manager: SaveLoadManager) -> int:
	if save_manager.save_settings():
		print("✅ 設定を保存しました")
		return COMMAND_SUCCESS
	else:
		error("設定の保存に失敗しました")
		return COMMAND_ERROR

func _handle_load_settings(save_manager: SaveLoadManager) -> int:
	if save_manager.load_settings():
		print("✅ 設定を再読み込みしました")
		return COMMAND_SUCCESS
	else:
		error("設定の読み込みに失敗しました")
		return COMMAND_ERROR

func _handle_print_settings(save_manager: SaveLoadManager) -> int:
	save_manager.print_current_settings()
	return COMMAND_SUCCESS

func _parse_value(value_str: String):
	"""文字列から適切な型の値に変換"""
	# 真偽値
	if value_str.to_lower() in ["true", "yes", "on", "1"]:
		return true
	elif value_str.to_lower() in ["false", "no", "off", "0"]:
		return false
	
	# 数値（浮動小数点）
	if value_str.is_valid_float():
		return value_str.to_float()
	
	# 数値（整数）
	if value_str.is_valid_int():
		return value_str.to_int()
	
	# 文字列（そのまま）
	return value_str
