extends RefCounted
class_name ArgodeMessageRenderer

## メッセージ表示の統括クラス（リファクタリング後）
## 各専門レンダラーを統制するコーディネーター

# メッセージウィンドウの参照
var message_window: ArgodeMessageWindow = null
var message_canvas: ArgodeMessageCanvas = null

# 専門レンダラー
var text_renderer: ArgodeTextRenderer = null
var ruby_renderer: ArgodeRubyRenderer = null
var decoration_renderer: ArgodeDecorationRenderer = null
var animation_coordinator: ArgodeAnimationCoordinator = null

# タイプライターサービス
var typewriter_service: ArgodeTypewriterService = null

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
		# クラス名で走査
		message_canvas = _find_node_by_class(message_window, "ArgodeMessageCanvas")
	
	if message_canvas:
		# 描画コールバックを設定
		message_canvas.set_draw_callback(_draw_message_content)
		
		# タイプライターサービスを初期化
		_initialize_typewriter_service()
		
		# AnimationCoordinatorにcanvasを設定
		if animation_coordinator:
			animation_coordinator.set_message_canvas(message_canvas)
	else:
		ArgodeSystem.log("❌ MessageCanvas not found in message window", 2)

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
	ArgodeSystem.log("✅ Typewriter effect completed: %s" % final_text.substr(0, 30) + ("..." if final_text.length() > 30 else ""))
	
	# アニメーションコーディネーターに完了を通知
	if animation_coordinator:
		# スキップされた場合のみアニメーションも強制完了
		if typewriter_service and typewriter_service.was_typewriter_skipped():
			ArgodeSystem.log("⏭️ Typewriter was skipped - forcing animation completion")
			animation_coordinator.skip_all_animations()
			_notify_message_completion()
		else:
			# 自然完了の場合はアニメーション完了を待つ
			ArgodeSystem.log("⏳ Typewriter completed naturally - waiting for animations...")
			animation_coordinator.wait_for_animations_completion()
	else:
		# アニメーションコーディネーターが無効な場合は即座に完了通知
		ArgodeSystem.log("🔄 No animation coordinator, completing immediately")
		_notify_message_completion()

## アニメーション完了時のコールバック
func _on_animation_completed():
	ArgodeSystem.log("✅ All animations completed")
	_notify_message_completion()

## メッセージ表示完了を通知
func _notify_message_completion():
	# StatementManagerに完了を通知
	if on_typewriter_completed.is_valid():
		ArgodeSystem.log("📢 Notifying typewriter completion to StatementManager")
		on_typewriter_completed.call()
	else:
		ArgodeSystem.log("⚠️ Typewriter completion callback not set")

## メッセージをレンダリング
func render_message(character_name: String, text: String):
	if not message_canvas:
		ArgodeSystem.log("❌ MessageCanvas not available for rendering", 2)
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
	if not message_canvas:
		ArgodeSystem.log("❌ MessageCanvas not available for rendering", 2)
		return
	
	# 各レンダラーにデータを設定
	ruby_renderer.extract_ruby_data(position_commands)
	decoration_renderer.extract_decoration_data(position_commands)
	
	# アニメーションコーディネーターを初期化
	if animation_coordinator:
		animation_coordinator.initialize_for_text(display_text.length())
	
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