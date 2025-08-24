extends Control
class_name ArgodeMessageCanvas

# レンダラーからの描画コールバック
var draw_callback: Callable

# メッセージデータ（レンダラーが設定）
var current_text: String = ""

# GlyphSystem統合（Task 6-3: GlyphRenderer実装）
var glyph_manager: ArgodeGlyphManager = null
var glyph_renderer: ArgodeGlyphRenderer = null
var direct_draw_mode: bool = false  # 直接描画モード

# アニメーション更新用
var animation_update_enabled: bool = false
var animation_update_callback: Callable

# フォント設定
@export var font_size: int = 20 : set = set_font_size
@export var use_bold_font: bool = false : set = set_use_bold_font
@export var use_serif_font: bool = false : set = set_use_serif_font

# キャッシュされたフォント
var cached_font: Font
var cached_font_dirty: bool = true

func _ready():
	# 最小サイズを設定
	custom_minimum_size = Vector2(100, 100)
	
	# GlyphRendererを初期化
	glyph_renderer = ArgodeGlyphRenderer.new()
	ArgodeSystem.log_workflow("🎨 MessageCanvas: GlyphRenderer initialized")
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

## GlyphManagerを設定（Task 6-3: GlyphRenderer統合）
func set_glyph_manager(manager: ArgodeGlyphManager):
	"""GlyphManagerを設定してGlyphSystemを有効化"""
	glyph_manager = manager
	if glyph_manager:
		ArgodeSystem.log_workflow("🎨 MessageCanvas: GlyphManager set [ID: %s], GlyphSystem rendering enabled" % str(glyph_manager.get_instance_id()))
	else:
		ArgodeSystem.log_workflow("⚠️ MessageCanvas: GlyphManager set to null")
	queue_redraw()

## GlyphRendererの設定を変更
func configure_glyph_renderer(debug_mode: bool = false, max_glyphs: int = 100, batch_mode: bool = true):
	"""GlyphRendererのパフォーマンス・デバッグ設定"""
	if glyph_renderer:
		glyph_renderer.set_debug_mode(debug_mode)
		glyph_renderer.set_performance_settings(max_glyphs, batch_mode)
		ArgodeSystem.log_workflow("🎨 MessageCanvas: GlyphRenderer configured (debug: %s, max: %d, batch: %s)" % [debug_mode, max_glyphs, batch_mode])

## 描画処理 - GlyphSystem専用（デバッグ強化版）
func _draw():
	ArgodeSystem.log_workflow("🎨 [DRAW] Canvas _draw() called")
	
	# Phase 1: 基本状態確認
	ArgodeSystem.log_workflow("🔍 [DRAW] glyph_manager: %s" % str(glyph_manager != null))
	ArgodeSystem.log_workflow("🔍 [DRAW] glyph_renderer: %s" % str(glyph_renderer != null))
	
	# Phase 2: エフェクト更新（重要！）
	if glyph_manager:
		var delta = get_process_delta_time()
		glyph_manager.update_all_effects(delta)
		ArgodeSystem.log_workflow("🔄 [DRAW] Updated effects with delta: %.3f" % delta)
	
	# Phase 3: GlyphManager統合の中核描画（ログ削除でパフォーマンス向上）
	if glyph_manager and glyph_manager.text_glyphs.size() > 0:
		var visible_count = 0
		for glyph in glyph_manager.text_glyphs:
			if glyph.is_visible:
				visible_count += 1
		
		# 可視グリフがある場合のみ描画処理を実行
		if visible_count > 0:
			_draw_glyphs_directly()
			return
		else:
			# グリフはあるが可視グリフがない場合は何もしない
			pass
	
	# Phase 3: エラー状態表示（GlyphSystemが準備されていない場合）
	var error_font = get_argode_font()
	if error_font:
		draw_string(error_font, Vector2(10, 30), "ERROR: GlyphSystem not initialized", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.RED)
		draw_string(error_font, Vector2(10, 60), "glyph_manager: " + str(glyph_manager != null), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.YELLOW)
		if glyph_manager:
			draw_string(error_font, Vector2(10, 90), "glyphs count: " + str(glyph_manager.text_glyphs.size()), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.YELLOW)

