# AdvGameUI.gd
# v2設計: AdvScreenを継承したADVゲーム用UI画面
extends "res://addons/adv_engine/ui/AdvScreen.gd"
class_name AdvGameUI

# === UI要素 ===
@onready var message_box: Control = $MessageBox
@onready var name_label: Label = $MessageBox/MessagePanel/MarginContainer/VBoxContainer/NameLabel
@onready var message_label: RichTextLabel = $MessageBox/MessagePanel/MarginContainer/VBoxContainer/MessageLabel
@onready var choice_container: Control = $ChoiceContainer
@onready var choice_panel: Panel = $ChoiceContainer/ChoicePanel
@onready var choice_vbox: VBoxContainer = $ChoiceContainer/ChoicePanel/VBoxContainer
@onready var continue_prompt: Label = $ContinuePrompt

# === 自動スクリプト設定 ===
@export var auto_start_script: bool = true
@export var default_script_path: String = "res://scenarios/main_demo.rgd"
@export var start_label: String = "main_demo_start"

# === レイヤーマッピング設定 ===
@export var layer_mappings: Dictionary = {
	"background": null,
	"character": null,
	"ui": null
}

# === タイプライター機能 ===
var typewriter: TypewriterText
var is_message_complete: bool = false
var handle_input: bool = true

var choice_buttons: Array[Button] = []

func _ready():
	super._ready()
	print("🎨 AdvGameUI initialized (v2 AdvScreen-based)")
	
	if not message_box:
		push_error("❌ MessageBox not found! Check the scene structure.")
		return
	
	if not message_label:
		push_error("❌ MessageLabel not found! Check the scene structure.")
		return
	
	# タイプライター初期化
	typewriter = TypewriterText.new()
	add_child(typewriter)
	typewriter.setup_target(message_label)
	typewriter.skip_key_enabled = false
	
	# タイプライターシグナル接続
	typewriter.typewriter_started.connect(_on_typewriter_started)
	typewriter.typewriter_finished.connect(_on_typewriter_finished)
	typewriter.typewriter_skipped.connect(_on_typewriter_skipped)
	typewriter.character_typed.connect(_on_character_typed)
	
	# 初期状態設定
	choice_container.visible = false
	message_box.visible = true
	continue_prompt.visible = false
	
	# MessageBox状態確認完了
	
	# デフォルトボタンを取得
	_get_default_buttons()
	
	# レイヤーマッピング初期化
	_initialize_layer_mappings()

func on_screen_ready():
	"""画面初期化完了時の処理"""
	if auto_start_script:
		await get_tree().process_frame
		start_auto_script()

func on_screen_shown(parameters: Dictionary = {}):
	"""画面表示時の処理"""
	super.on_screen_shown(parameters)
	# 必要に応じて画面表示時の追加処理

func start_auto_script():
	"""自動スクリプト開始機能（v2 AdvScreen版）"""
	print("🚀 AdvGameUI: Starting auto script")
	
	if default_script_path.is_empty():
		print("⚠️ No default script path specified")
		return
	
	if not adv_system:
		push_error("❌ AdvSystem not found")
		return
	
	print("🎬 Auto-starting script:", default_script_path, "from label:", start_label)
	
	# AdvSystemにレイヤーマッピングを渡して初期化
	if not adv_system.is_initialized:
		print("🚀 Initializing AdvSystem...")
		var success = adv_system.initialize_game(layer_mappings)
		if not success:
			print("❌ AdvSystem initialization failed")
			return
		print("✅ AdvSystem initialization successful")
		# カスタムコマンドシグナルに接続
		_connect_custom_command_signals()
	
	# スクリプトを開始
	adv_system.start_script(default_script_path, start_label)
	
	# UIManagerとの連携を設定
	setup_ui_manager_integration()

func setup_ui_manager_integration():
	"""UIManagerとの連携を設定（v2 AdvScreen版）"""
	if not adv_system or not adv_system.UIManager:
		push_error("❌ AdvSystem.UIManager not available")
		return
	
	var ui_manager = adv_system.UIManager
	print("🔗 Found UIManager via AdvSystem")
	
	# UIManagerの参照を設定
	ui_manager.name_label = name_label
	ui_manager.text_label = message_label
	ui_manager.choice_container = choice_vbox
	
	# 入力処理を有効化
	handle_input = true
	print("🔗 UI integrated with AdvSystem.UIManager - input enabled")

