# AudioCommand.gd
# オーディオ再生制御のためのカスタムコマンド
@tool
class_name BuiltinAudioCommand
extends BaseCustomCommand

func _init():
	command_name = "audio"
	description = "オーディオ（BGM/SE）を制御します"
	help_text = "audio bgm play <name> [loop] [volume=100] | audio se play <name> [volume=100]"
	
	set_parameter_info("subcommand", "string", true, "", "bgm/se のいずれか")
	set_parameter_info("action", "string", true, "", "play/stop/volume のいずれか")
	set_parameter_info("audio_name", "string", false, "", "オーディオ名またはエイリアス")

func execute(params: Dictionary, adv_system: Node) -> void:
	"""同期実行"""
	var raw_params = params.get("_raw", "")
	var args = _parse_raw_params(raw_params)
	
	# "audio" コマンド名自体を除去
	if args.size() > 0 and args[0].to_lower() == "audio":
		args = args.slice(1)
	
	if args.size() < 2:
		push_error("❌ audio command: 使用法: audio <bgm|se> <play|stop|volume> [options]")
		return
	
	var subcommand = args[0].to_lower()
	var action = args[1].to_lower()
	
	log_command("Audio command: " + subcommand + " " + action)
	
	if not adv_system.get("AudioManager") or not adv_system.AudioManager:
		push_error("❌ AudioManager not available")
		return
	
	match subcommand:
		"bgm":
			_execute_bgm(action, args.slice(2), adv_system)
		"se":
			_execute_se(action, args.slice(2), adv_system)
		_:
			push_error("❌ audio: 不明なサブコマンド: " + subcommand)

func _parse_raw_params(raw_params: String) -> PackedStringArray:
	"""パラメータ解析"""
	var args = PackedStringArray()
	var tokens = raw_params.strip_edges().split(" ")
	
	for token in tokens:
		if token.length() > 0:
			args.append(token)
	
	return args

func _execute_bgm(action: String, args: PackedStringArray, adv_system: Node):
	"""BGMコマンド処理"""
	var audio_manager = adv_system.AudioManager
	
	match action:
		"play":
			if args.size() < 1:
				push_error("❌ bgm play: オーディオ名が必要です")
				return
			
			var audio_name = args[0]
			var loop = true
			var volume = 1.0
			
			# オプション解析
			for i in range(1, args.size()):
				var arg = args[i]
				if arg == "noloop":
					loop = false
				elif arg.begins_with("volume="):
					volume = clamp(arg.substr(7).to_float() / 100.0, 0.0, 1.0)
			
			print("🎵 Audio Command: Playing BGM:", audio_name)
			audio_manager.play_bgm(audio_name, loop, volume, 0.0)
			
		"stop":
			print("🎵 Audio Command: Stopping BGM")
			audio_manager.stop_bgm(0.0)
			
		"volume":
			if args.size() < 1 or not args[0].begins_with("volume="):
				push_error("❌ bgm volume: volume=<0-100> が必要です")
				return
			
			var volume_val = args[0].substr(7).to_float()
			var volume = clamp(volume_val / 100.0, 0.0, 1.0)
			print("🔊 Audio Command: Setting BGM volume:", volume_val, "%")
			audio_manager.set_bgm_volume(volume)

func _execute_se(action: String, args: PackedStringArray, adv_system: Node):
	"""SEコマンド処理"""
	var audio_manager = adv_system.AudioManager
	
	match action:
		"play":
			if args.size() < 1:
				push_error("❌ se play: オーディオ名が必要です")
				return
			
			var audio_name = args[0]
			var volume = 1.0
			var pitch = 1.0
			
			# オプション解析
			for i in range(1, args.size()):
				var arg = args[i]
				if arg.begins_with("volume="):
					volume = clamp(arg.substr(7).to_float() / 100.0, 0.0, 1.0)
				elif arg.begins_with("pitch="):
					pitch = arg.substr(6).to_float()
			
			print("🔊 Audio Command: Playing SE:", audio_name)
			audio_manager.play_se(audio_name, volume, pitch)
			
		"stop":
			var audio_name = ""
			if args.size() > 0:
				audio_name = args[0]
			
			print("🔊 Audio Command: Stopping SE:", audio_name if not audio_name.is_empty() else "all")
			audio_manager.stop_se(audio_name)
			
		"volume":
			if args.size() < 1 or not args[0].begins_with("volume="):
				push_error("❌ se volume: volume=<0-100> が必要です")
				return
			
			var volume_val = args[0].substr(7).to_float()
			var volume = clamp(volume_val / 100.0, 0.0, 1.0)
			print("🔊 Audio Command: Setting SE volume:", volume_val, "%")
			audio_manager.set_se_volume(volume)
