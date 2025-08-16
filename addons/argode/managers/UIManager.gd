# UIManager.gd
# v2設計: UI管理システム - 統合版
# v2.5統合: UIElementDiscoveryManager機能統合
extends CanvasLayer

# === 統合: MessageDisplayManager機能のためのpreload ===
const RubyParser = preload("res://addons/argode/ui/ruby/RubyParser.gd")

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
	if current_screen:
		print("✅ Using v2 direct display_message_with_effects()")
		# 無限ループを避けるため、直接display_message_with_effectsを呼び出し
		display_message_with_effects(display_name, message, name_color)
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
	
	# 直接的なUI要素制御（無限ループ回避のためcurrent_screen経由はしない）
	_display_choices_directly(choices)

func _display_choices_directly(choices: Array):
	"""選択肢を直接UI要素に表示（無限ループ回避版）"""
	print("🔍 Attempting to display choices directly")
	
	# ChoiceContainerの動的発見を試行
	if not choice_container and current_screen:
		choice_container = current_screen.find_child("ChoiceContainer", true, false)
		print("🔍 Dynamically found ChoiceContainer: ", choice_container)
	
	# さらに具体的な探索: VBoxContainer を探す
	var choice_vbox = null
	if current_screen:
		choice_vbox = current_screen.find_child("VBoxContainer", true, false)
		if choice_vbox and choice_vbox.get_parent().name.contains("Choice"):
			print("🔍 Found choice VBoxContainer: ", choice_vbox)
		else:
			choice_vbox = null
	
	# choice_container または choice_vbox のどちらかを使用
	var target_container = choice_container if choice_container else choice_vbox
	
	if target_container:
		print("✅ Using container: ", target_container, " (Type: ", target_container.get_class(), ")")
		
		# Clear existing choice buttons
		if target_container.get_children() != null:
			for child in target_container.get_children():
				child.queue_free()
		
		# Create buttons for each choice
		for i in range(choices.size()):
			var button = Button.new()
			button.text = str(i + 1) + ". " + choices[i]
			button.pressed.connect(_on_choice_button_pressed.bind(i))
			target_container.add_child(button)
		
		# ChoiceContainerとその親を表示
		target_container.visible = true
		if target_container.get_parent():
			target_container.get_parent().visible = true
			print("📱 Container and parent set visible")
		
		# 追加: コンテナ階層を強制的に表示
		var current_node = target_container
		while current_node:
			current_node.visible = true
			# modulateプロパティを持つノードのみに適用
			if current_node.has_method("set_modulate"):
				current_node.modulate.a = 1.0  # 透明度確保
			if current_node == current_screen:
				break
			current_node = current_node.get_parent()
		
		print("🔍 Final choice container visibility: %s" % target_container.visible)
		print("🔍 Final choice container modulate: %s" % target_container.modulate)
		
		# choice_containerの参照を更新
		if not choice_container:
			choice_container = target_container
	else:
		print("❌ No choice container found - choices won't be displayed")
		print("🔍 Available children in current_screen:")
		if current_screen:
			_debug_print_children(current_screen, 0)

func _debug_print_children(node: Node, depth: int):
	"""デバッグ用: ノードの子要素を再帰的に出力"""
	var indent = ""
	for i in range(depth):
		indent += "  "
	print(indent + "- " + node.name + " (" + node.get_class() + ")")
	
	if depth < 3:  # 深度制限
		for child in node.get_children():
			_debug_print_children(child, depth + 1)

func _on_choice_button_pressed(choice_index: int):
	# Clear choice buttons
	if choice_container:
		for child in choice_container.get_children():
			child.queue_free()
		# ChoiceContainerを非表示
		choice_container.visible = false
	
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
	
	# v2優先: current_screenのTypewriterTextIntegrationManagerをチェック
	if current_screen and current_screen.typewriter_integration_manager:
		var typewriter_manager = current_screen.typewriter_integration_manager
		if typewriter_manager.has_method("is_typing_active"):
			var is_active = typewriter_manager.is_typing_active()
			print("⌨️ TypewriterIntegrationManager is active: ", is_active)
			return is_active
		else:
			print("❌ TypewriterIntegrationManager has no is_typing_active method")
	
	# フォールバック: 従来のsample_ui検索
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
	
	# v2優先: current_screenのTypewriterTextIntegrationManagerをチェック
	if current_screen and current_screen.typewriter_integration_manager:
		var typewriter_manager = current_screen.typewriter_integration_manager
		if typewriter_manager.has_method("skip_typing"):
			print("✅ Skipping typewriter via integration manager")
			typewriter_manager.skip_typing()
			return
		else:
			print("❌ TypewriterIntegrationManager has no skip_typing method")
	
	# フォールバック: 従来のsample_ui検索
	var sample_ui = _find_adv_game_ui(get_tree().current_scene)
	if sample_ui:
		var typewriter = sample_ui.get("typewriter")
		if typewriter and typewriter.has_method("skip_typing"):
			print("✅ Skipping typewriter via sample UI")
			typewriter.skip_typing()
		else:
			print("❌ Cannot skip typewriter")
	else:
		print("❌ No typewriter found to skip")

