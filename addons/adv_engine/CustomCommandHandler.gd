# CustomCommandHandler.gd
# v2新機能: カスタムコマンドシグナル処理のサンプル実装
extends Node
class_name CustomCommandHandler

# カスタムコマンドシグナル
signal window_shake_requested(intensity: float, duration: float)
signal camera_effect_requested(effect_name: String, parameters: Dictionary)
signal screen_flash_requested(color: Color, duration: float)
signal custom_transition_requested(transition_name: String, parameters: Dictionary)
signal text_effect_requested(effect_name: String, parameters: Dictionary)
signal ui_animation_requested(animation_name: String, parameters: Dictionary)
signal particle_effect_requested(effect_name: String, parameters: Dictionary)
# 同期コマンド完了通知
signal synchronous_command_completed(command_name: String)

var adv_system: Node

func _ready():
	print("🎯 CustomCommandHandler initialized")

func initialize(advSystem: Node):
	"""AdvSystemから初期化される"""
	adv_system = advSystem
	
	# AdvScriptPlayerのカスタムコマンドシグナルに接続
	if adv_system and adv_system.Player:
		adv_system.Player.custom_command_executed.connect(_on_custom_command_executed)
		print("✅ CustomCommandHandler connected to AdvScriptPlayer")
	else:
		push_warning("⚠️ Cannot connect to AdvScriptPlayer")

func _on_custom_command_executed(command_name: String, parameters: Dictionary, line: String):
	"""カスタムコマンドが実行された時の処理"""
	print("🎯 Processing custom command: '", command_name, "' with params: ", parameters)
	
	# 同期が必要なコマンドは個別に処理
	if command_name == "wait":
		await _handle_wait_command(parameters)
		synchronous_command_completed.emit(command_name)
		return
	
	match command_name:
		"window":
			_handle_window_command(parameters)
		"camera_shake":
			_handle_camera_shake_command(parameters)
		"screen_flash":
			_handle_screen_flash_command(parameters)
		"custom_transition":
			_handle_custom_transition_command(parameters)
		"vibrate":
			_handle_vibrate_command(parameters)
		"sound_effect":
			_handle_sound_effect_command(parameters)
		"text_animate":
			_handle_text_animate_command(parameters)
		"ui_slide":
			_handle_ui_slide_command(parameters)
		"ui_fade":
			_handle_ui_fade_command(parameters)
		"particles":
			_handle_particles_command(parameters)
		"zoom":
			_handle_zoom_command(parameters)
		"tint":
			_handle_tint_command(parameters)
		"blur":
			_handle_blur_command(parameters)
		_:
			print("❓ Unknown custom command: ", command_name)
			_handle_unknown_command(command_name, parameters, line)

# === 個別コマンド処理 ===

func _handle_window_command(params: Dictionary):
	"""window コマンド処理（ウィンドウ操作）"""
	# 例: window shake intensity=5.0 duration=0.5
	# 例: window minimize
	# 例: window fullscreen true
	
	# アクション判定：位置パラメータまたはキーワードパラメータから推定
	var action = params.get("arg0", params.get("action", ""))
	
	# key=value形式でアクションが明示されていない場合は、パラメータから推定
	if action.is_empty():
		if params.has("intensity") or params.has("duration"):
			action = "shake"  # shake特有のパラメータがある場合
		elif params.has("enable") or params.has("fullscreen"):
			action = "fullscreen"  # fullscreen特有のパラメータがある場合
	
	print("🪟 Window command action determined: '", action, "'")
	
	match action:
		"shake":
			var intensity = params.get("intensity", params.get("arg1", 5.0))
			var duration = params.get("duration", params.get("arg2", 0.5))
			print("🪟 Window shake requested: intensity=", intensity, " duration=", duration)
			window_shake_requested.emit(intensity, duration)
		"minimize":
			print("🪟 Window minimize requested")
			# Godot 4.x での正しいAPI使用
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)
		"fullscreen":
			var enable = params.get("arg1", params.get("enable", true))
			print("🪟 Fullscreen toggle requested: ", enable)
			if enable:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		_:
			print("❓ Unknown window action: ", action)

