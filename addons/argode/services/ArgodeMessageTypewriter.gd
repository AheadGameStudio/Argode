extends RefCounted
class_name ArgodeMessageTypewriter

## ArgodeMessageTypewr	# Phase 3: コマンド登録
	# if command_executor:
	# 	command_executor.register_commands_from_text(text)
	
	# # タイマー完全初期化（重複防止と速度更新）
	# if typing_timer:
	# 	typing_timer.stop()  # 既存タイマーを停止
	# 	typing_timer.wait_time = typing_speed
	
	# var start_msg_time = Time.get_ticks_msec()
	# ArgodeSystem.log_workflow("🎬 [MSG_START] Message '%s' starting at time: %d with speed: %.3f" % [text.substr(0, 20), start_msg_time, typing_speed])
	
	# ArgodeSystem.log_workflow("🎬 [Phase 3] Starting typing with command execution: '%s'" % [text.substr(0, 20) + ("..." if text.length() > 20 else "")])
	# _start_next_character()0 Phase 2
## タイプライター機能統合クラス - 基本機能実装版

# プリロード
const TypewriterTextParser = preload("res://addons/argode/services/TypewriterTextParser.gd")
const TypewriterCommandExecutor = preload("res://addons/argode/services/TypewriterCommandExecutor.gd")

# === 状態管理 ===
var current_text: String = ""
var display_text: String = ""
var position: int = 0
var is_typing: bool = false
var is_paused: bool = false
var typing_speed: float = 0.05

# Phase 2追加: 解析とタイマー
var parse_result = null
var typing_timer: Timer = null

# Phase 3追加: コマンド実行
var command_executor: TypewriterCommandExecutor = null

# GlyphSystem対応: GlyphManagerへの直接参照
var direct_glyph_manager: ArgodeGlyphManager = null

# === UI連携 ===
var message_canvas: Control = null

# === コールバック ===
var character_typed_callback: Callable
var typing_finished_callback: Callable

func _init():
	ArgodeSystem.log_workflow("🎬 [Phase 3] ArgodeMessageTypewriter with CommandExecutor initializing")
	_setup_typing_timer()
	_setup_command_executor()

func _setup_typing_timer():
	"""タイピング用タイマーを設定（Phase 2）"""
	typing_timer = Timer.new()
	typing_timer.wait_time = typing_speed
	typing_timer.timeout.connect(_on_typing_timer_timeout)
	typing_timer.one_shot = true
	
	# タイマーをシーンツリーに追加
	if ArgodeSystem.get_tree():
		ArgodeSystem.get_tree().root.add_child(typing_timer)
	
	ArgodeSystem.log_workflow("🎬 [Phase 2] Typing timer configured")

func _setup_command_executor():
	"""コマンド実行システムを設定（Phase 3）"""
	command_executor = TypewriterCommandExecutor.new()
	command_executor.initialize(self)
	ArgodeSystem.log_workflow("🎯 [Phase 3] Command executor configured")

## === 基本API ===

func start_typing(text: String, canvas_node = null, speed: float = 0.05):
	"""タイピングを開始（GlyphSystem対応版）"""
	if not text or text.length() == 0:
		ArgodeSystem.log_warning("[GlyphSystem] Empty text provided to typewriter")
		return
	
	# Phase 2: TypewriterTextParserでテキスト解析
	parse_result = TypewriterTextParser.parse_text(text)
	current_text = parse_result.plain_text
	display_text = ""
	position = 0
	typing_speed = speed
	is_typing = true
	is_paused = false
	
	# GlyphManager確実取得（重要）
	var glyph_manager = get_glyph_manager()
	if not glyph_manager:
		ArgodeSystem.log_workflow("❌ [CRITICAL] GlyphManager not available - text will not render!")
		return
	
	# Canvas設定（GlyphSystem対応）
	if canvas_node:
		message_canvas = canvas_node
		
		# GlyphSystemが利用可能かチェック
		if canvas_node.has_method("set_glyph_manager") and glyph_manager:
			# 新システム: GlyphManager設定
			canvas_node.set_glyph_manager(glyph_manager)
			ArgodeSystem.log_workflow("🎨 [GlyphSystem] Canvas connected to GlyphManager")
		elif canvas_node.has_method("set_draw_callback"):
			# フォールバック: 旧システム
			canvas_node.set_draw_callback(_draw_message_content)
			ArgodeSystem.log_workflow("🎨 [Legacy] Canvas using callback system")
	
	# Phase 3: コマンド登録
	if command_executor:
		command_executor.register_commands_from_text(text)
	
	# タイマー設定
	if typing_timer:
		typing_timer.wait_time = typing_speed
	
	ArgodeSystem.log_workflow("� [Phase 3] Starting typing with command execution: '%s'" % [text.substr(0, 20) + ("..." if text.length() > 20 else "")])
	_start_next_character()

