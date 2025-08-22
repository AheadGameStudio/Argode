# ArgodeUIControlService.gd
extends RefCounted

class_name ArgodeUIControlService

## タイプライター・UI制御サービス（ArgodeUIManagerと連携）
## 責任: タイプライター制御、UI一時停止管理、UIとの協調制御、メッセージシステム管理

# UI一時停止制御
var is_ui_paused: bool = false
var ui_pause_reason: String = ""

# タイプライター制御状態
var typewriter_speed_stack: Array[float] = []
var typewriter_pause_count: int = 0

# ArgodeUIManagerの参照
var ui_manager: ArgodeUIManager = null

# メッセージシステム管理（新規追加）
var message_window: ArgodeMessageWindow = null
var message_renderer: ArgodeMessageRenderer = null
var inline_command_manager: ArgodeInlineCommandManager = null

# 実行制御参照（入力待ちコールバック用）
var execution_service: ArgodeExecutionService = null

# シグナル: タイプライター完了時
signal typewriter_completed()
# シグナル: メッセージレンダリング完了時
signal message_rendering_completed()

func _init():
	_setup_ui_manager_connection()

## メッセージシステム初期化 ============================

func ensure_message_system_ready() -> void:
	"""メッセージシステムの初期化を確認する"""
	# UIManagerの準備状態を確認
	if not _ensure_ui_manager_ready():
		ArgodeSystem.log_critical("🚨 UIControlService: UIManager not available, cannot setup message system")
		return
	
	if not message_window:
		_create_default_message_window()
	if not message_renderer:
		_create_message_renderer()
	if not inline_command_manager:
		_create_inline_command_manager()

func _create_default_message_window() -> void:
	"""デフォルトのメッセージウィンドウを作成"""
	ArgodeSystem.log_debug_detail("🎮 UIControlService: デフォルトメッセージウィンドウ作成")
	
	# UIManagerの準備状態を再確認
	if not _ensure_ui_manager_ready():
		ArgodeSystem.log_critical("❌ UIControlService: UIManager not available for window creation")
		return
	
	# 既存のメッセージウィンドウがあるかUI Managerで確認
	message_window = ui_manager.get_ui("message")
	if message_window:
		ArgodeSystem.log_debug_detail("🎮 UIControlService: 既存のメッセージウィンドウを発見")
		return
	
	# メッセージウィンドウが存在しない場合は新規作成
	ArgodeSystem.log_debug_detail("🎮 UIControlService: 新しいメッセージウィンドウを作成します")
	var message_window_path = "res://addons/argode/builtin/scenes/default_message_window/default_message_window.tscn"
	
	# メッセージウィンドウをUIManagerに追加
	var add_result = ui_manager.add_ui(message_window_path, "message", 100)
	if add_result:
		message_window = ui_manager.get_ui("message")
		if message_window:
			ArgodeSystem.log_workflow("✅ UIControlService: Default message window created and added")
		else:
			ArgodeSystem.log_critical("❌ UIControlService: Window created but retrieval failed")
	else:
		ArgodeSystem.log_critical("❌ UIControlService: Failed to create default message window - add_ui returned false")
func _create_message_renderer() -> void:
	"""メッセージレンダラーを作成"""
	ArgodeSystem.log_debug_detail("🎮 UIControlService: メッセージレンダラー作成")
	message_renderer = create_message_renderer()
	# メッセージウィンドウの設定は create_message_renderer() 内で実行

func _create_inline_command_manager() -> void:
	"""インラインコマンドマネージャーを作成"""
	ArgodeSystem.log_debug_detail("🎮 UIControlService: インラインコマンドマネージャー作成")
	inline_command_manager = ArgodeInlineCommandManager.new()

## メッセージ表示機能（StatementManagerから移譲）================

func show_message(text: String, character: String = "") -> void:
	"""メッセージを表示する（StatementManagerから移譲された機能）"""
	ensure_message_system_ready()
	
	ArgodeSystem.log_debug_detail("🎮 UIControlService: show_message - renderer=%s, window=%s, inline_manager=%s" % [message_renderer, message_window, inline_command_manager])
	
	if message_renderer and inline_command_manager:
		# InlineCommandManagerでテキストを前処理（変数展開・タグ処理）
		ArgodeSystem.log_debug_detail("🔍 UIControlService: Processing text with inline commands: '%s'" % text)
		var processed_result = inline_command_manager.process_text(text)
		var display_text = processed_result.get("display_text", text)
		var position_commands = processed_result.get("position_commands", [])
		
		ArgodeSystem.log_debug_detail("🔍 UIControlService: Processed result - display_text='%s', commands=%d" % [display_text, position_commands.size()])
		
		# 位置ベースコマンド付きメッセージレンダリング
		message_renderer.render_message_with_position_commands(character, display_text, position_commands, inline_command_manager)
		ArgodeSystem.log_workflow("📺 Message displayed via UIControlService: %s: %s" % [character, display_text])
		
		# レンダリング完了シグナルを送信
		message_rendering_completed.emit()
		
	else:
		var missing_components = []
		if not message_renderer: missing_components.append("message_renderer")
		if not inline_command_manager: missing_components.append("inline_command_manager")
		ArgodeSystem.log_critical("🚨 UIControlService: メッセージシステムの準備ができていません - missing: %s" % str(missing_components))