## GlyphSystemの直接描画（_draw()内で呼び出し専用）
func _draw_glyphs_directly():
	"""_draw()メソッド内でグリフを直接描画"""
	if not glyph_manager:
		return
	
	var rendered_count = 0
	
	# 表示可能なグリフのみを描画
	for glyph in glyph_manager.text_glyphs:
		if glyph.is_visible:
			_draw_single_glyph_direct(glyph)
			rendered_count += 1
	
	ArgodeSystem.log_workflow("🎨 [Direct Draw] Rendered %d glyphs" % rendered_count)

func _draw_single_glyph_direct(glyph: ArgodeTextGlyph):
	"""単一グリフを直接描画（_draw()内専用）"""
	if not glyph:
		ArgodeSystem.log_workflow("❌ [Direct Draw] Glyph is null")
		return
	
	if not glyph.font:
		ArgodeSystem.log_workflow("❌ [Direct Draw] Font is null for glyph '%s'" % glyph.character)
		# フォントがnullの場合、MessageCanvasのフォントを使用
		glyph.font = get_argode_font()
		if glyph.font:
			ArgodeSystem.log_workflow("🔧 [Direct Draw] Applied MessageCanvas font to glyph '%s'" % glyph.character)
		else:
			ArgodeSystem.log_workflow("❌ [Direct Draw] MessageCanvas font is also null!")
			return
	
	# 改行文字はスキップ
	if glyph.character == "\n":
		return
	
	# 最終描画情報を取得
	var render_info = glyph.get_render_info()
	var final_position = render_info.get("position", Vector2.ZERO)
	var final_color = render_info.get("color", Color.WHITE)
	var final_scale = render_info.get("scale", 1.0)
	var font = render_info.get("font", glyph.font)
	var font_size = render_info.get("font_size", glyph.font_size)
	
	# スケール適用されたフォントサイズを計算
	var scaled_font_size = int(font_size * final_scale)
	
	# 詳細デバッグ情報
	ArgodeSystem.log_workflow("🔤 Drawing '%s' at %s, color: %s, scale: %.2f, size: %d" % [
		glyph.character, str(final_position), str(final_color), final_scale, scaled_font_size
	])
	
	# Canvas境界チェック
	var canvas_size = get_rect().size
	if final_position.x < 0 or final_position.y < 0 or final_position.x > canvas_size.x or final_position.y > canvas_size.y:
		ArgodeSystem.log_workflow("⚠️ [Direct Draw] Glyph '%s' position %s is outside canvas bounds %s" % [
			glyph.character, str(final_position), str(canvas_size)
		])
	
	# _draw()内なので直接draw_stringが使用可能
	draw_string(
		font,
		final_position,
		glyph.character,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		scaled_font_size,
		final_color
	)
	
	ArgodeSystem.log_workflow("✅ [Direct Draw] Successfully drew '%s'" % glyph.character)

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

## タイプライター効果を強制完了
func complete_typewriter():
	"""MessageCanvas内のタイプライター効果を強制完了"""
	# 親ノードでMessageRendererを探す
	var parent_node = get_parent()
	if parent_node and parent_node.has_method("complete_typewriter"):
		parent_node.complete_typewriter()
		ArgodeSystem.log("✅ [MessageCanvas] Typewriter completed via parent node")
		return
	
	# MessageCanvasの子ノードからMessageRendererを探す
	_find_and_complete_typewriter_in_children()

## 子ノードでMessageRendererを探してタイプライターを完了
func _find_and_complete_typewriter_in_children():
	"""子ノード階層を探索してMessageRendererのcomplete_typewriterを呼び出す"""
	for child in get_children():
		if child.has_method("complete_typewriter"):
			child.complete_typewriter()
			ArgodeSystem.log("✅ [MessageCanvas] Typewriter completed via child node: %s" % child.name)
			return
		
		# 再帰的に子ノードを探索
		if child.get_child_count() > 0:
			_find_typewriter_in_node(child)

## ノード内でMessageRendererを探す
func _find_typewriter_in_node(node: Node):
	"""指定ノード内でMessageRendererを探索"""
	for child in node.get_children():
		if child.has_method("complete_typewriter"):
			child.complete_typewriter()
			ArgodeSystem.log("✅ [MessageCanvas] Typewriter completed via nested node: %s" % child.name)
			return
		
		# 再帰的に探索
		if child.get_child_count() > 0:
			_find_typewriter_in_node(child)
