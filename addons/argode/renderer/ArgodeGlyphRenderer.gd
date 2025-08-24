extends RefCounted
class_name ArgodeGlyphRenderer

## 複数ArgodeTextGlyphの統合描画レンダラー
## Task 6-3: 残り10%の統合描画機能実装

# 描画設定
var debug_mode: bool = false
var draw_character_bounds: bool = false
var draw_effect_info: bool = false

# パフォーマンス設定
var max_glyphs_per_frame: int = 100  # フレーム当たりの最大描画グリフ数
var batch_rendering: bool = true     # バッチ描画モード

# 統計情報
var last_render_time: float = 0.0
var glyphs_rendered_count: int = 0

func _init():
	pass

## === メイン描画API ===

func render_all_glyphs(canvas: Control, glyph_manager: ArgodeGlyphManager) -> void:
	"""GlyphManagerの全グリフを描画"""
	if not canvas or not glyph_manager:
		ArgodeSystem.log_workflow("⚠️ GlyphRenderer: Invalid canvas or glyph_manager")
		return
	
	var start_time = Time.get_ticks_msec()
	var rendered_count = 0
	
	# 表示可能なグリフのみを描画
	for glyph in glyph_manager.text_glyphs:
		if glyph.is_visible:
			_render_single_glyph(canvas, glyph)
			rendered_count += 1
			
			# パフォーマンス制限
			if rendered_count >= max_glyphs_per_frame:
				ArgodeSystem.log_workflow("🎯 GlyphRenderer: Frame limit reached (%d glyphs)" % max_glyphs_per_frame)
				break
	
	# 統計更新
	var end_time = Time.get_ticks_msec()
	_update_render_stats(start_time, end_time, rendered_count)
	
	if debug_mode:
		ArgodeSystem.log_workflow("🎨 GlyphRenderer: Rendered %d glyphs" % rendered_count)

func render_glyph_range(canvas: Control, glyph_manager: ArgodeGlyphManager, start_index: int, end_index: int) -> void:
	"""指定範囲のグリフを描画"""
	if not canvas or not glyph_manager:
		return
	
	var rendered_count = 0
	var glyph_count = glyph_manager.text_glyphs.size()
	
	for i in range(max(0, start_index), min(end_index + 1, glyph_count)):
		var glyph = glyph_manager.text_glyphs[i]
		if glyph.is_visible:
			_render_single_glyph(canvas, glyph)
			rendered_count += 1
	
	if debug_mode:
		ArgodeSystem.log_workflow("🎨 GlyphRenderer: Rendered range %d-%d (%d glyphs)" % [start_index, end_index, rendered_count])

## === 個別グリフ描画 ===

func _render_single_glyph(canvas: Control, glyph: ArgodeTextGlyph) -> void:
	"""単一グリフを描画（エフェクト・位置・色・スケール適用）"""
	if not glyph or not glyph.font:
		ArgodeSystem.log_workflow("⚠️ GlyphRenderer: Invalid glyph or font")
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
	
	# デバッグ情報を出力
	if debug_mode:
		ArgodeSystem.log_workflow("🔤 Rendering glyph '%s' at %s, color: %s, scale: %.2f, font_size: %d" % [
			glyph.character, str(final_position), str(final_color), final_scale, font_size
		])
	
	# スケール適用されたフォントサイズを計算
	var scaled_font_size = int(font_size * final_scale)
	
	# 文字を描画
	if canvas.has_method("draw_string"):
		canvas.draw_string(
			font,
			final_position,
			glyph.character,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			scaled_font_size,
			final_color
		)
		if debug_mode:
			ArgodeSystem.log_workflow("✅ Drew glyph '%s' via draw_string" % glyph.character)
	elif canvas.has_method("draw_text_at"):
		canvas.draw_text_at(glyph.character, final_position, font, scaled_font_size, final_color)
		if debug_mode:
			ArgodeSystem.log_workflow("✅ Drew glyph '%s' via draw_text_at" % glyph.character)
	else:
		ArgodeSystem.log_workflow("❌ Canvas has no drawing methods available")
	
	# デバッグ情報の描画
	if debug_mode:
		_draw_debug_info(canvas, glyph, final_position, final_scale)

## === デバッグ描画機能 ===

