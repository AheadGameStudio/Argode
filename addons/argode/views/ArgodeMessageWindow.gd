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

func _ready():
	# NodePathから実際のノードへの参照を取得
	if message_container:
		message_container = get_node(message_container)
	if message_label:
		message_label = get_node(message_label)
	if continue_prompt:
		continue_prompt = get_node(continue_prompt)
	if name_plate:
		name_plate = get_node(name_plate)
		# 名前ラベルを取得
		if name_plate and name_plate.get_child_count() > 0:
			name_label = name_plate.get_child(0)
	
	# フォント設定を適用
	_apply_font_settings()

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
	message_label.text = text

# 名前のテキストを設定
func set_name_text(name: String):
	if is_instance_valid(name_label):
		name_label.text = name
	else:
		# 名前ラベルがnullの場合は新規に取得
		name_label = name_plate.get_child(0) if name_plate.get_child_count() > 0 else null
		if not is_instance_valid(name_label):
			ArgodeSystem.log("❌ Error: Name label node is not valid or does not exist.", ArgodeSystem.DebugManager.LogLevel.ERROR)
			return
	if name_label:
		name_label.text = name

# キャラクター名を設定（名前プレートも表示）
func set_character_name(character_name: String):
	set_name_text(character_name)
	show_name_plate()

# キャラクター名を隠す（名前プレートも非表示）
func hide_character_name():
	hide_name_plate()

# 続行プロンプトを表示
func show_continue_prompt():
	continue_prompt.visible = true

# 続行プロンプトを非表示にする
func hide_continue_prompt():
	continue_prompt.visible = false

# 名前プレートを表示
func show_name_plate():
	name_plate.visible = true

# 名前プレートを非表示にする
func hide_name_plate():
	name_plate.visible = false