func skip_typing():
	"""タイピングをスキップして完了"""
	if is_typing:
		if typing_timer:
			typing_timer.stop()
		_on_typing_finished()
		ArgodeSystem.log_workflow("⏭️ [Phase 2] Typing skipped to completion")

func stop_typing():
	"""タイピングを停止"""
	is_typing = false
	is_paused = false
	if typing_timer:
		typing_timer.stop()
	ArgodeSystem.log_workflow("⏹️ [Phase 2] Typing stopped")

func pause_typing():
	"""タイピングを一時停止（Phase 3）"""
	if is_typing and not is_paused:
		is_paused = true
		if typing_timer:
			typing_timer.stop()
		ArgodeSystem.log_workflow("⏸️ [Phase 3] Typing paused")

func resume_typing():
	"""タイピングを再開（Phase 3）"""
	if is_typing and is_paused:
		is_paused = false
		ArgodeSystem.log_workflow("▶️ [Phase 3] Typing resumed")
		# タイマー直接開始ではなく、次文字処理を呼び出し
		_start_next_character()

func is_currently_typing() -> bool:
	"""タイピング中かどうか"""
	return is_typing and not is_paused

## === UI連携 ===

func set_message_canvas(canvas: Control):
	"""メッセージキャンバスを設定"""
	message_canvas = canvas
	ArgodeSystem.log_workflow("🎨 [Phase 2] Message canvas set: %s" % canvas)

func set_callbacks(char_callback: Callable, finish_callback: Callable):
	"""コールバックを設定"""
	character_typed_callback = char_callback
	typing_finished_callback = finish_callback

## === 描画コールバック対応 ===

func _draw_message_content(canvas, character_name: String = ""):
	"""Canvas描画コールバック（Phase 2実装）"""
	if not canvas or not canvas.has_method("queue_redraw"):
		return
	
	# 現在の表示文字列を取得
	var current_display = display_text
	if not current_display and parse_result:
		current_display = TypewriterTextParser.get_substring_at_position(parse_result, position)
	
	# Canvasに描画をトリガー
	canvas.current_text = current_display
	canvas.queue_redraw()

## === 内部処理（Phase 2） ===

func _start_next_character():
	"""次の文字のタイピングを開始"""
	if not is_typing or is_paused:
		return
	
	if not parse_result or position >= parse_result.total_length:
		_on_typing_finished()
		return
	
	var start_time = Time.get_ticks_msec()
	
	# タイマー開始（重複起動防止）
	if typing_timer:
		if not typing_timer.is_stopped():
			typing_timer.stop()
		
		# wait_timeの更新は必要時のみ
		if typing_timer.wait_time != typing_speed:
			typing_timer.wait_time = typing_speed
		
		ArgodeSystem.log_workflow("⏱️ [TIMER] Starting timer for char %d - speed: %.3f, current_time: %d" % [position, typing_speed, start_time])
		typing_timer.start()

func _on_typing_timer_timeout():
	"""タイマータイムアウト時の処理（Phase 3拡張）"""
	var timeout_time = Time.get_ticks_msec()
	
	if not is_typing or is_paused:
		return
	
	if not parse_result or position >= parse_result.total_length:
		_on_typing_finished()
		return
	
	# Phase 3: Command実行チェック（文字進行前）
	if command_executor:
		command_executor.check_and_execute_commands(position)
		# wait実行中ならここで処理を中断
		if is_paused:
			return
	
	# 1文字追加
	position += 1
	display_text = TypewriterTextParser.get_substring_at_position(parse_result, position)
	
	ArgodeSystem.log_workflow("⏱️ [TIMER] Timeout for char %d at time: %d (speed was: %.3f)" % [position-1, timeout_time, typing_speed])
	
	# UI更新
	_update_display()
	
	# コールバック呼び出し
	if character_typed_callback.is_valid():
		# 現在追加された文字を取得
		var current_char = ""
		if parse_result and position > 0 and position <= parse_result.plain_text.length():
			current_char = parse_result.plain_text[position - 1]
		character_typed_callback.call(current_char, display_text)
	
	# 次の文字へ
	_start_next_character()

