# AudioTag.gd
# オーディオ制御用のカスタムタグ
@tool
extends "res://addons/argode/builtin/tags/BaseCustomTag.gd"


func get_tag_name() -> String:
	return "audio"

func get_description() -> String:
	return "オーディオ（BGM/SE）を制御します"

func get_tag_type():
	return 3  # InlineTagProcessor.TagType.CUSTOM

func get_tag_properties() -> Dictionary:
	return {
		"execution_timing": "PRE_VARIABLE"
	}

func process_tag(tag_name: String, parameters: Dictionary, adv_system):
	"""
	タグパラメータを処理してオーディオコマンドを実行
	例: {audio=bgm:play:res://audio/bgm.ogg:fade:2.0}
	"""
	print("🎵 [AudioTag] Processing tag: ", tag_name, " with params: ", parameters)
	
	var param_value = parameters.get("value", "")
	if param_value.is_empty():
		push_error("AudioTag: パラメータが指定されていません")
		return
	
	# コロン区切りでパラメータを解析
	var parts = param_value.split(":")
	if parts.size() < 2:
		push_error("AudioTag: 無効なパラメータ形式: " + param_value)
		return

	var audio_type = parts[0].strip_edges()  # bgm/se
	var action = parts[1].strip_edges()      # play/stop/volume

	# オーディオコマンド文字列を構築
	var command_str = "audio " + audio_type + " " + action

	# アクションに応じてパラメータを追加
	match action:
		"play":
			if parts.size() >= 3:
				var file_param = parts[2].strip_edges()
				# ファイルIDかパスかを判定
				if file_param.begins_with("res://"):
					command_str += " " + file_param
				else:
					# オーディオ定義IDとして扱う
					command_str += " " + file_param
				# 追加オプションを処理
				for i in range(3, parts.size()):
					var param = parts[i].strip_edges()
					if param == "loop":
						command_str += " loop"
					elif param == "fade" and i + 1 < parts.size():
						command_str += " fade=" + parts[i + 1].strip_edges()
					elif param.is_valid_int() or param.is_valid_float():
						# 音量として扱う
						command_str += " volume=" + param
		
		"stop":
			# フェードアウトオプション
			for i in range(2, parts.size()):
				var stop_param = parts[i].strip_edges()
				if stop_param == "fade" and i + 1 < parts.size():
					command_str += " fade=" + parts[i + 1].strip_edges()
		
		"volume":
			if parts.size() >= 3:
				command_str += " " + parts[2].strip_edges()

	print("🎵 [AudioTag] Generated command: ", command_str)

	# CustomCommandHandlerのシグナル発行システムを使って直接audioコマンドを実行
	print("📻 [AudioTag] Generated command: ", command_str)

	# adv_systemからArgodeSystemを取得
	var argode_system = null
	if adv_system and adv_system.has_method("get_node"):
		argode_system = adv_system.get_node("/root/ArgodeSystem")
	
	if not argode_system:
		# シングルトン経由でアクセス
		argode_system = ArgodeSystem
	
	if argode_system and argode_system.has_method("get_custom_command_handler"):
		var custom_handler = argode_system.get_custom_command_handler()
		if custom_handler and custom_handler.has_method("_on_custom_command_executed"):
			# コマンド文字列を解析してパラメータに変換
			var cmd_parts = command_str.strip_edges().split(" ")
			if cmd_parts.size() >= 3:  # audio, type, action
				var cmd_name = cmd_parts[1]  # "audio"のスキップ、実際はaudioコマンド
				
				# _rawパラメータ用の文字列を手動で構築
				var raw_parts = []
				for i in range(1, cmd_parts.size()):
					raw_parts.append(cmd_parts[i])
				var raw_string = " ".join(raw_parts)
				
				var cmd_params = {
					"arg0": cmd_parts[1],  # bgm/se
					"arg1": cmd_parts[2],  # play/stop
					"_raw": raw_string,
					"_count": cmd_parts.size() - 1
				}
				
				# 追加パラメータを処理
				for i in range(3, cmd_parts.size()):
					var key = "arg" + str(i-1)
					cmd_params[key] = cmd_parts[i]
					cmd_params[i-1] = cmd_parts[i]
					cmd_params["_count"] = i
				
				# CustomCommandHandlerのシグナル発行システムを直接呼び出し
				custom_handler._on_custom_command_executed("audio", cmd_params, command_str)
				print("✅ [AudioTag] Audio command executed via CustomCommandHandler")
			else:
				push_error("AudioTag: Invalid command format: " + command_str)
		else:
			push_error("AudioTag: CustomCommandHandler._on_custom_command_executed not found")
	else:
		push_error("AudioTag: ArgodeSystem.get_custom_command_handler not found")

func get_help_text() -> String:
	return """AudioTag使用例:
	# {audio=bgm:play:res://audio/bgm.ogg:fade:2.0}  - BGMをフェードイン再生
	# {audio=se:play:res://audio/se.ogg:100}         - SEを音量100%で再生
	# {audio=bgm:stop:fade:1.0}                      - BGMをフェードアウト停止
	# {audio=bgm:volume:50}                           - BGM音量を50%に設定"""