func _draw_debug_info(canvas: Control, glyph: ArgodeTextGlyph, position: Vector2, scale: float) -> void:
	"""デバッグ情報の描画"""
	if not canvas.has_method("draw_rect"):
		return
	
	# 文字境界の描画
	if draw_character_bounds:
		var char_size = Vector2(glyph.font_size * scale, glyph.font_size * scale)
		var rect = Rect2(position, char_size)
		canvas.draw_rect(rect, Color.YELLOW, false, 1.0)
	
	# エフェクト情報の描画
	if draw_effect_info and glyph.effects.size() > 0:
		var info_text = "E:%d" % glyph.effects.size()
		var info_pos = position + Vector2(0, -15)
		if canvas.has_method("draw_string"):
			canvas.draw_string(
				glyph.font,
				info_pos,
				info_text,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				12,
				Color.CYAN
			)

## === バッチ描画機能 ===

func render_glyphs_batched(canvas: Control, glyph_manager: ArgodeGlyphManager) -> void:
	"""同一プロパティのグリフをバッチ描画（パフォーマンス最適化）"""
	if not batch_rendering:
		render_all_glyphs(canvas, glyph_manager)
		return
	
	# 同一プロパティでグループ化
	var glyph_batches = _group_glyphs_by_properties(glyph_manager.text_glyphs)
	
	# バッチごとに描画
	for batch in glyph_batches:
		_render_glyph_batch(canvas, batch)

func _group_glyphs_by_properties(glyphs: Array) -> Array:
	"""同一描画プロパティでグリフをグループ化"""
	var batches = []
	var current_batch = []
	var last_properties = {}
	
	for glyph in glyphs:
		if not glyph.is_visible:
			continue
		
		var render_info = glyph.get_render_info()
		var properties = {
			"font": render_info.get("font"),
			"font_size": render_info.get("font_size"),
			"color": render_info.get("color"),
			"scale": render_info.get("scale")
		}
		
		# プロパティが変わったら新しいバッチを開始
		if properties != last_properties:
			if current_batch.size() > 0:
				batches.append(current_batch.duplicate())
			current_batch.clear()
			last_properties = properties
		
		current_batch.append(glyph)
	
	# 最後のバッチを追加
	if current_batch.size() > 0:
		batches.append(current_batch)
	
	return batches

func _render_glyph_batch(canvas: Control, batch: Array) -> void:
	"""同一プロパティのグリフバッチを描画"""
	if batch.size() == 0:
		return
	
	# 最初のグリフからプロパティを取得
	var first_glyph = batch[0]
	var render_info = first_glyph.get_render_info()
	var font = render_info.get("font", first_glyph.font)
	var font_size = render_info.get("font_size", first_glyph.font_size)
	var color = render_info.get("color", Color.WHITE)
	var scale = render_info.get("scale", 1.0)
	
	var scaled_font_size = int(font_size * scale)
	
	# バッチ内の全グリフを描画
	for glyph in batch:
		var position = glyph.get_render_info().get("position", Vector2.ZERO)
		
		if canvas.has_method("draw_string"):
			canvas.draw_string(
				font,
				position,
				glyph.character,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				scaled_font_size,
				color
			)

## === 統計・設定機能 ===

func _update_render_stats(start_time: int, end_time: int, rendered_count: int) -> void:
	"""描画統計を更新"""
	# ミリ秒単位の時間計算
	var render_ms = end_time - start_time
	last_render_time = render_ms / 1000.0  # 秒に変換
	glyphs_rendered_count = rendered_count

func set_debug_mode(enabled: bool) -> void:
	"""デバッグモードの設定"""
	debug_mode = enabled
	draw_character_bounds = enabled
	draw_effect_info = enabled

func set_performance_settings(max_glyphs: int, batch_mode: bool) -> void:
	"""パフォーマンス設定"""
	max_glyphs_per_frame = max_glyphs
	batch_rendering = batch_mode

func get_render_stats() -> Dictionary:
	"""描画統計を取得"""
	return {
		"last_render_time": last_render_time,
		"glyphs_rendered": glyphs_rendered_count,
		"debug_mode": debug_mode,
		"batch_rendering": batch_rendering,
		"max_glyphs_per_frame": max_glyphs_per_frame
	}

## === ユーティリティ ===

func clear_stats() -> void:
	"""統計をクリア"""
	last_render_time = 0.0
	glyphs_rendered_count = 0

func get_visible_glyph_count(glyph_manager: ArgodeGlyphManager) -> int:
	"""表示可能グリフ数を取得"""
	if not glyph_manager:
		return 0
	
	var count = 0
	for glyph in glyph_manager.text_glyphs:
		if glyph.is_visible:
			count += 1
	return count
