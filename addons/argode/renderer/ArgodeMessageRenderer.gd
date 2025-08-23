extends RefCounted
class_name ArgodeMessageRenderer

## メッセージ表示の統括クラス（リファクタリング後）
## 各専門レンダラーを統制するコーディネーター

# メッセージウィンドウの参照
var message_window: ArgodeMessageWindow = null
var message_canvas: Control = null

# 専門レンダラー
var text_renderer: ArgodeTextRenderer = null
var ruby_renderer: ArgodeRubyRenderer = null
var decoration_renderer: ArgodeDecorationRenderer = null
var animation_coordinator: ArgodeAnimationCoordinator = null

# タイプライターサービス
var typewriter_service: ArgodeTypewriterService = null

# インラインコマンド処理サービス
var inline_processor_service: RefCounted = null

# 状態管理
var current_text: String = ""  # 現在のテキスト
var current_display_length: int = 0  # 現在の表示文字数

# タイプライター完了時のコールバック
var on_typewriter_completed: Callable

func _init(window: ArgodeMessageWindow = null):
	_initialize_renderers()
	if window:
		set_message_window(window)

## アニメーション設定をカスタマイズ
func configure_text_animation(config: Dictionary):
	"""
	テキストアニメーション設定を変更
	使用例:
	renderer.configure_text_animation({
		"fade_in": {"duration": 0.5, "enabled": true},
		"slide_down": {"duration": 0.3, "offset": -20.0, "enabled": true},
		"scale": {"duration": 0.2, "enabled": true}
	})
	"""
	if animation_coordinator and animation_coordinator.character_animation:
		animation_coordinator.character_animation.setup_custom_animation(config)
		ArgodeSystem.log("📝 Text animation configuration updated")

## アニメーション設定プリセット
func set_animation_preset(preset_name: String):
	"""
	プリセットアニメーション設定を適用
	"""
	var config = {}
	
	match preset_name:
		"default":
			config = {
				"fade_in": {"duration": 0.3, "enabled": true},
				"slide_down": {"duration": 0.4, "offset": -8.0, "enabled": true},
				"scale": {"enabled": false}
			}
		"fast":
			config = {
				"fade_in": {"duration": 0.15, "enabled": true},
				"slide_down": {"duration": 0.2, "offset": -5.0, "enabled": true},
				"scale": {"enabled": false}
			}
		"dramatic":
			config = {
				"fade_in": {"duration": 0.6, "enabled": true},
				"slide_down": {"duration": 0.8, "offset": -20.0, "enabled": true},
				"scale": {"duration": 0.4, "enabled": true}
			}
		"simple":
			config = {
				"fade_in": {"duration": 0.2, "enabled": true},
				"slide_down": {"enabled": false},
				"scale": {"enabled": false}
			}
		"none":
			config = {
				"fade_in": {"enabled": false},
				"slide_down": {"enabled": false},
				"scale": {"enabled": false}
			}
		_:
			ArgodeSystem.log("⚠️ Unknown animation preset: %s" % preset_name)
			return
	
	configure_text_animation(config)
	ArgodeSystem.log("🎭 Animation preset '%s' applied" % preset_name)

## 各専門レンダラーを初期化
func _initialize_renderers():
	"""各専門レンダラーを初期化"""
	text_renderer = ArgodeTextRenderer.new()
	ruby_renderer = ArgodeRubyRenderer.new()
	decoration_renderer = ArgodeDecorationRenderer.new()
	animation_coordinator = ArgodeAnimationCoordinator.new()
	
	# インラインコマンド処理サービスを初期化
	var inline_processor_script = load("res://addons/argode/services/ArgodeInlineProcessorService.gd")
	if inline_processor_script:
		inline_processor_service = inline_processor_script.new()
		ArgodeSystem.log("✅ MessageRenderer: InlineProcessorService initialized", ArgodeSystem.LOG_LEVEL.DEBUG)
	else:
		ArgodeSystem.log("❌ Failed to load InlineProcessorService", ArgodeSystem.LOG_LEVEL.CRITICAL)
	
	# アニメーションシステムを初期化
	animation_coordinator.initialize_character_animation()
	
	# アニメーション完了コールバックを設定
	animation_coordinator.set_animation_completion_callback(_on_animation_completed)
	
	ArgodeSystem.log("✅ MessageRenderer: All specialized renderers initialized")