# === メッセージ表示機能 ===

func show_message(character_name: String = "", message: String = "", name_color: Color = Color.WHITE):
	"""メッセージを表示する（タイプライター付き）"""
	
	if not message_box:
		push_error("❌ show_message: MessageBox is null!")
		return
	
	if not message_label:
		push_error("❌ show_message: MessageLabel is null!")
		return
	
	message_box.visible = true
	choice_container.visible = false
	continue_prompt.visible = false
	is_message_complete = false
	
	# UI状態設定完了
	
	if character_name.is_empty():
		name_label.text = ""
		name_label.visible = false
	else:
		name_label.text = character_name
		name_label.modulate = name_color
		name_label.visible = true
	
	# エスケープシーケンスを変換
	var processed_message = _process_escape_sequences(message)
	
	# タイプライターでメッセージを表示
	typewriter.start_typing(processed_message)
	print("💬 UI Message: [", character_name, "] ", processed_message)

func show_choices(choices: Array):
	"""選択肢を表示する"""
	message_box.visible = true
	choice_container.visible = true
	continue_prompt.visible = false
	
	# 既存ボタンをクリア
	_clear_choice_buttons()
	
	# 新しい選択肢ボタンを作成
	for i in range(choices.size()):
		var button = Button.new()
		button.text = str(i + 1) + ". " + choices[i]
		button.add_theme_font_size_override("font_size", 14)
		button.pressed.connect(_on_choice_selected.bind(i))
		choice_vbox.add_child(button)
	
	print("🤔 UI Choices displayed: ", choices.size(), " options")

func hide_ui():
	"""UI全体を非表示にする"""
	message_box.visible = false
	choice_container.visible = false
	continue_prompt.visible = false

# === 入力処理 ===

func _unhandled_input(event):
	"""UIでの入力処理（v2 AdvScreen版）"""
	if not handle_input:
		return
	
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		print("🎮 AdvGameUI: Input detected - ui_accept:", event.is_action_pressed("ui_accept"), "ui_select:", event.is_action_pressed("ui_select"))
		print("📦 Message box visible:", message_box.visible, "Choice container visible:", choice_container.visible)
	
	if message_box.visible and not choice_container.visible:
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
			var key_name = "Enter" if event.is_action_pressed("ui_accept") else "Space"
			print("🎮 AdvGameUI: ", key_name, " pressed")
			print("⌨️ Message complete: ", is_message_complete)
			
			if not is_message_complete:
				print("⌨️ Skipping typewriter")
				typewriter.skip_typing()
				get_viewport().set_input_as_handled()
			else:
				print("➡️ Message complete - advancing ADV engine")
				if adv_system and adv_system.Player:
					adv_system.Player.next()
				get_viewport().set_input_as_handled()

# === 選択肢処理 ===

func _on_choice_selected(choice_index: int):
	"""選択肢選択時の処理"""
	print("🔘 UI Choice selected: ", choice_index)
	choice_container.visible = false
	
	# ADVエンジンに選択結果を送信
	if adv_system and adv_system.Player:
		adv_system.Player.on_choice_selected(choice_index)

# === タイプライターシグナルハンドラー ===

func _on_typewriter_started(_text: String):
	is_message_complete = false
	continue_prompt.visible = false
	print("⌨️ UI: Typewriter started")

func _on_typewriter_finished():
	is_message_complete = true
	continue_prompt.visible = true
	print("⌨️ UI: Typewriter finished")

func _on_typewriter_skipped():
	is_message_complete = true
	continue_prompt.visible = true
	print("⌨️ UI: Typewriter skipped")

func _on_character_typed(_character: String, _position: int):
	# カスタマイズ用
	pass

# === ヘルパーメソッド ===

func _get_default_buttons():
	for child in choice_vbox.get_children():
		if child is Button:
			choice_buttons.append(child)

func _clear_choice_buttons():
	for child in choice_vbox.get_children():
		if child is Button:
			child.queue_free()

