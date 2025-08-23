extends RefCounted
class_name ArgodeMessageTypewriter

## ArgodeMessageTypewriter v1.2.0 Phase 2
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
	"""タイピングを開始（Phase 2拡張版）"""
	if not text or text.length() == 0:
		ArgodeSystem.log_warning("[Phase 2] Empty text provided to typewriter")
		return
	
	# Phase 2: TypewriterTextParserでテキスト解析
	parse_result = TypewriterTextParser.parse_text(text)
	current_text = parse_result.plain_text
	display_text = ""
	position = 0
	typing_speed = speed
	is_typing = true
	is_paused = false
	
	# Canvas設定（オプション）
	if canvas_node:
		message_canvas = canvas_node
		# 描画コールバックを設定
		if canvas_node.has_method("set_draw_callback"):
			canvas_node.set_draw_callback(_draw_message_content)
	
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
	
	# タイマー開始
	if typing_timer:
		typing_timer.start()

func _on_typing_timer_timeout():
	"""タイマータイムアウト時の処理（Phase 3拡張）"""
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
	"""表示を更新（Phase 2）"""
	if message_canvas and message_canvas.has_method("queue_redraw"):
		message_canvas.current_text = display_text
		message_canvas.queue_redraw()
		ArgodeSystem.log_workflow("[Phase 2] Display updated: '%s' (length: %d)" % [display_text, display_text.length()])

func _on_typing_finished():
	"""タイピング完了処理"""
	is_typing = false
	if parse_result:
		position = parse_result.total_length
		display_text = parse_result.plain_text
	
	_update_display()
	
	ArgodeSystem.log_workflow("✅ [Phase 2] Typing completed: '%s'" % display_text)
	
	if typing_finished_callback.is_valid():
		typing_finished_callback.call()
