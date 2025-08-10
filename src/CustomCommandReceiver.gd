# CustomCommandReceiver.gd
# カスタムコマンドシグナルを受け取って実際の処理を行うサンプル実装
extends Node
class_name CustomCommandReceiver

var main_camera: Camera2D  # メインカメラへの参照
var screen_overlay: ColorRect  # スクリーンフラッシュ用オーバーレイ
var shake_tween: Tween

func _ready():
	print("📡 CustomCommandReceiver initialized")
	
	# AdvSystemのCustomCommandHandlerからシグナルを受信
	var adv_system = get_node("/root/AdvSystem")
	if adv_system and adv_system.CustomCommandHandler:
		var handler = adv_system.CustomCommandHandler
		
		# 各シグナルに接続
		handler.window_shake_requested.connect(_on_window_shake_requested)
		handler.camera_effect_requested.connect(_on_camera_effect_requested) 
		handler.screen_flash_requested.connect(_on_screen_flash_requested)
		handler.custom_transition_requested.connect(_on_custom_transition_requested)
		
		print("✅ CustomCommandReceiver connected to signals")
	else:
		push_warning("⚠️ AdvSystem.CustomCommandHandler not found")

func setup_references(camera: Camera2D, overlay: ColorRect):
	"""外部からカメラとオーバーレイの参照を設定"""
	main_camera = camera
	screen_overlay = overlay
	print("🔗 CustomCommandReceiver references set up")

# === シグナルハンドラー ===

func _on_window_shake_requested(intensity: float, duration: float):
	"""ウィンドウ揺れエフェクトの実行"""
	print("🪟 Executing window shake: intensity=", intensity, " duration=", duration)
	
	if not main_camera:
		print("⚠️ No camera reference for window shake")
		return
	
	# カメラをシェイクして疑似的にウィンドウ揺れを表現
	_shake_camera(intensity * 2.0, duration)

func _on_camera_effect_requested(effect_name: String, parameters: Dictionary):
	"""カメラエフェクトの実行"""
	print("📹 Executing camera effect: ", effect_name, " params: ", parameters)
	
	match effect_name:
		"shake":
			var intensity = parameters.get("intensity", 1.0)
			var duration = parameters.get("duration", 0.5) 
			var shake_type = parameters.get("type", "both")
			_shake_camera(intensity, duration, shake_type)
		_:
			print("❓ Unknown camera effect: ", effect_name)

func _on_screen_flash_requested(color: Color, duration: float):
	"""スクリーンフラッシュエフェクトの実行"""
	print("⚡ Executing screen flash: color=", color, " duration=", duration)
	
	if not screen_overlay:
		print("⚠️ No screen overlay for flash effect")
		return
	
	# オーバーレイを使ってフラッシュ効果
	screen_overlay.color = color
	screen_overlay.modulate.a = 0.8
	screen_overlay.visible = true
	
	var tween = create_tween()
	tween.tween_property(screen_overlay, "modulate:a", 0.0, duration)
	tween.tween_callback(func(): screen_overlay.visible = false)

func _on_custom_transition_requested(transition_name: String, parameters: Dictionary):
	"""カスタムトランジションエフェクトの実行"""
	print("🌀 Executing custom transition: ", transition_name, " params: ", parameters)
	
	match transition_name:
		"spiral":
			var speed = parameters.get("speed", 1.0)
			var direction = parameters.get("direction", "clockwise")
			_execute_spiral_transition(speed, direction)
		"wave":
			var amplitude = parameters.get("amplitude", 2.0)
			var frequency = parameters.get("frequency", 1.0) 
			var wave_direction = parameters.get("direction", "horizontal")
			var wave_duration = parameters.get("duration", 1.0)
			_execute_wave_transition(amplitude, frequency, wave_direction, wave_duration)
		_:
			print("❓ Unknown custom transition: ", transition_name)

# === エフェクト実装 ===

func _shake_camera(intensity: float, duration: float, shake_type: String = "both"):
	"""カメラシェイクエフェクト"""
	if not main_camera:
		print("⚠️ No camera for shake effect")
		return
	
	# 既存のTweenを停止
	if shake_tween:
		shake_tween.kill()
	
	var original_position = main_camera.global_position
	shake_tween = create_tween()
	
	var steps = int(duration * 30)  # 30 steps per second
	for step in range(steps):
		var progress = float(step) / steps
		var shake_strength = intensity * (1.0 - progress)  # 徐々に弱く
		
		var shake_offset = Vector2.ZERO
		match shake_type:
			"horizontal":
				shake_offset.x = randf_range(-shake_strength, shake_strength)
			"vertical":
				shake_offset.y = randf_range(-shake_strength, shake_strength)
			"both", _:
				shake_offset = Vector2(
					randf_range(-shake_strength, shake_strength),
					randf_range(-shake_strength, shake_strength)
				)
		
		shake_tween.tween_property(main_camera, "global_position", 
			original_position + shake_offset, duration / steps)
	
	# 最後に元の位置に戻す
	shake_tween.tween_property(main_camera, "global_position", original_position, 0.1)

func _execute_spiral_transition(speed: float, direction: String):
	"""スパイラルトランジションエフェクト"""
	if not main_camera:
		return
	
	var rotation_amount = PI * 2 * speed
	if direction == "counterclockwise":
		rotation_amount = -rotation_amount
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	# 回転
	tween.tween_property(main_camera, "rotation", main_camera.rotation + rotation_amount, 1.0)
	# ズーム
	tween.tween_property(main_camera, "zoom", main_camera.zoom * 0.5, 0.5)
	tween.tween_property(main_camera, "zoom", main_camera.zoom, 0.5).set_delay(0.5)
	
	await tween.finished
	main_camera.rotation = 0  # 回転をリセット

func _execute_wave_transition(amplitude: float, frequency: float, direction: String, duration: float):
	"""波形トランジションエフェクト"""
	if not main_camera:
		return
	
	var original_position = main_camera.global_position
	var tween = create_tween()
	
	var steps = int(duration * 60)  # 60 steps per second
	for step in range(steps):
		var progress = float(step) / steps
		var wave_offset = sin(progress * PI * 2 * frequency) * amplitude
		
		var offset = Vector2.ZERO
		match direction:
			"horizontal":
				offset.x = wave_offset
			"vertical":
				offset.y = wave_offset
			_:
				offset.x = wave_offset
		
		tween.tween_property(main_camera, "global_position", 
			original_position + offset, duration / steps)
	
	# 元の位置に戻す
	tween.tween_property(main_camera, "global_position", original_position, 0.1)

# === ユーティリティ ===

func create_screen_overlay() -> ColorRect:
	"""スクリーンオーバーレイを作成（便利関数）"""
	var overlay = ColorRect.new()
	overlay.name = "ScreenFlashOverlay"
	overlay.color = Color.WHITE
	overlay.modulate.a = 0.0
	overlay.visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 1000  # 最前面
	
	return overlay