func _process_escape_sequences(text: String) -> String:
	var result = text
	result = result.replace("\\n", "\n")
	result = result.replace("\\t", "\t")
	result = result.replace("\\r", "\r")
	result = result.replace("\\\\", "\\")
	return result

func _initialize_layer_mappings():
	"""レイヤーマッピングの初期化"""
	layer_mappings["ui"] = self
	
	var parent_scene = get_tree().current_scene
	if parent_scene:
		var bg_layer = parent_scene.find_child("BackgroundLayer")
		if bg_layer:
			layer_mappings["background"] = bg_layer
		
		var char_layer = parent_scene.find_child("CharacterLayer")
		if char_layer:
			layer_mappings["character"] = char_layer
	
	print("🗺️ AdvGameUI: Layer mappings initialized:", layer_mappings)

func set_script_path(path: String, label: String = "start"):
	"""スクリプトパスとラベルを設定"""
	default_script_path = path
	start_label = label
	print("📝 Script path set to:", path, "with label:", label)

# === カスタムコマンド視覚効果実装 ===

func _connect_custom_command_signals():
	"""カスタムコマンドのシグナルに接続"""
	print("🔗 AdvGameUI: Attempting to connect to CustomCommandHandler signals...")
	print("   adv_system: ", adv_system)
	print("   CustomCommandHandler: ", adv_system.CustomCommandHandler if adv_system else "null")
	
	if adv_system and adv_system.CustomCommandHandler:
		var handler = adv_system.CustomCommandHandler
		handler.window_shake_requested.connect(_on_window_shake_requested)
		handler.camera_effect_requested.connect(_on_camera_effect_requested)
		handler.screen_flash_requested.connect(_on_screen_flash_requested)
		handler.custom_transition_requested.connect(_on_custom_transition_requested)
		handler.text_effect_requested.connect(_on_text_effect_requested)
		handler.ui_animation_requested.connect(_on_ui_animation_requested)
		handler.particle_effect_requested.connect(_on_particle_effect_requested)
		print("🎯 AdvGameUI: Successfully connected to CustomCommandHandler signals!")
	else:
		print("❌ AdvGameUI: Cannot connect - CustomCommandHandler not available")

func _on_window_shake_requested(intensity: float, duration: float):
	"""ウィンドウシェイク効果を実行"""
	print("🪟 AdvGameUI: Executing window shake - intensity=", intensity, " duration=", duration)
	
	var window = get_window()
	if window:
		var original_pos = window.position
		var tween = create_tween()
		var shake_steps = int(duration * 30)  # 30fps
		
		for i in range(shake_steps):
			var shake_offset = Vector2i(
				randi_range(-int(intensity), int(intensity)),
				randi_range(-int(intensity), int(intensity))
			)
			var target_pos = original_pos + shake_offset
			tween.tween_method(
				func(pos): window.position = pos,
				window.position, target_pos, 
				duration / shake_steps
			)
		
		# 元の位置に戻す
		tween.tween_method(
			func(pos): window.position = pos,
			window.position, original_pos,
			0.1
		)

func _on_camera_effect_requested(effect_name: String, parameters: Dictionary):
	"""カメラ効果を実行"""
	print("📹 AdvGameUI: Executing camera effect - ", effect_name, " params=", parameters)
	
	if effect_name == "shake":
		var intensity = parameters.get("intensity", 2.0)
		var duration = parameters.get("duration", 0.5)
		var shake_type = parameters.get("type", "both")
		
		_execute_camera_shake(intensity, duration, shake_type)

func _execute_camera_shake(intensity: float, duration: float, shake_type: String):
	"""カメラシェイクを実行（全画面を揺らす）"""
	var original_pos = position
	var tween = create_tween()
	var shake_steps = int(duration * 30)
	
	for i in range(shake_steps):
		var shake_offset = Vector2.ZERO
		match shake_type:
			"horizontal":
				shake_offset.x = randf_range(-intensity, intensity)
			"vertical":
				shake_offset.y = randf_range(-intensity, intensity)
			_:  # "both"
				shake_offset = Vector2(
					randf_range(-intensity, intensity),
					randf_range(-intensity, intensity)
				)
		
		var target_pos = original_pos + shake_offset
		tween.tween_property(self, "position", target_pos, duration / shake_steps)
	
	# 元の位置に戻す
	tween.tween_property(self, "position", original_pos, 0.1)