func _update_display():
	"""表示を更新（GlyphSystem対応版）"""
	if not message_canvas:
		return
	
	# GlyphSystemの場合: GlyphManagerの表示位置を更新
	if command_executor and command_executor.glyph_manager_ref:
		# GlyphManagerに現在の位置を通知
		command_executor.glyph_manager_ref.update_visible_glyphs(position)
		ArgodeSystem.log_workflow("🎨 [GlyphSystem] Display updated to position %d" % position)
	
	# Legacy Fallback: 従来方式
	if message_canvas.has_method("queue_redraw"):
		if message_canvas.has_property("current_text"):
			message_canvas.current_text = display_text
		message_canvas.queue_redraw()
		ArgodeSystem.log_workflow("🎨 [Legacy] Display updated: '%s' (length: %d)" % [display_text, display_text.length()])

func _on_typing_finished():
	"""タイピング完了処理（GlyphSystem対応）"""
	is_typing = false
	is_paused = false
	
	# タイマーを確実に停止
	if typing_timer:
		typing_timer.stop()
	
	if parse_result:
		position = parse_result.total_length
		display_text = parse_result.plain_text
	
	# GlyphSystemの場合: 全グリフを表示
	if command_executor and command_executor.glyph_manager_ref:
		command_executor.glyph_manager_ref.show_all_glyphs()
		ArgodeSystem.log_workflow("✅ [GlyphSystem] All glyphs shown on completion")
	
	_update_display()
	
	ArgodeSystem.log_workflow("✅ [GlyphSystem] Typing completed: '%s'" % display_text)
	
	if typing_finished_callback.is_valid():
		typing_finished_callback.call()

## === クリーンアップ（重要：タイマー問題解決） ===

func cleanup():
	"""タイプライターのクリーンアップ（タイマー重複防止）"""
	is_typing = false
	is_paused = false
	
	# タイマーの完全削除
	if typing_timer and is_instance_valid(typing_timer):
		typing_timer.stop()
		if typing_timer.get_parent():
			typing_timer.get_parent().remove_child(typing_timer)
		typing_timer.queue_free()
		typing_timer = null
	
	# コマンドエグゼキューターもクリーンアップ
	if command_executor:
		command_executor.cleanup()
		command_executor = null
	
	ArgodeSystem.log_workflow("🧹 [Phase 3] ArgodeMessageTypewriter cleaned up completely")

## === GlyphSystem統合支援 ===

func get_glyph_manager():
	"""GlyphManagerを取得（TypewriterCommandExecutor経由）"""
	# 直接参照があればそれを使用
	if direct_glyph_manager:
		return direct_glyph_manager
	
	# CommandExecutorからの取得を試行
	if command_executor and command_executor.glyph_manager_ref:
		var glyph_manager = command_executor.glyph_manager_ref.get_ref()
		if glyph_manager:
			return glyph_manager
	
	# UIManagerからMessageRendererを経由して取得
	if ArgodeSystem.UIManager and ArgodeSystem.UIManager.has_method("get_message_renderer"):
		var renderer = ArgodeSystem.UIManager.get_message_renderer()
		if renderer and renderer.has_property("glyph_manager"):
			return renderer.glyph_manager
	
	ArgodeSystem.log_workflow("⚠️ Typewriter: GlyphManager not found via any path")
	return null

func set_glyph_manager(manager: ArgodeGlyphManager):
	"""GlyphManagerを直接設定（外部から呼び出し可能）"""
	direct_glyph_manager = manager
	if manager:
		ArgodeSystem.log_workflow("🎨 Typewriter: GlyphManager set directly")

func _notification(what):
	"""自動クリーンアップ"""
	if what == NOTIFICATION_PREDELETE:
		cleanup()
