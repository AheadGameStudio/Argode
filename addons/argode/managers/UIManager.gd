extends CanvasLayer

var name_label: Label
var text_label: Control  # Label または RichTextLabel に対応
var choice_container: VBoxContainer
var current_sample_ui: Node = null  # 現在のサンプルUI参照

# v2: ArgodeSystem統合により、直接参照に変更
var script_player  # AdvScriptPlayer - ArgodeSystemから設定される
var character_defs  # CharacterDefinitionManager - v2新機能
var layer_manager  # LayerManager - v2新機能

func _ready():
	print("🎨 UIManager initialized")
	
	# サンプルUIがあるかチェック
	_check_for_sample_ui()

func show_message(char_data, message: String):
	# v2: char_dataがnullの場合、char_idから定義を取得を試行
	var display_name = ""
	var name_color = Color.WHITE
	
	if char_data:
		# v1: すでにchar_dataがある場合（リソースまたは定義）
		if char_data.has("display_name"):
			display_name = char_data.display_name
		if char_data.has("name_color"):
			name_color = char_data.name_color
	
	# コンソール出力
	if display_name:
		print("💬 [", display_name, "] ", message)
	else:
		print("💬 ", message)
	
	# サンプルUIが連携している場合は、そちらのメッセージ表示を使用
	var sample_ui = _find_adv_game_ui(get_tree().current_scene)
	if sample_ui and sample_ui.has_method("show_message"):
		current_sample_ui = sample_ui
		sample_ui.show_message(display_name, message, name_color)
		return
	
	# 基本UIでの表示処理
	if name_label:
		name_label.text = display_name
		name_label.modulate = name_color
	
	if text_label:
		# RichTextLabel と Label の両方に対応
		if text_label.has_method("set_text"):
			text_label.text = message
		elif text_label.has_property("text"):
			text_label.text = message
		else:
			push_warning("⚠️ text_label doesn't support text property: " + str(text_label.get_class()))

func show_choices(choices: Array):
	print("📝 Choose (1-", choices.size(), "):")
	for i in range(choices.size()):
		print("  ", i + 1, ". ", choices[i])
	
	# サンプルUIが連携している場合は、そちらの選択肢表示を使用
	var sample_ui = _find_adv_game_ui(get_tree().current_scene)
	if sample_ui and sample_ui.has_method("show_choices"):
		sample_ui.show_choices(choices)
		return
	
	# Clear existing choice buttons (for basic UI implementation)
	if choice_container:
		for child in choice_container.get_children():
			child.queue_free()
		
		# Create buttons for each choice
		for i in range(choices.size()):
			var button = Button.new()
			button.text = str(i + 1) + ". " + choices[i]
			button.pressed.connect(_on_choice_button_pressed.bind(i))
			choice_container.add_child(button)

func _on_choice_button_pressed(choice_index: int):
	# Clear choice buttons
	if choice_container:
		for child in choice_container.get_children():
			child.queue_free()
	
	# Notify script player
	if script_player:
		script_player.on_choice_selected(choice_index)

func _check_for_sample_ui():
	"""サンプルUIの自動検出と連携設定"""
	# シーン内のAdvGameUIを探す
	var sample_ui = _find_adv_game_ui(get_tree().current_scene)
	if sample_ui:
		print("🔗 Sample UI detected, setting up integration")
		# 少し待ってから連携設定
		call_deferred("_setup_sample_ui_integration", sample_ui)

func _find_adv_game_ui(node: Node) -> Node:
	"""再帰的にAdvGameUIを探す"""
	if not node:
		return null
	if node.get_script():
		var _class_name = node.get_script().get_global_name()
		# AdvGameUIまたはBaseAdvGameUIクラスを検索
		if _class_name == "AdvGameUI" or _class_name == "BaseAdvGameUI":
			return node
	
	for child in node.get_children():
		var result = _find_adv_game_ui(child)
		if result:
			return result
	
	return null

func _setup_sample_ui_integration(ui_node: Node):
	"""サンプルUIとの連携を設定"""
	if ui_node.has_method("setup_ui_manager_integration"):
		ui_node.setup_ui_manager_integration()
		print("✅ Sample UI integration completed")

func is_typewriter_active() -> bool:
	"""タイプライターが動作中かどうかチェック"""
	print("🔍 Checking typewriter state...")
	var sample_ui = _find_adv_game_ui(get_tree().current_scene)
	if sample_ui:
		print("✅ Sample UI found: ", sample_ui.name)
		var typewriter = sample_ui.get("typewriter")
		if typewriter:
			print("✅ Typewriter found")
			if typewriter.has_method("is_typing_active"):
				var is_active = typewriter.is_typing_active()
				print("⌨️ Typewriter is active: ", is_active)
				return is_active
			else:
				print("❌ Typewriter has no is_typing_active method")
		else:
			print("❌ Typewriter not found in sample UI")
	else:
		print("❌ No sample UI found")
	return false