func _on_screen_flash_requested(color: Color, duration: float):
	"""画面フラッシュ効果を実行"""
	print("⚡ AdvGameUI: Executing screen flash - color=", color, " duration=", duration)
	
	# フラッシュ用のColorRectを作成
	var flash_rect = ColorRect.new()
	flash_rect.color = color
	flash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(flash_rect)
	
	# フェードイン・アウト効果
	var tween = create_tween()
	flash_rect.modulate.a = 0.0
	tween.tween_property(flash_rect, "modulate:a", 0.8, duration * 0.3)
	tween.tween_property(flash_rect, "modulate:a", 0.0, duration * 0.7)
	tween.tween_callback(flash_rect.queue_free)

func _on_custom_transition_requested(transition_name: String, parameters: Dictionary):
	"""カスタムトランジション効果を実行"""
	print("🌀 AdvGameUI: Executing custom transition - ", transition_name, " params=", parameters)
	# サンプル実装：スピン効果
	if transition_name == "spiral":
		var speed = parameters.get("speed", 1.0)
		var direction = parameters.get("direction", "clockwise")
		_execute_spiral_transition(speed, direction)

func _execute_spiral_transition(speed: float, direction: String):
	"""スパイラルトランジション効果"""
	var rotation_amount = 360.0 if direction == "clockwise" else -360.0
	var tween = create_tween()
	tween.tween_property(self, "rotation_degrees", rotation_amount, 1.0 / speed)
	tween.tween_property(self, "rotation_degrees", 0.0, 0.2)

func _on_text_effect_requested(effect_name: String, parameters: Dictionary):
	"""テキスト演出効果を実行"""
	print("📝 AdvGameUI: Executing text effect - ", effect_name, " params=", parameters)
	
	if effect_name == "wave":
		_execute_text_wave_effect(parameters)
	elif effect_name == "shake":
		_execute_text_shake_effect(parameters)
	elif effect_name == "typewriter":
		_execute_typewriter_effect(parameters)

func _execute_text_wave_effect(params: Dictionary):
	"""テキスト波打ち効果"""
	var amplitude = params.get("amplitude", 5.0)
	var frequency = params.get("frequency", 2.0)
	var duration = params.get("duration", 3.0)
	
	if message_label:
		var tween = create_tween()
		var original_pos = message_label.position
		var steps = int(duration * 30)
		
		for i in range(steps):
			var wave_y = sin(i * frequency * 0.1) * amplitude
			var target_pos = original_pos + Vector2(0, wave_y)
			tween.tween_property(message_label, "position", target_pos, duration / steps)
		
		tween.tween_property(message_label, "position", original_pos, 0.2)

func _execute_text_shake_effect(params: Dictionary):
	"""テキストシェイク効果"""
	var intensity = params.get("intensity", 2.0)
	var duration = params.get("duration", 0.5)
	
	if message_label:
		var original_pos = message_label.position
		var tween = create_tween()
		var shake_steps = int(duration * 30)
		
		for i in range(shake_steps):
			var shake_offset = Vector2(
				randf_range(-intensity, intensity),
				randf_range(-intensity, intensity)
			)
			var target_pos = original_pos + shake_offset
			tween.tween_property(message_label, "position", target_pos, duration / shake_steps)
		
		tween.tween_property(message_label, "position", original_pos, 0.1)

func _execute_typewriter_effect(params: Dictionary):
	"""タイプライター効果速度変更"""
	var speed = params.get("speed", "normal")
	
	if typewriter:
		match speed:
			"fast":
				typewriter.characters_per_second = 60.0
			"slow":
				typewriter.characters_per_second = 15.0
			"instant":
				typewriter.characters_per_second = 1000.0
			_:
				typewriter.characters_per_second = 30.0  # normal