## メッセージウィンドウを設定
func set_message_window(window: ArgodeMessageWindow):
	message_window = window
	_find_message_canvas()

## MessageCanvasノードを探す
func _find_message_canvas():
	if not message_window:
		return
	
	# %MessageCanvasでユニーク取得を試行
	message_canvas = message_window.get_node_or_null("%MessageCanvas")
	
	if not message_canvas:
		# ノード名で直接検索
		message_canvas = message_window.get_node_or_null("MessageContainer/MessageCanvas")
	
	if not message_canvas:
		# クラス名で走査
		message_canvas = _find_node_by_class(message_window, "ArgodeMessageCanvas")
	
	if message_canvas:
		# ArgodeMessageCanvasかどうかを確認
		if message_canvas.has_method("set_draw_callback"):
			# 描画コールバックを設定
			message_canvas.set_draw_callback(_draw_message_content)
		else:
			ArgodeSystem.log("⚠️ MessageCanvas found but doesn't have set_draw_callback method", 1)
		
		# タイプライターサービスを初期化
		_initialize_typewriter_service()
		
		# AnimationCoordinatorにcanvasを設定
		if animation_coordinator:
			animation_coordinator.set_message_canvas(message_canvas)
		
		ArgodeSystem.log("✅ MessageCanvas found and configured")
	else:
		ArgodeSystem.log("❌ MessageCanvas not found in message window", 2)
		# デバッグ: 子ノードを列挙
		ArgodeSystem.log("🔍 Available child nodes in message window:")
		_debug_print_node_tree(message_window, 0, 3)

## クラス型でノードを検索
func _find_node_by_class(node: Node, target_class_name: String) -> Node:
	# 現在のノードをチェック
	if node.get_script() and node.get_script().get_global_name() == target_class_name:
		return node
	
	# 子ノードを再帰的に検索
	for child in node.get_children():
		var result = _find_node_by_class(child, target_class_name)
		if result:
			return result
	
	return null

## タイプライターサービスを初期化
func _initialize_typewriter_service():
	# 動的にクラスを作成
	var TypewriterServiceClass = load("res://addons/argode/services/ArgodeTypewriterService.gd")
	typewriter_service = TypewriterServiceClass.new()
	
	# コールバックを設定
	typewriter_service.set_callbacks(_on_character_typed, _on_typing_finished)
	
	# ArgodeSystemにサービスを登録
	ArgodeSystem.register_service("ArgodeTypewriterService", typewriter_service)
	ArgodeSystem.register_service("TypewriterService", typewriter_service)  # 別名も登録
	
	ArgodeSystem.log("✅ MessageRenderer: Typewriter service initialized")

## タイプライター効果での文字タイプ時のコールバック
func _on_character_typed(character: String, current_display: String):
	# 現在の表示文字数を更新
	current_display_length = current_display.length()
	
	# メッセージキャンバスに現在の表示テキストを設定
	if message_canvas:
		message_canvas.set_message_text(current_display)
	
	# アニメーションコーディネーターに通知
	if animation_coordinator:
		animation_coordinator.trigger_character_animation(current_display_length - 1)
	
	# ルビレンダラーに表示進捗を通知
	if ruby_renderer:
		ruby_renderer.update_ruby_visibility(current_display_length, message_canvas)

