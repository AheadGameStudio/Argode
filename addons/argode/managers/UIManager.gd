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
	print("💬 UIManager.show_message called")
	print("  📥 message: '", message, "'")
	
	# v2: char_dataがnullの場合、char_idから定義を取得を試行
	var display_name = ""
	var name_color = Color.WHITE
	
	if char_data:
		if char_data.has("display_name"):
			display_name = char_data.display_name
		if char_data.has("name_color"):
			name_color = char_data.name_color
	
	# コンソール出力（HIDEモードでもログは出力される）
	if display_name:
		print("💬 [", display_name, "] ", message)
	else:
		print("💬 ", message)
	
	# v2: メッセージウィンドウモード制御
	match message_window_mode:
		WindowMode.AUTO:
			_update_message_window_visibility(true)  # メッセージ表示時は表示
		WindowMode.SHOW:
			_update_message_window_visibility(true)  # 常に表示
		WindowMode.HIDE:
			_update_message_window_visibility(false) # 常に非表示（ログのみ）
			return  # UI表示をスキップ
	
	# 🚀 v2優先: current_screenを最初にチェック
	print("🔍 Checking current_screen: ", current_screen)
	if current_screen and current_screen.has_method("show_message"):
		print("✅ Using v2 current_screen.show_message()")
		current_screen.show_message(display_name, message, name_color)
		return
	
	# 🔄 フォールバック: sample_ui検索（後方互換性）
	print("⚠️ current_screen not available, falling back to sample_ui detection")
	var sample_ui = _find_adv_game_ui(get_tree().current_scene)
	if sample_ui and sample_ui.has_method("show_message"):
		print("🔧 Using legacy sample_ui.show_message()")
		current_sample_ui = sample_ui
		sample_ui.show_message(display_name, message, name_color)
		return
	
	print("❌ No UI found for message display")
	
	# 基本UIでの表示処理（最後の手段）
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
	
	if current_screen:
		current_screen.show_choices(choices)

	# Clear existing choice buttons (for basic UI implementation)
	if choice_container:
		print(choice_container)
		if choice_container.get_children() != null:
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

# === v2新機能: メッセージウィンドウ制御 ===

enum WindowMode {
	SHOW,  # 常に表示
	HIDE,  # 常に非表示
	AUTO   # 自動制御（メッセージ表示時のみ表示）
}

var message_window_mode: WindowMode = WindowMode.AUTO

func set_message_window_mode(mode_str: String):
	"""メッセージウィンドウの表示モードを設定"""
	match mode_str.to_lower():
		"show":
			message_window_mode = WindowMode.SHOW
			print("🪟 Message window mode: SHOW (always visible)")
			_update_message_window_visibility(true)
		"hide":
			message_window_mode = WindowMode.HIDE
			print("🪟 Message window mode: HIDE (always hidden)")
			_update_message_window_visibility(false)
		"auto":
			message_window_mode = WindowMode.AUTO
			print("🪟 Message window mode: AUTO (show during messages)")
		_:
			push_warning("⚠️ Unknown window mode: " + mode_str)

func _update_message_window_visibility(visible: bool):
	"""Argode UI全体の表示/非表示を制御（CanvasLayerレベル）"""
	print("🪟 UIManager: Setting visibility to ", visible)
	
	# UIManager自体がCanvasLayerなので、直接visible制御
	self.visible = visible
	
	# current_screenがある場合はそちらも制御
	if current_screen:
		if current_screen is ArgodeScreen:
			var params:Dictionary = current_screen.screen_parameters
			if visible and not current_screen.visible:
				current_screen.show_screen(params)
			elif not visible and current_screen.visible:
				current_screen.hide_screen()
		else:
			current_screen.visible = visible
		print("📱 Current screen visibility also set to: ", visible)
	
	# フォールバック: sample_ui制御
	var sample_ui = _find_adv_game_ui(get_tree().current_scene)
	if sample_ui:
		sample_ui.visible = visible
		print("🔧 Sample UI visibility set to: ", visible)