func handle_input_for_argode(event) -> bool:
	"""ADVエンジン用の入力処理 - タイプライター状態を考慮"""
	print("🔍 Checking typewriter state...")
	
	# TypewriterTextの状態確認
	var is_typing_active = false
	if current_screen and current_screen.typewriter_integration_manager:
		if current_screen.typewriter_integration_manager.has_method("is_typing_active"):
			is_typing_active = current_screen.typewriter_integration_manager.is_typing_active()
			print("✅ TypewriterIntegrationManager is_typing_active: ", is_typing_active)
		else:
			print("❌ TypewriterIntegrationManager has no is_typing_active method")
	else:
		print("❌ No TypewriterIntegrationManager available")
	
	# Sample UI確認（後方互換性）
	var sample_ui = _find_adv_game_ui(get_tree().current_scene)
	if not sample_ui:
		print("❌ No sample UI found")
	
	if event.is_action_pressed("ui_accept"):
		print("🎮 Enter key pressed - checking typewriter...")
		if is_typing_active:
			# タイプライター中ならスキップ
			print("⌨️ Skipping typewriter...")
			if current_screen and current_screen.typewriter_integration_manager:
				current_screen.typewriter_integration_manager.skip_typing()
				print("⏭️ Typewriter skip triggered")
			print("✅ Input consumed by typewriter")
			return true  # 入力を消費（次に進まない）
		else:
			# タイプライター完了済みなら次に進む
			print("➡️ Typewriter not active, allowing ADV engine to process")
			print("➡️ UIManager returned false, proceeding with ArgodeScreen logic")
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

# === 統合: UIElementDiscoveryManager機能 ===

func discover_ui_elements(
	target_root: Node,
	message_box_path: NodePath = NodePath(""),
	name_label_path: NodePath = NodePath(""),
	message_label_path: NodePath = NodePath(""),
	choice_container_path: NodePath = NodePath(""),
	choice_panel_path: NodePath = NodePath(""),
	choice_vbox_path: NodePath = NodePath(""),
	continue_prompt_path: NodePath = NodePath("")
) -> Dictionary:
	"""UI要素を自動発見（UIElementDiscoveryManager統合）"""
	
	if not target_root:
		print("❌ UIManager: No root node provided for UI element discovery")
		return {}
	
	print("🔍 UIManager: Starting UI element discovery")
	print("  - Root node: ", target_root.name, " (", target_root.get_class(), ")")
	
	# @exportで指定されたNodePathを優先使用
	var message_box = _get_ui_node_from_path_or_fallback(target_root, message_box_path, "MessageBox")
	var name_label = _get_ui_node_from_path_or_fallback(target_root, name_label_path, "NameLabel", message_box)
	var message_label = _get_ui_node_from_path_or_fallback(target_root, message_label_path, "MessageLabel", message_box)
	
	var choice_container = _get_ui_node_from_path_or_fallback(target_root, choice_container_path, "ChoiceContainer")
	var choice_panel = _get_ui_node_from_path_or_fallback(target_root, choice_panel_path, "ChoicePanel", choice_container)
	var choice_vbox = _get_ui_node_from_path_or_fallback(target_root, choice_vbox_path, "VBoxContainer", choice_panel)
	
	var continue_prompt = _get_ui_node_from_path_or_fallback(target_root, continue_prompt_path, "ContinuePrompt")
	
	# UIManagerの内部参照を更新
	if name_label:
		self.name_label = name_label
	if message_label:
		self.text_label = message_label
	if choice_vbox:
		self.choice_container = choice_vbox
	
	var discovered_elements = {
		"message_box": message_box,
		"name_label": name_label,
		"message_label": message_label,
		"choice_container": choice_container,
		"choice_panel": choice_panel,
		"choice_vbox": choice_vbox,
		"continue_prompt": continue_prompt
	}
	
	print("✅ UIManager: UI element discovery complete - elements found: ", discovered_elements.keys().size())
	return discovered_elements

func _get_ui_node_from_path_or_fallback(root_node: Node, node_path: NodePath, fallback_name: String, parent_node: Node = null) -> Node:
	"""NodePathが指定されていればそれを使用、なければ自動発見（UIElementDiscoveryManager統合）"""
	
	# 1. @export NodePathが指定されている場合
	if not node_path.is_empty():
		var node = root_node.get_node_or_null(node_path)
		if node:
			print("   ✅ UIManager: Using NodePath: ", fallback_name, " -> ", node_path, " (", node.get_class(), ")")
			return node
		else:
			print("   ⚠️ UIManager: NodePath not found: ", node_path, " for ", fallback_name)
	
	# 2. フォールバック：自動発見
	var search_root = parent_node if parent_node else root_node
	var node = search_root.find_child(fallback_name, true, false)
	
	if node:
		print("   🔍 UIManager: Auto-discovered: ", fallback_name, " -> ", node.get_path(), " (", node.get_class(), ")")
	else:
		print("   ❌ UIManager: Not found: ", fallback_name)
	
	return node

# === 統合: MessageDisplayManager機能 ===