func create_message_renderer() -> ArgodeMessageRenderer:
	"""メッセージレンダラーを作成"""
	if not message_window:
		ArgodeSystem.log_critical("🚨 UIControlService: メッセージウィンドウが必要です")
		return null
	
	ArgodeSystem.log_debug_detail("🎮 UIControlService: メッセージレンダラー作成開始")
	
	# ArgodeMessageRendererクラスを動的に読み込み
	var renderer_path = "res://addons/argode/renderer/ArgodeMessageRenderer.gd"
	if not ResourceLoader.exists(renderer_path):
		ArgodeSystem.log_critical("❌ UIControlService: ArgodeMessageRenderer not found at: %s" % renderer_path)
		return null
	
	var RendererClass = load(renderer_path)
	if not RendererClass:
		ArgodeSystem.log_critical("❌ UIControlService: Failed to load ArgodeMessageRenderer class")
		return null

	var renderer = RendererClass.new()
	if not renderer:
		ArgodeSystem.log_critical("❌ UIControlService: Failed to instantiate ArgodeMessageRenderer")
		return null
	
	# メッセージウィンドウを設定
	if renderer.has_method("set_message_window"):
		renderer.set_message_window(message_window)
		ArgodeSystem.log_debug_detail("🎮 UIControlService: メッセージレンダラー作成完了")
	else:
		ArgodeSystem.log_critical("🚨 UIControlService: Renderer missing set_message_window method")
		return null
		
	return renderer

## タイプライター制御 ==================================
func _setup_ui_manager_connection():
	"""UIManagerへの接続を確立（遅延初期化対応）"""
	ui_manager = ArgodeSystem.UIManager
	
	if ui_manager:
		# 🎬 WORKFLOW: UI制御システム初期化（GitHub Copilot重要情報）
		ArgodeSystem.log_workflow("UIControlService connected to ArgodeUIManager")
	else:
		# UIManagerがまだ初期化されていない場合は、遅延初期化を試行
		ArgodeSystem.log_debug_detail("� UIManager not ready, will retry during message system setup")

func _ensure_ui_manager_ready() -> bool:
	"""UIManagerの準備状態を確認し、必要に応じて再接続"""
	if not ui_manager:
		ui_manager = ArgodeSystem.UIManager
		
		if ui_manager:
			ArgodeSystem.log_workflow("✅ UIControlService: UIManager connection established (delayed)")
		else:
			ArgodeSystem.log_critical("❌ UIControlService: UIManager still not available")
			return false
	
	return true

## UI操作を一時停止
func pause_ui_operations(reason: String):
	is_ui_paused = true
	ui_pause_reason = reason
	
	# 🎬 WORKFLOW: UI一時停止（GitHub Copilot重要情報）
	ArgodeSystem.log_workflow("UI operations paused: %s" % reason)

## UI操作を再開
func resume_ui_operations(reason: String = ""):
	if is_ui_paused:
		is_ui_paused = false
		var previous_reason = ui_pause_reason
		ui_pause_reason = ""
		
		# 🎬 WORKFLOW: UI再開（GitHub Copilot重要情報）
		ArgodeSystem.log_workflow("UI operations resumed (was: %s)" % previous_reason)

## UI一時停止状態をチェック
func is_ui_operations_paused() -> bool:
	return is_ui_paused

## タイプライター速度をスタックにプッシュ
func push_typewriter_speed(new_speed: float):
	typewriter_speed_stack.push_back(new_speed)
	
	# UIManagerのタイプライター制御と連携
	if ui_manager and ui_manager.has_method("set_typewriter_speed"):
		ui_manager.set_typewriter_speed(new_speed)
	
	# 🔍 DEBUG: タイプライター制御詳細（通常は非表示）
	ArgodeSystem.log_debug_detail("Typewriter speed pushed: %f (stack depth: %d)" % [new_speed, typewriter_speed_stack.size()])

## タイプライター速度をスタックからポップ
func pop_typewriter_speed():
	if typewriter_speed_stack.is_empty():
		# 🚨 CRITICAL: 重要なエラー（GitHub Copilot重要情報）
		ArgodeSystem.log_critical("Cannot pop typewriter speed: stack is empty")
		return
	
	typewriter_speed_stack.pop_back()
	
	# スタックの最上位またはデフォルト速度を適用
	var current_speed = get_current_typewriter_speed()
	if ui_manager and ui_manager.has_method("set_typewriter_speed"):
		ui_manager.set_typewriter_speed(current_speed)
	
	# 🔍 DEBUG: タイプライター制御詳細（通常は非表示）
	ArgodeSystem.log_debug_detail("Typewriter speed popped: %f (stack depth: %d)" % [current_speed, typewriter_speed_stack.size()])