func _handle_camera_shake_command(params: Dictionary):
	"""camera_shake コマンド処理"""
	# 例: camera_shake 3.0 0.3
	# 例: camera_shake intensity=2.5 duration=1.0 type=horizontal
	
	var intensity = params.get("intensity", params.get("arg0", params.get(0, 1.0)))
	var duration = params.get("duration", params.get("arg1", params.get(1, 0.5)))
	var shake_type = params.get("type", params.get("arg2", "both"))
	
	print("📹 Camera shake requested: intensity=", intensity, " duration=", duration, " type=", shake_type)
	
	var effect_params = {
		"intensity": intensity,
		"duration": duration,
		"type": shake_type
	}
	
	camera_effect_requested.emit("shake", effect_params)

func _handle_screen_flash_command(params: Dictionary):
	"""screen_flash コマンド処理"""
	# 例: screen_flash white 0.2
	# 例: screen_flash color=red duration=0.5
	
	var color_str = params.get("color", params.get("arg0", params.get(0, "white")))
	var duration = params.get("duration", params.get("arg1", params.get(1, 0.2)))
	
	var color = _parse_color(color_str)
	print("⚡ Screen flash requested: color=", color, " duration=", duration)
	
	screen_flash_requested.emit(color, duration)

func _handle_custom_transition_command(params: Dictionary):
	"""custom_transition コマンド処理"""
	# 例: custom_transition spiral speed=2.0 direction=clockwise
	
	var transition_name = params.get("arg0", params.get(0, "spiral"))
	var effect_params = {}
	
	for key in params.keys():
		var key_str = str(key)
		if not key_str.begins_with("arg") and not key_str.is_valid_int() and key != "_count" and key != "_raw":
			effect_params[key] = params[key]
	
	print("🌀 Custom transition requested: ", transition_name, " params: ", effect_params)
	custom_transition_requested.emit(transition_name, effect_params)

func _handle_wait_command(params: Dictionary) -> void:
	"""wait コマンド処理（待機）"""
	# 例: wait 2.0
	# 例: wait duration=1.5
	
	var duration = params.get("duration", params.get("arg0", params.get(0, 1.0)))
	print("⏱️ Wait requested: ", duration, " seconds")
	
	await get_tree().create_timer(duration).timeout
	print("⏱️ Wait completed")

func _handle_vibrate_command(params: Dictionary):
	"""vibrate コマンド処理（モバイル向け）"""
	# 例: vibrate 200
	# 例: vibrate pattern=short
	
	var duration_ms = params.get("duration", params.get("arg0", params.get(0, 100)))
	var pattern = params.get("pattern", params.get("arg1", ""))
	
	print("📳 Vibrate requested: duration=", duration_ms, "ms pattern=", pattern)
	
	# モバイルプラットフォームでのみ実行
	if OS.has_feature("mobile"):
		match pattern:
			"short":
				Input.vibrate_handheld(100)
			"long":
				Input.vibrate_handheld(500)
			"double":
				Input.vibrate_handheld(100)
				await get_tree().create_timer(0.1).timeout
				Input.vibrate_handheld(100)
			_:
				Input.vibrate_handheld(duration_ms)
	else:
		print("⚠️ Vibration not supported on this platform")

func _handle_sound_effect_command(params: Dictionary):
	"""sound_effect コマンド処理"""
	# 例: sound_effect button_click
	# 例: sound_effect volume=0.8 file=explosion.ogg
	
	var sound_name = params.get("file", params.get("arg0", params.get(0, "")))
	var volume = params.get("volume", params.get("arg1", params.get(1, 1.0)))
	
	print("🔊 Sound effect requested: ", sound_name, " volume=", volume)
	
	# AudioSystemがある場合は委譲
	if adv_system and adv_system.has_method("play_sound_effect"):
		adv_system.play_sound_effect(sound_name, volume)
	else:
		print("⚠️ AudioSystem not available for sound effect")