func set_message_window_mode_with_transition(mode_str: String, transition: String):
	"""トランジション効果付きでメッセージウィンドウモードを設定"""
	print("🪟 Window control with transition: ", mode_str, " -> ", transition)
	
	# モードを設定
	match mode_str.to_lower():
		"show":
			message_window_mode = WindowMode.SHOW
		"hide":
			message_window_mode = WindowMode.HIDE
		"auto":
			message_window_mode = WindowMode.AUTO
		_:
			push_warning("⚠️ Unknown window mode: " + mode_str)
			return
	
	# トランジション効果を適用
	var target_visible = (mode_str.to_lower() != "hide")
	
	# ArgodeSystemのTransitionPlayerを取得
	var argode_system = get_node("/root/ArgodeSystem")
	if argode_system and argode_system.TransitionPlayer:
		print("🎬 Applying transition: ", transition, " to UI visibility")
		
		# トランジション対象のUIを特定
		var transition_target = null
		if current_screen:
			transition_target = current_screen
			print("🎯 Using current_screen as transition target")
		else:
			var sample_ui = _find_adv_game_ui(get_tree().current_scene)
			if sample_ui:
				transition_target = sample_ui
				print("🎯 Using sample_ui as transition target")
		
		if transition_target:
			print("� Transition target:", transition_target.get_class(), "- visible:", transition_target.visible)
			
			if target_visible:
				# 表示する場合: UIを表示状態にしてからフェードイン
				if not self.visible:
					self.visible = true
				if not transition_target.visible:
					transition_target.visible = true
					if transition_target.has_property("modulate"):
						transition_target.modulate.a = 0.0  # 透明から開始
						print("� Target set to visible with alpha 0.0")
				
				# フェードインエフェクト実行
				print("▶️ Starting fade-in transition")
				await argode_system.TransitionPlayer.play(transition_target, transition)
			else:
				# 非表示にする場合: フェードアウト後にUIを非表示
				if transition_target.visible:
					print("▶️ Starting fade-out transition")
					# フェードアウトエフェクト実行
					await argode_system.TransitionPlayer.play(transition_target, transition, 0.5, true)  # reverse = true
					
					# エフェクト完了後に非表示
					transition_target.visible = false
					self.visible = false  # CanvasLayer自体も非表示
					print("📱 Target and UIManager set to invisible")
			
			print("✅ Window transition completed: ", transition)
		else:
			# トランジション対象が見つからない場合は即座に切り替え
			print("⚠️ No transition target found, switching immediately")
			_update_message_window_visibility(target_visible)
	else:
		# TransitionPlayerが無い場合は即座に切り替え
		push_warning("⚠️ TransitionPlayer not available, switching immediately")
		_update_message_window_visibility(target_visible)

func _apply_canvas_layer_fade(target_visible: bool, transition: String, duration: float = 0.5):
	"""CanvasLayer用の独自フェード処理（代替案）"""
	print("🎨 Applying CanvasLayer fade transition: ", transition)
	
	# 全ての子ノードに対してフェード効果を適用
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	var child_nodes = []
	_collect_ui_children(self, child_nodes)
	
	if target_visible:
		# フェードイン: 透明→不透明
		for node in child_nodes:
			if node.has_property("modulate"):
				node.modulate.a = 0.0
		
		self.visible = true
		
		for node in child_nodes:
			if node.has_property("modulate"):
				tween.parallel().tween_property(node, "modulate:a", 1.0, duration)
	else:
		# フェードアウト: 不透明→透明
		for node in child_nodes:
			if node.has_property("modulate"):
				tween.parallel().tween_property(node, "modulate:a", 0.0, duration)
		
		await tween.finished
		self.visible = false

func _collect_ui_children(node: Node, result: Array):
	"""UI要素となる子ノードを再帰的に収集"""
	if node != self and (node is Control or node is Node2D):
		result.append(node)
	
	for child in node.get_children():
		_collect_ui_children(child, result)

func set_main_screen(screen: Node):
	"""メインのArgodeScreenを設定する"""
	if screen and (screen.has_method("show_message") or screen.get_script() and screen.get_script().has_method("show_message")):
		current_screen = screen
		print("🖥️ Main screen set: ", screen.name)
	else:
		print("⚠️ Invalid screen provided to set_main_screen")
