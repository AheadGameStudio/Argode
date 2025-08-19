extends Control
class_name ArgodeMessageCanvas

# レンダラーからの描画コールバック
var draw_callback: Callable

# メッセージデータ（レンダラーが設定）
var current_text: String = ""

# アニメーション更新用
var animation_update_enabled: bool = false
var animation_update_callback: Callable

# フォント設定
@export var font_size: int = 16 : set = set_font_size
@export var use_bold_font: bool = false : set = set_use_bold_font
@export var use_serif_font: bool = false : set = set_use_serif_font

# キャッシュされたフォント
var cached_font: Font
var cached_font_dirty: bool = true

func _ready():
	# 最小サイズを設定
	custom_minimum_size = Vector2(100, 100)
	# フォントキャッシュを初期化
	_update_font_cache()

## アニメーション更新処理
func _process(delta: float):
	if animation_update_enabled and animation_update_callback.is_valid():
		animation_update_callback.call(delta)
		queue_redraw()  # アニメーション更新時に再描画

## プロパティのセッター関数
func set_font_size(value: int):
	font_size = value
	cached_font_dirty = true
	queue_redraw()

func set_use_bold_font(value: bool):
	use_bold_font = value
	cached_font_dirty = true
	queue_redraw()

func set_use_serif_font(value: bool):
	use_serif_font = value
	cached_font_dirty = true
	queue_redraw()

## Argodeプロジェクト設定からフォントを取得
func get_argode_font() -> Font:
	if cached_font_dirty:
		_update_font_cache()
	return cached_font

func _update_font_cache():
	cached_font = _load_font_from_settings()
	cached_font_dirty = false

func _load_font_from_settings() -> Font:
	var font_path: String = ""
	
	# Argodeプロジェクト設定からフォントパスを取得
	if use_serif_font:
		if use_bold_font:
			font_path = ProjectSettings.get_setting("argode/fonts/serif_font_bold", "")
		else:
			font_path = ProjectSettings.get_setting("argode/fonts/serif_font_normal", "")
	else:
		if use_bold_font:
			font_path = ProjectSettings.get_setting("argode/fonts/system_font_bold", "")
		else:
			font_path = ProjectSettings.get_setting("argode/fonts/system_font_normal", "")
	
	# フォントの読み込みを試行
	if font_path and not font_path.is_empty():
		var font = _try_load_font(font_path)
		if font:
			ArgodeSystem.log("✅ MessageCanvas: Loaded Argode font (%s, size:%d): %s" % ["serif" if use_serif_font else "system", font_size, font_path])
			return font
	
	# フォールバック1: GUIテーマのカスタムフォント
	var custom_theme = ProjectSettings.get_setting("gui/theme/custom", "")
	if custom_theme and not custom_theme.is_empty():
		var theme = _try_load_resource(custom_theme)
		if theme and theme is Theme:
			var theme_font = theme.get_default_font()
			if theme_font:
				ArgodeSystem.log("✅ MessageCanvas: Using GUI theme font (size:%d): %s" % [font_size, custom_theme])
				return theme_font
	
	# フォールバック2: GUIカスタムフォント設定
	var custom_font_path = ProjectSettings.get_setting("gui/theme/custom_font", "")
	if custom_font_path and not custom_font_path.is_empty():
		var font = _try_load_font(custom_font_path)
		if font:
			ArgodeSystem.log("✅ MessageCanvas: Using GUI custom font (size:%d): %s" % [font_size, custom_font_path])
			return font
	
	# フォールバック3: Godotデフォルトフォント
	ArgodeSystem.log("⚠️ MessageCanvas: Using Godot fallback font (size:%d) - no custom fonts configured" % font_size)
	return ThemeDB.fallback_font

func _try_load_font(path: String) -> Font:
	if path.is_empty():
		return null
	
	var resource = load(path)
	if resource and resource is Font:
		return resource
	else:
		ArgodeSystem.log("❌ Failed to load font: %s" % path, 2)
		return null

func _try_load_resource(path: String) -> Resource:
	if path.is_empty():
		return null
	
	var resource = load(path)
	if resource:
		return resource
	else:
		ArgodeSystem.log("❌ Failed to load resource: %s" % path, 2)
		return null

## 描画コールバックを設定（Rendererから呼ばれる）
func set_draw_callback(callback: Callable):
	draw_callback = callback

## メッセージテキストを設定
func set_message_text(text: String):
	current_text = text
	queue_redraw()  # 再描画をリクエスト

## 描画処理 - Rendererのコールバックを呼び出す
func _draw():
	if draw_callback.is_valid():
		# Rendererの描画メソッドを呼び出し、メッセージテキストのみを渡す
		draw_callback.call(self, "", current_text)

## Canvasの描画領域サイズを取得
func get_canvas_size() -> Vector2:
	return get_rect().size

## 描画用ヘルパーメソッド（Rendererから使用される）
func draw_text_at(text: String, position: Vector2, font: Font, font_size: int, color: Color):
	draw_string(font, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

## ランタイムでフォント設定を変更するメソッド
func configure_font(size: int = 16, bold: bool = false, serif: bool = false):
	font_size = size
	use_bold_font = bold
	use_serif_font = serif
	cached_font_dirty = true
	queue_redraw()
	ArgodeSystem.log("🎨 MessageCanvas font configured: size=%d, bold=%s, serif=%s" % [size, bold, serif])

## 現在のフォント設定をデバッグ出力
func debug_print_font_info():
	ArgodeSystem.log("🔍 MessageCanvas Font Debug Info:")
	ArgodeSystem.log("  - Font size: %d" % font_size)
	ArgodeSystem.log("  - Use bold: %s" % use_bold_font)
	ArgodeSystem.log("  - Use serif: %s" % use_serif_font)
	ArgodeSystem.log("  - Cache dirty: %s" % cached_font_dirty)
	if cached_font:
		ArgodeSystem.log("  - Current font: %s" % str(cached_font))
	else:
		ArgodeSystem.log("  - Current font: null")

## アニメーション更新を開始
func start_animation_updates(update_callback: Callable):
	animation_update_callback = update_callback
	animation_update_enabled = true
	ArgodeSystem.log("✨ Animation updates started on MessageCanvas")

## アニメーション更新を停止
func stop_animation_updates():
	animation_update_enabled = false
	animation_update_callback = Callable()
	ArgodeSystem.log("⏹️ Animation updates stopped on MessageCanvas")