func _on_ui_animation_requested(animation_name: String, parameters: Dictionary):
	"""UIアニメーション効果を実行"""
	print("🎞️ AdvGameUI: Executing UI animation - ", animation_name, " params=", parameters)
	
	match animation_name:
		"slide":
			_execute_ui_slide_animation(parameters)
		"fade":
			_execute_ui_fade_animation(parameters)

func _execute_ui_slide_animation(params: Dictionary):
	"""UIスライドアニメーション"""
	var action = params.get("action", "in")
	var direction = params.get("direction", "left")
	var duration = params.get("duration", 0.5)
	
	var target_control = message_box if message_box else self
	var screen_size = get_viewport().get_visible_rect().size
	var original_pos = target_control.position
	
	var slide_distance = Vector2.ZERO
	match direction:
		"left":
			slide_distance = Vector2(-screen_size.x, 0)
		"right":
			slide_distance = Vector2(screen_size.x, 0)
		"up":
			slide_distance = Vector2(0, -screen_size.y)
		"down":
			slide_distance = Vector2(0, screen_size.y)
	
	var tween = create_tween()
	
	if action == "in":
		target_control.position = original_pos + slide_distance
		tween.tween_property(target_control, "position", original_pos, duration)
	else:  # "out"
		tween.tween_property(target_control, "position", original_pos + slide_distance, duration)

func _execute_ui_fade_animation(params: Dictionary):
	"""UIフェードアニメーション"""
	var action = params.get("action", "in")
	var duration = params.get("duration", 1.0)
	var alpha = params.get("alpha", 1.0 if action == "in" else 0.0)
	
	var target_control = message_box if message_box else self
	var tween = create_tween()
	
	if action == "in":
		target_control.modulate.a = 0.0
	
	tween.tween_property(target_control, "modulate:a", alpha, duration)

func _on_particle_effect_requested(effect_name: String, parameters: Dictionary):
	"""パーティクル効果を実行"""
	print("✨ AdvGameUI: Executing particle effect - ", effect_name, " params=", parameters)
	
	# パーティクルシステムが実装されていない場合は、代替効果で対応
	match effect_name:
		"sparkle":
			_create_sparkle_effect(parameters)
		"rain":
			print("🌧️ Rain particle effect requested (not implemented)")
		"snow":
			print("❄️ Snow particle effect requested (not implemented)")
		"explosion":
			_create_explosion_effect(parameters)

func _create_sparkle_effect(params: Dictionary):
	"""簡単なスパークル効果（パーティクルの代替）"""
	var intensity = params.get("intensity", "normal")
	var duration = params.get("duration", 2.0)
	
	var sparkle_count = 10
	if intensity == "high":
		sparkle_count = 20
	elif intensity == "low":
		sparkle_count = 5
	
	for i in range(sparkle_count):
		var sparkle = ColorRect.new()
		sparkle.size = Vector2(4, 4)
		sparkle.color = Color(1, 1, 1, 0.8)
		sparkle.position = Vector2(
			randf() * get_viewport().get_visible_rect().size.x,
			randf() * get_viewport().get_visible_rect().size.y
		)
		add_child(sparkle)
		
		var tween = create_tween()
		tween.tween_property(sparkle, "modulate:a", 0.0, duration * randf())
		tween.tween_callback(sparkle.queue_free)

func _create_explosion_effect(params: Dictionary):
	"""簡単な爆発効果"""
	var explosion_position = params.get("position", "center")
	
	var explosion_pos = Vector2.ZERO
	match explosion_position:
		"center":
			explosion_pos = get_viewport().get_visible_rect().size * 0.5
		_:
			explosion_pos = get_viewport().get_visible_rect().size * 0.5
	
	# 複数の円形エフェクトで爆発を表現
	for i in range(5):
		var circle = ColorRect.new()
		circle.size = Vector2(20, 20) * (i + 1)
		circle.position = explosion_pos - circle.size * 0.5
		circle.color = Color(1, 0.5, 0, 0.7)
		add_child(circle)
		
		var tween = create_tween()
		tween.parallel().tween_property(circle, "scale", Vector2(3, 3), 0.3)
		tween.parallel().tween_property(circle, "modulate:a", 0.0, 0.3)
		tween.tween_callback(circle.queue_free)