## タイプライター効果完了時のコールバック
func _on_typing_finished(final_text: String):
	ArgodeSystem.log_workflow("✅ MessageRenderer._on_typing_finished called: %s" % final_text.substr(0, 30) + ("..." if final_text.length() > 30 else ""))
	ArgodeSystem.log_workflow("🔍 Typewriter skipped: %s" % (typewriter_service.was_typewriter_skipped() if typewriter_service else "null"))
	
	# アニメーションコーディネーターに完了を通知
	if animation_coordinator:
		# スキップされた場合のみアニメーションも強制完了
		if typewriter_service and typewriter_service.was_typewriter_skipped():
			ArgodeSystem.log_workflow("⏭️ Typewriter was skipped - forcing animation completion")
			animation_coordinator.skip_all_animations()
			_notify_message_completion()
		else:
			# 自然完了の場合はアニメーション完了を待つ
			ArgodeSystem.log_workflow("⏳ Typewriter completed naturally - waiting for animations...")
			animation_coordinator.wait_for_animations_completion()
	else:
		# アニメーションコーディネーターが無効な場合は即座に完了通知
		ArgodeSystem.log_workflow("⚠️ No animation coordinator - immediate completion notification")
		ArgodeSystem.log("🔄 No animation coordinator, completing immediately")
		_notify_message_completion()

## アニメーション完了時のコールバック
func _on_animation_completed():
	ArgodeSystem.log("✅ All animations completed")
	_notify_message_completion()

## メッセージ表示完了を通知
func _notify_message_completion():
	# StatementManagerに完了を通知
	ArgodeSystem.log_workflow("📢 MessageRenderer._notify_message_completion called")
	ArgodeSystem.log_workflow("🔍 Callback valid: %s" % on_typewriter_completed.is_valid())
	if on_typewriter_completed.is_valid():
		ArgodeSystem.log_workflow("📢 Calling typewriter completion callback to StatementManager")
		on_typewriter_completed.call()
		ArgodeSystem.log_workflow("📢 Typewriter completion callback executed")
	else:
		ArgodeSystem.log_workflow("⚠️ Typewriter completion callback not set")

# ===========================
# UIManager Compatibility Methods
# ===========================
func display_message(text: String, character_name: String = "", properties: Dictionary = {}) -> void:
	"""
	UIManager compatibility method for displaying messages.
	This bridges UIManager's display_message call to our render_message method.
	
	Args:
		text: The message text to display
		character_name: Optional character name
		properties: Additional display properties
	"""
	ArgodeSystem.log("🔍 MessageRenderer.display_message called - text: '%s', character: '%s'" % [text, character_name], ArgodeSystem.LOG_LEVEL.DEBUG)
	
	# === 新しいメッセージ開始時：完全なエフェクトクリア ===
	_clear_all_effects_for_new_message()
	
	# インラインコマンド処理を行う
	if inline_processor_service:
		var process_result = inline_processor_service.process_text_with_inline_commands(text)
		
		if process_result.success:
			var display_text = process_result.display_text
			var position_commands = process_result.position_commands
			
			# インラインコマンドがある場合は専用メソッドを使用
			if position_commands.size() > 0:
				ArgodeSystem.log("🔍 Using render_message_with_position_commands - commands: %d" % position_commands.size(), ArgodeSystem.LOG_LEVEL.DEBUG)
				render_message_with_position_commands(character_name, display_text, position_commands, inline_processor_service.inline_command_manager)
			else:
				# インラインコマンドがない場合は通常のレンダリング
				ArgodeSystem.log("🔍 Using standard render_message", ArgodeSystem.LOG_LEVEL.DEBUG)
				render_message(character_name, display_text)
		else:
			# インラインコマンド処理が失敗した場合はフォールバック
			ArgodeSystem.log("⚠️ Inline processing failed: %s - using fallback" % process_result.error, ArgodeSystem.LOG_LEVEL.WORKFLOW)
			render_message(character_name, text)
	else:
		# InlineProcessorServiceがない場合はフォールバック
		ArgodeSystem.log("⚠️ InlineProcessorService not available - using fallback", ArgodeSystem.LOG_LEVEL.WORKFLOW)
		render_message(character_name, text)

# ===========================
# Main Message Rendering Pipeline
# ===========================