func skip_typewriter():
	"""タイプライターをスキップ"""
	print("⌨️ Attempting to skip typewriter...")
	var sample_ui = _find_adv_game_ui(get_tree().current_scene)
	if sample_ui:
		var typewriter = sample_ui.get("typewriter")
		if typewriter and typewriter.has_method("skip_typing"):
			print("✅ Skipping typewriter")
			typewriter.skip_typing()
		else:
			print("❌ Cannot skip typewriter")

func handle_input_for_argode(event) -> bool:
	"""ADVエンジン用の入力処理 - タイプライター状態を考慮"""
	if event.is_action_pressed("ui_accept"):
		print("🎮 Enter key pressed - checking typewriter...")
		if is_typewriter_active():
			# タイプライター中ならスキップ
			print("⌨️ Skipping typewriter...")
			skip_typewriter()
			print("✅ Input consumed by typewriter")
			return true  # 入力を消費（次に進まない）
		else:
			# タイプライター完了済みなら次に進む
			print("➡️ Typewriter not active, allowing ADV engine to process")
			return false  # 入力を消費しない（ADVエンジンが処理）
	
	return false  # その他の入力は処理しない

# === v2新機能: AdvScreenスタック管理 ===

var screen_stack: Array = []  # Array[AdvScreen] - 型を実行時に確認
var current_screen = null  # AdvScreen - 型を実行時に確認
var screen_container: Control = null

signal screen_pushed(screen)  # AdvScreen
signal screen_popped(screen, return_value: Variant)  # screen: AdvScreen
signal screen_stack_changed()

func _setup_screen_container():
	"""スクリーン表示用のコンテナを作成"""
	if screen_container:
		return
	
	# メインシーンにスクリーンコンテナを追加
	var main_scene = get_tree().current_scene
	if main_scene:
		screen_container = Control.new()
		screen_container.name = "ScreenContainer"
		screen_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		main_scene.add_child(screen_container)
		print("📱 Screen container created")

func call_screen(screen_path: String, parameters: Dictionary = {}, caller = null) -> Variant:  # caller: AdvScreen
	"""画面を呼び出す（スクリーンスタック使用）"""
	print("📱 Calling screen: ", screen_path, " with params: ", parameters)
	
	_setup_screen_container()
	
	# スクリーンをロード
	var screen_scene = load(screen_path)
	if not screen_scene:
		push_error("❌ UIManager: Failed to load screen: " + screen_path)
		return null
	
	var screen_instance = screen_scene.instantiate()
	# AdvScreen型チェック（実行時）
	if not screen_instance.get_script() or not screen_instance.has_method("close_screen"):
		push_error("❌ UIManager: Screen is not an AdvScreen: " + screen_path)
		screen_instance.queue_free()
		return null
	
	# 現在のスクリーンを非アクティブに
	if current_screen:
		current_screen.hide_screen()
		screen_stack.append(current_screen)
	
	# 新しいスクリーンを設定
	current_screen = screen_instance
	screen_container.add_child(screen_instance)
	screen_instance.parent_screen = caller
	
	# スクリーンを表示
	screen_instance.show_screen(parameters)
	
	# シグナル発火
	screen_pushed.emit(screen_instance)
	screen_stack_changed.emit()
	
	# スクリーンが閉じられるまで待機
	var return_value = await screen_instance.screen_closed
	
	return return_value

func close_screen(screen, return_value: Variant = null):  # screen: AdvScreen
	"""画面を閉じる（スクリーンスタックから削除）"""
	if screen != current_screen:
		push_warning("⚠️ UIManager: Trying to close non-current screen")
		return
	
	print("📱 Closing screen: ", screen.screen_name, " with return: ", return_value)
	
	# 現在のスクリーンを削除
	current_screen = null
	screen.queue_free()
	
	# 前のスクリーンを復元
	if screen_stack.size() > 0:
		current_screen = screen_stack.pop_back()
		current_screen.show_screen()
		print("📱 Restored previous screen: ", current_screen.screen_name)
	
	# シグナル発火
	screen_popped.emit(screen, return_value)
	screen_stack_changed.emit()

func get_current_screen():  # -> AdvScreen
	"""現在のスクリーンを取得"""
	return current_screen

func get_screen_stack() -> Array:  # Array[AdvScreen]
	"""スクリーンスタックを取得"""
	return screen_stack.duplicate()

func clear_screen_stack():
	"""スクリーンスタックをクリア"""
	# 全スクリーンを閉じる
	while current_screen:
		var screen = current_screen
		close_screen(screen)
	
	screen_stack.clear()
	screen_stack_changed.emit()
	print("📱 Screen stack cleared")

func get_screen_stack_depth() -> int:
	"""スクリーンスタックの深さを取得"""
	var depth = screen_stack.size()
	if current_screen:
		depth += 1
	return depth