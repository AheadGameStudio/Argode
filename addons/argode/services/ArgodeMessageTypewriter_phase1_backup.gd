extends RefCounted
class_name ArgodeMessageTypewriter

## Phase 1 プロトタイプ: 最小限のタイプライター機能
## - 単純な文字送り
## - 一時停止・再開・スキップ
## - コマンド・エフェクトなし

# === 状態管理（Phase 2拡張） ===
var current_text: String = ""
var display_text: String = ""
var position: int = 0
var is_typing: bool = false
var is_paused: bool = false
var typing_speed: float = 0.05

# Phase 2追加: 解析とタイマー
var parse_result = null
var typing_timer: Timer = null

# === UI連携 ===
var message_canvas: Control = null  # Phase 2でTypewriterUIBridgeに置き換え

# === コールバック ===
var character_typed_callback: Callable
var typing_finished_callback: Callable

func _init():
	ArgodeSystem.log_workflow("🎬 [Phase 2] ArgodeMessageTypewriter with TextParser initializing")
	_setup_typing_timer()

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
	
	# タイマー設定
	if typing_timer:
		typing_timer.wait_time = typing_speed
	
	ArgodeSystem.log_workflow("🎬 [Phase 2] Starting enhanced typing: '%s' (parsed length: %d)" % [text.substr(0, 20) + ("..." if text.length() > 20 else ""), parse_result.total_length])
	_start_next_character()

func _start_next_character():
	"""次の文字のタイピングを開始"""
	if not is_typing or is_paused:
		return
	
	if position >= parse_result.total_length:
		_on_typing_finished()
		return
	
	# タイマー開始
	if typing_timer:
		typing_timer.start()

func _on_typing_timer_timeout():
	"""タイマータイムアウト時の処理（Phase 2）"""
	if not is_typing or is_paused:
		return
	
	if position >= parse_result.total_length:
		_on_typing_finished()
		return
	
	# 1文字追加
	position += 1
	display_text = TypewriterTextParser.get_substring_at_position(parse_result, position)
	
	# UI更新
	_update_display()
	
	# コールバック呼び出し
	if character_typed_callback.is_valid():
		character_typed_callback.call(display_text)
	
	# 次の文字へ
	_start_next_character()

func _update_display():
	"""表示を更新（Phase 2）"""
	if message_canvas and message_canvas.has_method("queue_redraw"):
		message_canvas.current_text = display_text
		message_canvas.queue_redraw()

func _on_typing_finished():
	"""タイピング完了処理"""
	is_typing = false
	position = parse_result.total_length
	display_text = parse_result.plain_text
	
	_update_display()
	
	ArgodeSystem.log_workflow("✅ [Phase 2] Typing completed: '%s'" % display_text)
	
	if typing_finished_callback.is_valid():
		typing_finished_callback.call()

func pause_typing():
	"""タイピングを一時停止"""
	is_paused = true
	ArgodeSystem.log_workflow("⏸️ [Phase 1] Typing paused")

func resume_typing():
	"""タイピングを再開"""
	if is_paused and is_typing:
		is_paused = false
		ArgodeSystem.log_workflow("▶️ [Phase 1] Typing resumed")
		_process_simple_typing()

func skip_typing():
	"""タイピングをスキップして完了"""
	if is_typing:
		display_text = current_text
		position = current_text.length()
		is_typing = false
		is_paused = false
		ArgodeSystem.log_workflow("⏭️ [Phase 1] Typing skipped to completion")
		_update_display()
		_on_typing_finished()

func stop_typing():
	"""タイピングを停止"""
	is_typing = false
	is_paused = false
	ArgodeSystem.log_workflow("⏹️ [Phase 1] Typing stopped")

func is_currently_typing() -> bool:
	"""タイピング中かどうか"""
	return is_typing and not is_paused

## === UI連携 ===

func set_message_canvas(canvas: Control):
	"""メッセージキャンバスを設定"""
	message_canvas = canvas
	ArgodeSystem.log_workflow("🎨 [Phase 1] Message canvas set: %s" % canvas)

func set_callbacks(char_callback: Callable, finish_callback: Callable):
	"""コールバックを設定"""
	character_typed_callback = char_callback
	typing_finished_callback = finish_callback

## 描画コールバック対応 ==================================

func _draw_message_content(canvas, character_name: String = ""):
	"""Canvas描画コールバック（Phase 1互換実装）"""
	# Phase 1: 基本的なテキスト描画のみ
	if not canvas or not canvas.has_method("queue_redraw"):
		return
	
	# 現在の表示文字列を取得
	var display_text = ""
	if current_text and position >= 0:
		var end_pos = min(position, current_text.length())
		display_text = current_text.substr(0, end_pos)
	
	# Canvasに描画をトリガー
	canvas.current_text = display_text
	canvas.queue_redraw()

## === 内部処理（プロトタイプ版） ===

func _process_simple_typing():
	"""単純な文字送り処理"""
	if not is_typing or is_paused:
		return
	
	if position >= current_text.length():
		# タイピング完了
		is_typing = false
		ArgodeSystem.log_workflow("✅ [Phase 1] Typing completed")
		_on_typing_finished()
		return
	
	# 1文字追加
	var char = current_text[position]
	display_text += char
	position += 1
	
	# UI更新
	_update_display()
	
	# 文字入力コールバック
	if character_typed_callback.is_valid():
		character_typed_callback.call(char, display_text)
	
	# 次の文字の待機時間
	await Engine.get_main_loop().create_timer(typing_speed).timeout
	
	# 再帰的に次の文字へ
	_process_simple_typing()

func _update_display():
	"""表示更新"""
	if message_canvas and message_canvas.has_method("set_message_text"):
		message_canvas.set_message_text(display_text)

func _on_typing_finished():
	"""タイピング完了処理"""
	if typing_finished_callback.is_valid():
		typing_finished_callback.call()
	ArgodeSystem.log_workflow("🎬 [Phase 1] Typing finished callback executed")