func _handle_text_animate_command(params: Dictionary):
	"""text_animate コマンド処理（テキスト演出）"""
	# 例: text_animate typewriter speed=fast
	# 例: text_animate wave amplitude=5.0 frequency=2.0
	
	var animation = params.get("arg0", params.get(0, "typewriter"))
	var effect_params = {}
	
	for key in params.keys():
		var key_str = str(key)
		if not key_str.begins_with("arg") and not key_str.is_valid_int() and key != "_count" and key != "_raw":
			effect_params[key] = params[key]
	
	print("📝 Text animation requested: ", animation, " params: ", effect_params)
	text_effect_requested.emit(animation, effect_params)

func _handle_ui_slide_command(params: Dictionary):
	"""ui_slide コマンド処理（UIスライドアニメーション）"""
	# 例: ui_slide in direction=left duration=0.5
	# 例: ui_slide out direction=up
	
	var action = params.get("arg0", params.get(0, "in"))
	var direction = params.get("direction", params.get("arg1", params.get(1, "left")))
	var duration = params.get("duration", params.get("arg2", 0.5))
	
	var effect_params = {
		"action": action,
		"direction": direction, 
		"duration": duration
	}
	
	print("🎞️ UI slide requested: ", effect_params)
	ui_animation_requested.emit("slide", effect_params)

func _handle_ui_fade_command(params: Dictionary):
	"""ui_fade コマンド処理（UIフェードアニメーション）"""
	# 例: ui_fade in duration=1.0
	# 例: ui_fade out alpha=0.3
	
	var action = params.get("arg0", params.get(0, "in"))
	var duration = params.get("duration", params.get("arg1", 1.0))
	var alpha = params.get("alpha", params.get("arg2", 1.0 if action == "in" else 0.0))
	
	var effect_params = {
		"action": action,
		"duration": duration,
		"alpha": alpha
	}
	
	print("🌫️ UI fade requested: ", effect_params)
	ui_animation_requested.emit("fade", effect_params)

func _handle_particles_command(params: Dictionary):
	"""particles コマンド処理（パーティクル効果）"""
	# 例: particles rain intensity=high duration=5.0
	# 例: particles explosion position=center
	
	var particle_type = params.get("arg0", params.get(0, "sparkle"))
	var effect_params = {}
	
	for key in params.keys():
		var key_str = str(key)
		if not key_str.begins_with("arg") and not key_str.is_valid_int() and key != "_count" and key != "_raw":
			effect_params[key] = params[key]
	
	print("✨ Particle effect requested: ", particle_type, " params: ", effect_params)
	particle_effect_requested.emit(particle_type, effect_params)

func _handle_zoom_command(params: Dictionary):
	"""zoom コマンド処理（ズーム効果）"""
	# 例: zoom in scale=1.5 duration=1.0
	# 例: zoom out target=character1
	
	var action = params.get("arg0", params.get(0, "in"))
	var scale = params.get("scale", params.get("arg1", 1.5 if action == "in" else 1.0))
	var duration = params.get("duration", params.get("arg2", 1.0))
	var target = params.get("target", params.get("arg3", ""))
	
	var effect_params = {
		"action": action,
		"scale": scale,
		"duration": duration,
		"target": target
	}
	
	print("🔍 Zoom effect requested: ", effect_params)
	camera_effect_requested.emit("zoom", effect_params)

func _handle_tint_command(params: Dictionary):
	"""tint コマンド処理（色調変更）"""
	# 例: tint red intensity=0.5 duration=2.0
	# 例: tint reset
	
	var color_str = params.get("arg0", params.get(0, "white"))
	var intensity = params.get("intensity", params.get("arg1", 0.3))
	var duration = params.get("duration", params.get("arg2", 1.0))
	
	var color = _parse_color(color_str)
	
	var effect_params = {
		"color": color,
		"intensity": intensity,
		"duration": duration
	}
	
	print("🎨 Tint effect requested: ", effect_params)
	camera_effect_requested.emit("tint", effect_params)