func display_message_with_effects(
	character_name: String = "", 
	message: String = "", 
	name_color: Color = Color.WHITE, 
	override_multi_label_ruby: bool = false
):
	"""メッセージを表示する（MessageDisplayManager統合）"""
	print("🔍 [UIManager] display_message_with_effects called:")
	print("  - character: ", character_name, ", message: ", message)
	print("  - text_label available: ", text_label != null)
	print("  - current_screen available: ", current_screen != null)
	
	if not text_label:
		print("❌ UIManager: MessageLabel not available, attempting to discover UI elements")
		# UI要素の再発見を試行
		if current_screen:
			discover_ui_elements(current_screen)
		if not text_label:
			print("❌ UIManager: Still no MessageLabel found after discovery")
			return
	
	# UI要素の表示制御
	if current_sample_ui:
		current_sample_ui.visible = true
	
	# ChoiceContainerを確実に非表示にする
	if choice_container:
		choice_container.visible = false
		print("🔍 UIManager: ChoiceContainer set to invisible")
	
	# current_screenからもChoiceContainerを探して非表示にする
	if current_screen:
		var screen_choice_container = current_screen.find_child("ChoiceContainer", true, false)
		if screen_choice_container:
			screen_choice_container.visible = false
			print("🔍 UIManager: Screen ChoiceContainer set to invisible")
	
	# ContinuePromptも初期は非表示にする
	var continue_prompt = get_node_or_null("ContinuePrompt")
	if not continue_prompt and current_screen:
		continue_prompt = current_screen.find_child("ContinuePrompt", true, false)
	if continue_prompt:
		continue_prompt.visible = false
	
	# キャラクター名の設定
	if character_name.is_empty():
		if name_label:
			name_label.visible = false
	else:
		if name_label:
			name_label.text = character_name
			name_label.modulate = name_color
			name_label.visible = true
	
	# メッセージ表示処理
	_display_message_text(message, override_multi_label_ruby)
	
	print("✅ UIManager: Message display complete")

func _display_message_text(message: String, override_multi_label_ruby: bool = false):
	"""メッセージテキストの表示処理（内部メソッド）"""
	if not text_label:
		return
	
	# 改行コードの変換処理
	var processed_message = message.replace("\\n", "\n")
	
	# RubyRichTextLabel対応
	if text_label.get_class() == "RubyRichTextLabel" or text_label.has_method("set_ruby_data"):
		print("🔤 UIManager: Using RubyRichTextLabel for message display")
		
		# ルビ解析とテキスト設定（正しいメソッド名で呼び出し）
		var parsed_result = RubyParser.parse_ruby_syntax(processed_message)
		
		if parsed_result.rubies.size() > 0:
			text_label.set_ruby_data(parsed_result.rubies)
			# タイプライター機能を使用（TypewriterTextIntegrationManager経由）
			if current_screen and current_screen.typewriter_integration_manager:
				current_screen.typewriter_integration_manager.start_typing(parsed_result.text)
				print("🔤 UIManager: Started typewriter via integration manager with %d ruby entries" % parsed_result.rubies.size())
			else:
				text_label.text = parsed_result.text
				print("🔤 UIManager: Set text directly (no typewriter integration)")
		else:
			# ルビなしの場合もタイプライター使用
			if current_screen and current_screen.typewriter_integration_manager:
				current_screen.typewriter_integration_manager.start_typing(processed_message)
				print("🔤 UIManager: Started typewriter for text without rubies")
			else:
				text_label.text = processed_message
			text_label.clear_ruby_data() if text_label.has_method("clear_ruby_data") else null
	else:
		# 通常のRichTextLabel - タイプライター機能使用
		if current_screen and current_screen.typewriter_integration_manager:
			current_screen.typewriter_integration_manager.start_typing(processed_message)
			print("🔤 UIManager: Started typewriter for standard RichTextLabel")
		else:
			text_label.text = processed_message
	
	# タイプライター完了後にContinuePromptを表示するシグナル接続
	_setup_typewriter_signals()
	
	print("📝 UIManager: Message text set with typewriter functionality")

func _setup_typewriter_signals():
	"""タイプライター完了シグナルの設定"""
	if not current_screen or not current_screen.typewriter_integration_manager:
		return
	
	# TypewriterTextIntegrationManagerのシグナルに接続
	var typewriter_manager = current_screen.typewriter_integration_manager
	if typewriter_manager.has_signal("typing_finished") and not typewriter_manager.is_connected("typing_finished", _on_typewriter_finished):
		typewriter_manager.connect("typing_finished", _on_typewriter_finished)
		print("🔗 UIManager: Connected to typewriter_integration_manager.typing_finished signal")

func _on_typewriter_finished():
	"""タイプライター完了時の処理"""
	# ContinuePromptを表示
	var continue_prompt = get_node_or_null("ContinuePrompt")
	if not continue_prompt and current_screen:
		continue_prompt = current_screen.find_child("ContinuePrompt", true, false)
	if continue_prompt:
		continue_prompt.visible = true
		print("📱 UIManager: ContinuePrompt shown after typewriter finished")
