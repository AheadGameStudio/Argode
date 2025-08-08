extends CanvasLayer

var name_label: Label
var text_label: Control  # Label または RichTextLabel に対応
var choice_container: VBoxContainer
var current_sample_ui: Node = null  # 現在のサンプルUI参照

func _ready():
	print("🎨 UIManager initialized")
	
	# サンプルUIがあるかチェック
	_check_for_sample_ui()

func show_message(char_data, message: String):
	# コンソール出力は常に行う
	if char_data:
		print("💬 [", char_data.display_name, "] ", message)
	else:
		print("💬 ", message)
	
	# サンプルUIが連携している場合は、そちらのメッセージ表示を使用
	var sample_ui = _find_adv_game_ui(get_tree().current_scene)
	if sample_ui and sample_ui.has_method("show_message"):
		current_sample_ui = sample_ui
		var char_name = char_data.display_name if char_data else ""
		var char_color = char_data.name_color if char_data else Color.WHITE
		sample_ui.show_message(char_name, message, char_color)
		return
	
	# 基本UIでの表示処理
	if char_data:
		if name_label:
			name_label.text = char_data.display_name
			name_label.modulate = char_data.name_color
	else:
		if name_label:
			name_label.text = ""
	
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
	var script_player = get_node("/root/AdvScriptPlayer")
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

func handle_input_for_adv_engine(event) -> bool:
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