func _handle_blur_command(params: Dictionary):
	"""blur コマンド処理（ブラー効果）"""
	# 例: blur strength=3.0 duration=1.0
	# 例: blur off
	
	var strength = params.get("strength", params.get("arg0", params.get(0, 2.0)))
	var duration = params.get("duration", params.get("arg1", 1.0))
	var action = params.get("arg0", params.get(0, ""))
	
	if action == "off" or action == "disable":
		strength = 0.0
	
	var effect_params = {
		"strength": strength,
		"duration": duration
	}
	
	print("🌀 Blur effect requested: ", effect_params)
	camera_effect_requested.emit("blur", effect_params)

func _handle_unknown_command(command_name: String, params: Dictionary, line: String):
	"""未知のカスタムコマンド処理"""
	print("❓ Unknown custom command '", command_name, "' - forwarding as generic signal")
	print("   Parameters: ", params)
	print("   Original line: ", line)
	
	# 汎用シグナルとして発行（他のシステムがキャッチ可能）
	var signal_name = "custom_" + command_name + "_requested"
	print("📡 Emitting generic signal: ", signal_name)

# === ユーティリティメソッド ===

func _parse_color(color_str: String) -> Color:
	"""色文字列をColor型に変換"""
	match color_str.to_lower():
		"white", "w":
			return Color.WHITE
		"black", "b":
			return Color.BLACK
		"red", "r":
			return Color.RED
		"green", "g":
			return Color.GREEN
		"blue":
			return Color.BLUE
		"yellow", "y":
			return Color.YELLOW
		"cyan", "c":
			return Color.CYAN
		"magenta", "m":
			return Color.MAGENTA
		_:
			# hex形式やRGBA形式の解析を試行
			if color_str.begins_with("#"):
				return Color.html(color_str)
			else:
				print("⚠️ Unknown color: ", color_str, " using white")
				return Color.WHITE

func get_supported_commands() -> Array[String]:
	"""サポートされているカスタムコマンド一覧を返す"""
	return [
		"window", "camera_shake", "screen_flash", "custom_transition",
		"wait", "vibrate", "sound_effect", "text_animate", "ui_slide", 
		"ui_fade", "particles", "zoom", "tint", "blur"
	]

func get_command_help(command_name: String) -> String:
	"""コマンドのヘルプテキストを返す"""
	match command_name:
		"window":
			return "Window operations: window shake intensity=5.0 duration=0.5 | window fullscreen true"
		"camera_shake":
			return "Camera shake: camera_shake intensity=2.0 duration=0.5 type=both"
		"screen_flash":
			return "Screen flash: screen_flash color=white duration=0.2"
		"custom_transition":
			return "Custom transition: custom_transition spiral speed=2.0 direction=clockwise"
		"wait":
			return "Wait/pause: wait duration=2.0"
		"vibrate":
			return "Vibration (mobile): vibrate duration=100 | vibrate pattern=short"
		"sound_effect":
			return "Sound effect: sound_effect button_click volume=0.8"
		"text_animate":
			return "Text animation: text_animate wave amplitude=5.0 frequency=2.0"
		"ui_slide":
			return "UI slide: ui_slide in direction=left duration=0.5"
		"ui_fade":
			return "UI fade: ui_fade in duration=1.0 | ui_fade out alpha=0.3"
		"particles":
			return "Particle effects: particles rain intensity=high duration=5.0"
		"zoom":
			return "Zoom effect: zoom in scale=1.5 duration=1.0 target=character1"
		"tint":
			return "Tint effect: tint red intensity=0.5 duration=2.0"
		"blur":
			return "Blur effect: blur strength=3.0 duration=1.0 | blur off"
		_:
			return "Unknown command: " + command_name