extends CanvasLayer
class_name BaseAdvGameUI

# UI要素への参照
@onready var message_box: Control = $MessageBox
@onready var name_label: Label = $MessageBox/MessagePanel/MarginContainer/VBoxContainer/NameLabel
@onready var message_label: RichTextLabel = $MessageBox/MessagePanel/MarginContainer/VBoxContainer/MessageLabel
@onready var choice_container: Control = $ChoiceContainer
@onready var choice_panel: Panel = $ChoiceContainer/ChoicePanel
@onready var choice_vbox: VBoxContainer = $ChoiceContainer/ChoicePanel/VBoxContainer
@onready var continue_prompt: Label = $ContinuePrompt

# 自動スクリプト実行設定
@export var auto_start_script: bool = true
@export var default_script_path: String = "res://scenarios/scene_test.rgd"
@export var start_label: String = "scene_test_start"

# タイプライター機能
var typewriter: TypewriterText
var is_message_complete: bool = false
var handle_input: bool = true  # ADVエンジンとの重複を防ぐ

var choice_buttons: Array[Button] = []

func _ready():
	print("🎨 AdvGameUI initialized")
	
	# タイプライター初期化
	typewriter = TypewriterText.new()
	add_child(typewriter)
	typewriter.setup_target(message_label)
	# スキップキー処理を無効化（UIManagerが制御）
	typewriter.skip_key_enabled = false
	
	# タイプライターシグナル接続
	typewriter.typewriter_started.connect(_on_typewriter_started)
	typewriter.typewriter_finished.connect(_on_typewriter_finished)
	typewriter.typewriter_skipped.connect(_on_typewriter_skipped)
	typewriter.character_typed.connect(_on_character_typed)
	
	# 初期状態では選択肢を非表示
	choice_container.visible = false
	
	# メッセージボックスは初期状態で表示
	message_box.visible = true
	continue_prompt.visible = false
	
	# デフォルトのボタンを取得（削除用）
	_get_default_buttons()
	
	# デバッグ用：初期メッセージを表示
	print("🔍 BaseAdvGameUI: MessageBox visible =", message_box.visible)
	print("🔍 BaseAdvGameUI: ChoiceContainer visible =", choice_container.visible)
	
	# 自動スクリプト開始機能
	if auto_start_script:
		await get_tree().process_frame  # 初期化完了を待つ
		start_auto_script()

func _get_default_buttons():
	for child in choice_vbox.get_children():
		if child is Button:
			choice_buttons.append(child)

# ベースクラス用の仮想関数（継承先で必要に応じてオーバーライド）
func initialize_ui():
	"""UIの初期化処理（継承先でオーバーライド推奨）"""
	pass

func start_auto_script():
	"""自動スクリプト開始機能"""
	print("🚀 BaseAdvGameUI: start_auto_script called")
	print("  - auto_start_script:", auto_start_script)
	print("  - default_script_path:", default_script_path)
	print("  - start_label:", start_label)
	
	if default_script_path.is_empty():
		print("⚠️ BaseAdvGameUI: No default script path specified")
		return
		
	var script_player = get_node("/root/AdvScriptPlayer")
	if script_player:
		print("🎬 BaseAdvGameUI: Auto-starting script:", default_script_path, "from label:", start_label)
		script_player.load_script(default_script_path)
		script_player.play_from_label(start_label)
		
		# UIManagerとの連携を設定
		setup_ui_manager_integration()
	else:
		print("❌ BaseAdvGameUI: AdvScriptPlayer not found - script auto-start disabled")

func set_script_path(path: String, label: String = "start"):
	"""スクリプトパスとラベルを設定"""
	default_script_path = path
	start_label = label
	print("📝 BaseAdvGameUI: Script path set to:", path, "with label:", label)

func show_message(character_name: String = "", message: String = "", name_color: Color = Color.WHITE):
	"""メッセージを表示する（タイプライター付き）"""
	message_box.visible = true
	choice_container.visible = false
	continue_prompt.visible = false  # タイプ中は非表示
	is_message_complete = false
	
	if character_name.is_empty():
		name_label.text = ""
		name_label.visible = false
	else:
		name_label.text = character_name
		name_label.modulate = name_color
		name_label.visible = true
	
	# エスケープシーケンスを実際の文字に変換
	var processed_message = _process_escape_sequences(message)
	
	# タイプライターでメッセージを表示
	typewriter.start_typing(processed_message)
	print("💬 UI Message: [", character_name, "] ", processed_message)