## 現在のタイプライター速度を取得
func get_current_typewriter_speed() -> float:
	if typewriter_speed_stack.is_empty():
		return 1.0  # デフォルト速度
	return typewriter_speed_stack[-1]

## タイプライターを一時停止
func pause_typewriter():
	typewriter_pause_count += 1
	
	if ui_manager and ui_manager.has_method("pause_typewriter"):
		ui_manager.pause_typewriter()
	
	# 🔍 DEBUG: タイプライター制御詳細（通常は非表示）
	ArgodeSystem.log_debug_detail("Typewriter paused (count: %d)" % typewriter_pause_count)

## タイプライターを再開
func resume_typewriter():
	if typewriter_pause_count > 0:
		typewriter_pause_count -= 1
		
		if typewriter_pause_count == 0:
			if ui_manager and ui_manager.has_method("resume_typewriter"):
				ui_manager.resume_typewriter()
		
		# 🔍 DEBUG: タイプライター制御詳細（通常は非表示）
		ArgodeSystem.log_debug_detail("Typewriter resumed (count: %d)" % typewriter_pause_count)

## タイプライターが一時停止中かチェック
func is_typewriter_paused() -> bool:
	return typewriter_pause_count > 0

## タイプライターが動作中かチェック
func is_typewriter_active() -> bool:
	if ui_manager and ui_manager.has_method("is_typewriter_active"):
		return ui_manager.is_typewriter_active()
	return false

## タイプライターを強制完了
func complete_typewriter():
	if ui_manager and ui_manager.has_method("complete_typewriter"):
		ui_manager.complete_typewriter()
		# 🔍 DEBUG: タイプライター制御詳細（通常は非表示）
		ArgodeSystem.log_debug_detail("Typewriter force completed")

## UI状態をリセット
func reset_ui_state():
	is_ui_paused = false
	ui_pause_reason = ""
	typewriter_speed_stack.clear()
	typewriter_pause_count = 0
	
	# 🎬 WORKFLOW: UI状態リセット（GitHub Copilot重要情報）
	ArgodeSystem.log_workflow("UIControlService state reset")

## デバッグ用：UI制御状態を出力
func debug_print_ui_state():
	# 🔍 DEBUG: UI制御状態詳細（通常は非表示）
	ArgodeSystem.log_debug_detail("UIControlService State:")
	ArgodeSystem.log_debug_detail("  ui_paused: %s, reason: %s" % [str(is_ui_paused), ui_pause_reason])
	ArgodeSystem.log_debug_detail("  typewriter_pause_count: %d" % typewriter_pause_count)
	ArgodeSystem.log_debug_detail("  typewriter_speed_stack: %s" % str(typewriter_speed_stack))
	ArgodeSystem.log_debug_detail("  ui_manager: %s" % ("connected" if ui_manager != null else "not connected"))

## メッセージウィンドウを通してメッセージを表示（StatementManagerから移譲）
func display_message_via_window(text: String, character: String, message_window, execution_service: RefCounted = null):
	"""
	メッセージウィンドウを通してメッセージを表示
	
	Args:
		text: 表示するメッセージテキスト
		character: キャラクター名（オプション）
		message_window: メッセージウィンドウインスタンス
		execution_service: ExecutionServiceインスタンス（入力待ち設定用）
	"""
	if not message_window:
		ArgodeSystem.log_workflow("❌ Message window is not available")
		return
	
	# メッセージウィンドウを表示
	if ui_manager:
		ui_manager.show_ui("message")
	else:
		ArgodeSystem.UIManager.show_ui("message")
	
	# メッセージウィンドウにメッセージを設定
	if message_window.has_method("set_message_text"):
		message_window.set_message_text(text)
		ArgodeSystem.log_debug_detail("✅ Message text set via set_message_text")
	else:
		ArgodeSystem.log_workflow("❌ Message window does not have set_message_text method")
	
	# キャラクター名を設定（空でない場合）
	if character != "":
		if message_window.has_method("set_character_name"):
			message_window.set_character_name(character)
			ArgodeSystem.log_debug_detail("✅ Character name set via set_character_name: %s" % character)
		else:
			ArgodeSystem.log_workflow("❌ Message window does not have set_character_name method")
	else:
		# キャラクター名が無い場合は名前プレートを隠す
		if message_window.has_method("hide_character_name"):
			message_window.hide_character_name()
			ArgodeSystem.log_debug_detail("✅ Character name hidden")
	
	ArgodeSystem.log_workflow("📺 Message displayed via window: %s: %s" % [character, text])
	
	# ウィンドウパス使用時も入力待ち状態を設定
	if execution_service and execution_service.has_method("set_waiting_for_input"):
		execution_service.set_waiting_for_input(true)
		ArgodeSystem.log_debug_detail("⏳ Set waiting for user input to continue (via window)")
	else:
		ArgodeSystem.log_workflow("❌ ExecutionService not available for input waiting")
