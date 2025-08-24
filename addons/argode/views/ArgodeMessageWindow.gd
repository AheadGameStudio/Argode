extends ArgodeViewBase
class_name ArgodeMessageWindow

@export_node_path var message_container
@export_node_path var message_label
@export_node_path var continue_prompt
@export_node_path var name_plate
var name_label: Label

# フォント設定
@export var character_name_font_size: int = 18 : set = set_character_name_font_size
@export var use_bold_font_for_names: bool = true : set = set_use_bold_font_for_names

# アクティブ状態監視
var _last_active_state: bool = true
signal active_state_changed(new_state: bool)

func _ready():
	# NodePathから実際のノードへの参照を取得
	if message_container:
		message_container = get_node(message_container)
	if message_label:
		message_label = get_node(message_label)
	if continue_prompt:
		continue_prompt = get_node(continue_prompt)
		# 初期状態でContinuePromptを非表示に設定
		continue_prompt.visible = false
	if name_plate:
		name_plate = get_node(name_plate)
		# 名前ラベルを取得
		if name_plate and name_plate.get_child_count() > 0:
			name_label = name_plate.get_child(0)
		# 初期状態でNamePlateを非表示に設定
		name_plate.visible = false

	# MessageCanvasの場合はdraw_callbackを設定
	if message_label is ArgodeMessageCanvas:
		message_label.draw_callback = _draw_message_callback
		ArgodeSystem.log("✅ MessageCanvas draw_callback set", ArgodeSystem.LOG_LEVEL.DEBUG)

	# フォント設定を適用
	_apply_font_settings()

func _post_ready():
	super._post_ready()
	# 最前面に固定(Z-Index +1000)
	is_sticky_front = true
	
	# アクティブ状態の初期化
	_last_active_state = is_active
	
	# アクティブ状態監視の開始
	_start_active_state_monitoring()

## アクティブ状態の監視を開始
func _start_active_state_monitoring():
	# 定期的にis_activeの変化をチェック
	var monitor_timer = Timer.new()
	monitor_timer.wait_time = 0.1  # 100ms間隔でチェック
	monitor_timer.timeout.connect(_check_active_state)
	monitor_timer.autostart = true
	add_child(monitor_timer)

## アクティブ状態の変化をチェック
func _check_active_state():
	if is_active != _last_active_state:
		_last_active_state = is_active
		active_state_changed.emit(is_active)
		
		if is_active:
			ArgodeSystem.log("✅ MessageWindow became active - resuming operations")
		else:
			ArgodeSystem.log("⏸️ MessageWindow became inactive - pausing operations")

## プロパティのセッター関数
func set_character_name_font_size(value: int):
	character_name_font_size = value
	_apply_font_settings()

func set_use_bold_font_for_names(value: bool):
	use_bold_font_for_names = value
	_apply_font_settings()

## フォント設定をキャラクター名ラベルに適用
func _apply_font_settings():
	if not is_instance_valid(name_label):
		return
	
	# Argodeプロジェクト設定からフォントを取得
	var font = _get_argode_font_for_names()
	
	# LabelNodeのtheme設定を更新
	if not name_label.theme:
		name_label.theme = Theme.new()
	
	name_label.theme.set_font("font", "Label", font)
	name_label.theme.set_font_size("font_size", "Label", character_name_font_size)

## キャラクター名用のフォントを取得
func _get_argode_font_for_names() -> Font:
	var font_path: String = ""
	
	# プロジェクト設定からフォントパスを取得
	if use_bold_font_for_names:
		font_path = ProjectSettings.get_setting("argode/fonts/system_font_bold", "")
	else:
		font_path = ProjectSettings.get_setting("argode/fonts/system_font_normal", "")
	
	# フォントの読み込みを試行
	if font_path and not font_path.is_empty():
		var font = _try_load_font(font_path)
		if font:
			return font
	
	# フォールバック1: GUIテーマのカスタムフォント
	var custom_theme = ProjectSettings.get_setting("gui/theme/custom", "")
	if custom_theme and not custom_theme.is_empty():
		var theme = _try_load_resource(custom_theme)
		if theme and theme is Theme:
			var theme_font = theme.get_default_font()
			if theme_font:
				return theme_font
	
	# フォールバック2: GUIカスタムフォント設定
	var custom_font_path = ProjectSettings.get_setting("gui/theme/custom_font", "")
	if custom_font_path and not custom_font_path.is_empty():
		var font = _try_load_font(custom_font_path)
		if font:
			return font
	
	# フォールバック3: Godotデフォルトフォント
	return ThemeDB.fallback_font

func _try_load_font(path: String) -> Font:
	if path.is_empty():
		return null
	
	var resource = load(path)
	if resource and resource is Font:
		return resource
	else:
		ArgodeSystem.log("❌ Failed to load font for character names: %s" % path, 2)
		return null

func _try_load_resource(path: String) -> Resource:
	if path.is_empty():
		return null
	
	var resource = load(path)
	if resource:
		return resource
	else:
		ArgodeSystem.log("❌ Failed to load resource for character names: %s" % path, 2)
		return null