func show_choices(choices: Array):
	"""選択肢を表示する"""
	message_box.visible = true
	choice_container.visible = true
	continue_prompt.visible = false
	
	# 既存のボタンをクリア
	_clear_choice_buttons()
	
	# 新しい選択肢ボタンを作成
	for i in range(choices.size()):
		var button = Button.new()
		button.text = str(i + 1) + ". " + choices[i]
		# Godot 4.x でのフォントサイズ設定
		button.add_theme_font_size_override("font_size", 14)
		button.pressed.connect(_on_choice_selected.bind(i))
		choice_vbox.add_child(button)
	
	print("🤔 UI Choices displayed: ", choices.size(), " options")

func hide_ui():
	"""UI全体を非表示にする"""
	message_box.visible = false
	choice_container.visible = false
	continue_prompt.visible = false

func _clear_choice_buttons():
	"""選択肢ボタンをクリア"""
	for child in choice_vbox.get_children():
		if child is Button:
			child.queue_free()

func _on_choice_selected(choice_index: int):
	"""選択肢が選択された時の処理"""
	print("🔘 UI Choice selected: ", choice_index)
	choice_container.visible = false
	
	# ADVエンジンに選択結果を送信
	var script_player = get_node("/root/AdvScriptPlayer")
	if script_player:
		script_player.on_choice_selected(choice_index)

func _unhandled_input(event):
	"""UIでの入力処理（メッセージ送り・タイプライタースキップ）"""
	if not handle_input:
		print("🚫 AdvGameUI: Input handling disabled")
		return
		
	if message_box.visible and not choice_container.visible:
		# EnterキーとSpaceキー両方を同じ処理にする
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
			var key_name = "Enter" if event.is_action_pressed("ui_accept") else "Space"
			print("🎮 AdvGameUI: ", key_name, " pressed")
			print("⌨️ Message complete: ", is_message_complete)
			if not is_message_complete:
				# タイプライター中なら完了させる
				print("⌨️ AdvGameUI: Skipping typewriter")
				typewriter.skip_typing()
				# タイプライター中の場合はイベントを消費してusage_sampleに渡さない
				get_viewport().set_input_as_handled()
			else:
				# メッセージ完了済みの場合 - ADVエンジンを進める
				print("➡️ AdvGameUI: Message complete - advancing ADV engine")
				var script_player = get_node("/root/AdvScriptPlayer")
				if script_player:
					script_player.next()
					# イベントを消費して重複処理を防ぐ
					get_viewport().set_input_as_handled()
				else:
					print("⚠️ AdvGameUI: No script player - standalone mode")

# タイプライターシグナルハンドラー
func _on_typewriter_started(text: String):
	"""タイプライター開始時"""
	is_message_complete = false
	continue_prompt.visible = false
	print("⌨️ UI: Typewriter started")

func _on_typewriter_finished():
	"""タイプライター完了時"""
	is_message_complete = true
	continue_prompt.visible = true
	print("⌨️ UI: Typewriter finished")

func _on_typewriter_skipped():
	"""タイプライタースキップ時"""
	is_message_complete = true
	continue_prompt.visible = true
	print("⌨️ UI: Typewriter skipped")

func _on_character_typed(character: String, position: int):
	"""1文字タイプ時（カスタマイズ用）"""
	# 必要に応じて効果音や演出を追加可能
	pass

# ユーティリティ関数
func _process_escape_sequences(text: String) -> String:
	"""エスケープシーケンスを実際の文字に変換"""
	var result = text
	
	# よく使われるエスケープシーケンスを変換
	result = result.replace("\\n", "\n")   # 改行
	result = result.replace("\\t", "\t")   # タブ
	result = result.replace("\\r", "\r")   # キャリッジリターン
	result = result.replace("\\\\", "\\")  # バックスラッシュ
	
	return result

# UIManagerから呼び出される関数群
func setup_ui_manager_integration():
	"""UIManagerとの連携を設定"""
	var ui_manager = get_node("/root/UIManager")
	if ui_manager:
		# UIManagerの参照を設定
		ui_manager.name_label = name_label
		ui_manager.text_label = message_label
		ui_manager.choice_container = choice_vbox
		
		# BaseAdvGameUIを直接使用する場合は入力処理を有効にする
		var scene_name = get_tree().current_scene.scene_file_path
		if scene_name.contains("usage_sample") or scene_name.contains("main"):
			handle_input = true
			print("🔗 UI integrated with UIManager (direct UI mode - input enabled)")
		else:
			handle_input = false
			print("🔗 UI integrated with UIManager (input handling disabled)")
	else:
		# スタンドアロンモード
		handle_input = true
		print("🔗 UI running in standalone mode")