## メッセージをレンダリング
func render_message(character_name: String, text: String):
	ArgodeSystem.log("🔍 render_message called - canvas available: %s, window available: %s" % [message_canvas != null, message_window != null])
	
	if not message_canvas:
		ArgodeSystem.log("❌ MessageCanvas not available for rendering", 2)
		# 再度MessageCanvasを検索
		if message_window:
			ArgodeSystem.log("🔄 Attempting to re-find MessageCanvas...")
			_find_message_canvas()
			if message_canvas:
				ArgodeSystem.log("✅ MessageCanvas found on retry")
			else:
				ArgodeSystem.log("❌ MessageCanvas still not found after retry")
				return
		else:
			return
	
	# メッセージウィンドウを表示
	if message_window:
		message_window.visible = true
		
		# キャラクター名はMessageWindowのname_plateに表示
		if character_name and not character_name.is_empty():
			message_window.set_character_name(character_name)
		else:
			message_window.hide_character_name()
	
	# 現在のテキストを保存
	current_text = text
	current_display_length = 0
	
	# StatementManagerから登録済みアニメーション効果を取得して適用
	_apply_statement_manager_animations()
	
	# アニメーションシステムを初期化
	if animation_coordinator:
		animation_coordinator.initialize_for_text(text.length())
	
	# タイプライター効果を開始
	if typewriter_service:
		typewriter_service.start_typing(text, 0.05)  # 50ms間隔
		ArgodeSystem.log("🎨 Message rendering started with typewriter: [%s] %s" % [character_name, text.substr(0, 20) + ("..." if text.length() > 20 else "")])
	else:
		# フォールバック：即座に表示
		message_canvas.set_message_text(text)
		ArgodeSystem.log("🎨 Message rendered instantly: [%s] %s" % [character_name, text])

## 位置ベースコマンド付きメッセージをレンダリング
func render_message_with_position_commands(character_name: String, display_text: String, position_commands: Array, inline_command_manager: ArgodeInlineCommandManager):
	ArgodeSystem.log("🔍 render_message_with_position_commands called - canvas available: %s" % [message_canvas != null])
	
	if not message_canvas:
		ArgodeSystem.log("❌ MessageCanvas not available for rendering", 2)
		# 再度MessageCanvasを検索
		if message_window:
			ArgodeSystem.log("🔄 Attempting to re-find MessageCanvas...")
			_find_message_canvas()
			if message_canvas:
				ArgodeSystem.log("✅ MessageCanvas found on retry")
			else:
				ArgodeSystem.log("❌ MessageCanvas still not found after retry")
				return
		else:
			return
	
	# 各レンダラーにデータを設定
	ruby_renderer.extract_ruby_data(position_commands)
	decoration_renderer.extract_decoration_data(position_commands)
	
	# StatementManagerから登録済みアニメーション効果を取得して適用
	_apply_statement_manager_animations()
	
	# アニメーションコーディネーターを初期化
	if animation_coordinator:
		animation_coordinator.initialize_for_text(display_text.length())
		# 範囲別アニメーション設定を登録
		animation_coordinator.set_range_animation_configs(decoration_renderer)
	
	# メッセージウィンドウを表示
	if message_window:
		message_window.visible = true
		
		# キャラクター名はMessageWindowのname_plateに表示
		if character_name and not character_name.is_empty():
			message_window.set_character_name(character_name)
		else:
			message_window.hide_character_name()
	
	# 現在のテキストを保存
	current_text = display_text
	current_display_length = 0
	
	# 位置ベースタイプライター効果を開始
	if typewriter_service:
		typewriter_service.start_typing_with_position_commands(display_text, position_commands, inline_command_manager, 0.05)
		ArgodeSystem.log("🎨 Message rendering started with position commands: [%s] %s" % [character_name, display_text.substr(0, 20) + ("..." if display_text.length() > 20 else "")])
	else:
		# フォールバック：即座に表示
		message_canvas.set_message_text(display_text)
		ArgodeSystem.log("🎨 Message rendered instantly with position commands: [%s] %s" % [character_name, display_text])