# TypewriterServiceから受け取ったメッセージを純粋に表示するだけの関数
func set_message_text(text: String):
	if not is_instance_valid(message_label):
		ArgodeSystem.log("❌ Error: Message label node is not valid or does not exist.", ArgodeSystem.LOG_LEVEL.CRITICAL)
		return
	
	# ArgodeMessageCanvasの場合（専用メソッド使用）
	if message_label is ArgodeMessageCanvas:
		if message_label.has_method("set_message_text"):
			message_label.set_message_text(text)
			ArgodeSystem.log("✅ Message text set via ArgodeMessageCanvas.set_message_text", ArgodeSystem.LOG_LEVEL.DEBUG)
		else:
			message_label.current_text = text
			message_label.queue_redraw()  # 再描画を要求
			ArgodeSystem.log("✅ Message text set via ArgodeMessageCanvas.current_text", ArgodeSystem.LOG_LEVEL.DEBUG)
	# 通常のLabelの場合
	elif message_label.has_method("set_text"):
		message_label.set_text(text)
		ArgodeSystem.log("✅ Message text set via set_text method", ArgodeSystem.LOG_LEVEL.DEBUG)
	elif "text" in message_label:
		message_label.text = text
		ArgodeSystem.log("✅ Message text set via text property", ArgodeSystem.LOG_LEVEL.DEBUG)
	else:
		ArgodeSystem.log("❌ Error: Message label does not support text setting. Type: %s" % message_label.get_class(), ArgodeSystem.LOG_LEVEL.CRITICAL)

# 名前のテキストを設定
func set_name_text(name: String):
	ArgodeSystem.log_workflow("🎬 [Phase 3.5] Setting name text: '%s'" % name)
	if is_instance_valid(name_label):
		name_label.text = name
		ArgodeSystem.log_workflow("🎬 [Phase 3.5] Name text set to existing label: '%s'" % name)
	else:
		# 名前ラベルがnullの場合は新規に取得
		ArgodeSystem.log_workflow("🎬 [Phase 3.5] Name label not found, searching...")
		name_label = name_plate.get_child(0) if name_plate.get_child_count() > 0 else null
		if not is_instance_valid(name_label):
			ArgodeSystem.log("❌ Error: Name label node is not valid or does not exist.", ArgodeSystem.DebugManager.LogLevel.ERROR)
			return
	if name_label:
		name_label.text = name
		ArgodeSystem.log_workflow("🎬 [Phase 3.5] Name text finally set: '%s'" % name)

# キャラクター名を設定（名前プレートも表示）
func set_character_name(character_name: String):
	set_name_text(character_name)
	show_name_plate()

# キャラクター名を隠す（名前プレートも非表示）
func hide_character_name():
	hide_name_plate()

# 続行プロンプトを表示
func show_continue_prompt():
	if continue_prompt:
		continue_prompt.visible = true
		ArgodeSystem.log_workflow("🎬 [Phase 3.5] Continue prompt SHOWN")

# 続行プロンプトを非表示にする
func hide_continue_prompt():
	if continue_prompt:
		continue_prompt.visible = false
		ArgodeSystem.log_workflow("🎬 [Phase 3.5] Continue prompt HIDDEN")

# 名前プレートを表示
func show_name_plate():
	if name_plate:
		name_plate.visible = true
		ArgodeSystem.log_workflow("🎬 [Phase 3.5] Name plate SHOWN")
	else:
		ArgodeSystem.log_workflow("🎬 [Phase 3.5] Name plate not found!")

# 名前プレートを非表示にする
func hide_name_plate():
	if name_plate:
		name_plate.visible = false
		ArgodeSystem.log_workflow("🎬 [Phase 3.5] Name plate HIDDEN")
	else:
		ArgodeSystem.log_workflow("🎬 [Phase 3.5] Name plate not found!")

## MessageCanvas用の描画コールバック関数
func _draw_message_callback(canvas: ArgodeMessageCanvas, character_name: String):
	if not is_instance_valid(canvas):
		return
	
	# キャラクター名が指定されている場合は名前プレートに表示
	if not character_name.is_empty():
		set_character_name(character_name)
		show_name_plate()
	else:
		hide_name_plate()
	
	# メッセージテキストの描画は ArgodeMessageCanvas で行われる
	ArgodeSystem.log("✅ Message callback executed for character: '%s'" % character_name, ArgodeSystem.LOG_LEVEL.DEBUG)

## タイプライター効果を強制完了
func complete_typewriter():
	"""メッセージウィンドウ内のタイプライター効果を強制完了"""
	# MessageCanvasがある場合、その内部のMessageRendererを探す
	if message_label and message_label.has_method("complete_typewriter"):
		message_label.complete_typewriter()
		ArgodeSystem.log("✅ [MessageWindow] Typewriter completed via message label")
		return
	
	# 子ノードを探索してMessageRendererを見つける
	_find_and_complete_typewriter(self)

## MessageRendererを探してタイプライターを完了
func _find_and_complete_typewriter(node: Node):
	"""ノード階層を探索してMessageRendererのcomplete_typewriterを呼び出す"""
	for child in node.get_children():
		if child.has_method("complete_typewriter"):
			child.complete_typewriter()
			ArgodeSystem.log("✅ [MessageWindow] Typewriter completed via child node: %s" % child.name)
			return
		
		# 再帰的に子ノードを探索
		_find_and_complete_typewriter(child)