## 実際の描画処理（CanvasからCallableで呼ばれる）
func _draw_message_content(canvas, character_name: String, text: String):
	# 基本的な描画設定
	var canvas_size = canvas.get_canvas_size()
	var margin = Vector2(20, 20)
	var line_spacing = 5.0
	
	# MessageCanvasのフォントシステムを使用
	var message_font = canvas.get_argode_font()
	var font_size = canvas.font_size
	
	# 色設定
	var text_color = Color.WHITE
	
	var draw_position = margin
	
	# メッセージテキストのみを描画（キャラクター名はMessageWindowが担当）
	if text and not text.is_empty():
		var available_width = canvas_size.x - (margin.x * 2)
		
		# コールバック関数を作成
		var decoration_callback = func(char: String, font: Font, font_size: int, base_color: Color, current_position: int):
			var decorations = decoration_renderer.get_active_decorations_at_position(current_position)
			return decoration_renderer.calculate_char_render_info(char, font, font_size, base_color, decorations)
		
		var animation_callback = func(char_index: int):
			return animation_coordinator.get_character_animation_values(char_index)
		
		# 各レンダラーに処理を委譲
		text_renderer.draw_character_by_character(canvas, text, draw_position, available_width, message_font, font_size, text_color, current_display_length, decoration_callback, animation_callback)
		
		# ルビを描画
		ruby_renderer.draw_ruby_text(canvas, text, draw_position, message_font, font_size, text_renderer, current_display_length)

## メッセージウィンドウを非表示
func hide_message():
	if message_window:
		message_window.visible = false
		ArgodeSystem.log("👻 Message window hidden")

## メッセージをクリア
func clear_message():
	if message_canvas:
		message_canvas.set_message_text("")
	
	current_text = ""
	current_display_length = 0
	ArgodeSystem.log("🧹 Message cleared")

## タイプライター効果が動作中かチェック
func is_typewriter_active() -> bool:
	var result = false
	if typewriter_service:
		result = typewriter_service.is_currently_typing()
		ArgodeSystem.log_workflow("🔍 MessageRenderer.is_typewriter_active() → %s (from TypewriterService)" % result)
	else:
		ArgodeSystem.log_workflow("🔍 MessageRenderer.is_typewriter_active() → false (no TypewriterService)")
	return result

## タイプライター効果を即座に完了
func complete_typewriter():
	if typewriter_service and typewriter_service.is_currently_typing():
		ArgodeSystem.log("⏭️ Typewriter effect being completed by user (SKIP)")
		typewriter_service.complete_typing()
		
		# アニメーションもスキップ（ユーザーが明示的にスキップした場合のみ）
		if animation_coordinator:
			animation_coordinator.skip_all_animations()
			ArgodeSystem.log("⏭️ Animations skipped due to user skip")
			
			# アニメーション完了を即座に通知
			_notify_message_completion()
	else:
		ArgodeSystem.log("⚠️ Typewriter already completed or not running")

## タイプライター効果を停止
func stop_typewriter():
	if typewriter_service:
		typewriter_service.stop_typing()
		ArgodeSystem.log("⏹️ Typewriter effect stopped")

## タイプライター完了コールバックを設定
func set_typewriter_completion_callback(callback: Callable):
	on_typewriter_completed = callback

## RubyCommandから直接ルビを追加（下位互換性）
func add_ruby_display(base_text: String, ruby_text: String):
	if ruby_renderer:
		ruby_renderer.add_ruby_display(base_text, ruby_text, current_text, current_display_length)

## StatementManagerからアニメーション効果を取得して適用
func _apply_statement_manager_animations():
	"""StatementManagerの登録済みアニメーション効果をCharacterAnimationに適用"""
	ArgodeSystem.log("🎭 _apply_statement_manager_animations called")
	
	var statement_manager = ArgodeSystem.StatementManager
	if not statement_manager:
		ArgodeSystem.log("⚠️ StatementManager not found")
		return
	
	if not statement_manager.has_method("get_message_animation_effects"):
		ArgodeSystem.log("⚠️ StatementManager doesn't have get_message_animation_effects method")
		return
	
	var animation_effects = statement_manager.get_message_animation_effects()
	ArgodeSystem.log("🎭 Retrieved %d animation effects from StatementManager" % animation_effects.size())
	
	if animation_effects.is_empty():
		ArgodeSystem.log("🎭 No animation effects registered in StatementManager")
		return
	
	# AnimationCoordinatorのCharacterAnimationに効果を適用
	if animation_coordinator and animation_coordinator.character_animation:
		ArgodeSystem.log("🎭 Applying effects to CharacterAnimation")
		var config = {}
		
		# StatementManagerの効果をCharacterAnimation設定に変換
		for effect in animation_effects:
			ArgodeSystem.log("🎭 Processing effect: %s" % str(effect))
			match effect.get("type", ""):
				"fade":
					config["fade_in"] = {
						"duration": effect.get("duration", 0.3),
						"enabled": true
					}
					ArgodeSystem.log("🎭 Added fade_in config: %s" % str(config["fade_in"]))
				"slide":
					config["slide_down"] = {
						"duration": effect.get("duration", 0.4),
						"offset": effect.get("offset_y", -4.0),
						"enabled": true
					}
					ArgodeSystem.log("🎭 Added slide_down config: %s" % str(config["slide_down"]))
				"scale":
					config["scale"] = {
						"duration": effect.get("duration", 0.2),
						"enabled": true
					}
					ArgodeSystem.log("🎭 Added scale config: %s" % str(config["scale"]))
		
		# 設定を適用
		if not config.is_empty():
			ArgodeSystem.log("🎭 Calling setup_custom_animation with config: %s" % str(config))
			animation_coordinator.character_animation.setup_custom_animation(config)
			ArgodeSystem.log("🎭 Applied %d animation effects from StatementManager" % animation_effects.size())
		else:
			ArgodeSystem.log("⚠️ No valid animation effects could be converted")
	else:
		ArgodeSystem.log("⚠️ AnimationCoordinator or CharacterAnimation not available")

## デバッグ: ノードツリーを出力
func _debug_print_node_tree(node: Node, depth: int, max_depth: int):
	if depth > max_depth:
		return
	
	var indent = "  ".repeat(depth)
	var node_info = "%s%s (%s)" % [indent, node.name, node.get_class()]
	if node.get_script():
		node_info += " [%s]" % node.get_script().get_global_name()
	
	ArgodeSystem.log(node_info)
	
	for child in node.get_children():
		_debug_print_node_tree(child, depth + 1, max_depth)

## 新しいメッセージ開始時の完全エフェクトクリア
func _clear_all_effects_for_new_message():
	"""新しいメッセージ表示開始時に前のメッセージの全エフェクトを完全クリア"""
	ArgodeSystem.log("🧹 MessageRenderer: Clearing all effects for new message")
	
	# MessageCanvasのアニメーション停止
	if message_canvas:
		message_canvas.stop_animation_updates()
		ArgodeSystem.log("⏹️ Animation updates stopped on MessageCanvas")
	
	# DecorationRendererのデータクリア
	if decoration_renderer:
		decoration_renderer.clear_decoration_data()
		ArgodeSystem.log("🎨 Decoration data cleared")
	
	# RubyRendererのデータクリア
	if ruby_renderer and ruby_renderer.has_method("clear_ruby_data"):
		ruby_renderer.clear_ruby_data()
		ArgodeSystem.log("💎 Ruby data cleared")
	
	# TypewriterServiceの状態クリア（待機コマンド対応）
	var typewriter_service = ArgodeSystem.get_service("TypewriterService")
	if typewriter_service:
		typewriter_service.pending_inline_waits.clear()
		typewriter_service.is_paused = false
		ArgodeSystem.log("⌨️ TypewriterService state cleared (waits and pause)")
	else:
		ArgodeSystem.log("⚠️ TypewriterService not found in ArgodeSystem services")
	
	# InlineCommandManagerの状態クリア（位置ベースコマンド対応）
	if inline_processor_service and inline_processor_service.inline_command_manager:
		inline_processor_service.inline_command_manager.position_commands.clear()
		ArgodeSystem.log("🎯 InlineCommandManager position commands cleared")
	
	# AnimationCoordinatorの状態クリア
	if animation_coordinator:
		animation_coordinator.range_animation_configs.clear()
		if animation_coordinator.character_animation:
			animation_coordinator.character_animation.current_time = 0.0
			animation_coordinator.character_animation.character_animations.clear()
		ArgodeSystem.log("✨ Animation coordinator state cleared")
	
	ArgodeSystem.log("✅ All effects cleared for new message")