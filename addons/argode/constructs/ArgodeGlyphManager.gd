extends RefCounted
class_name ArgodeGlyphManager

## 複数のArgodeTextGlyphを統合管理するマネージャー
## テキスト全体のレイアウト、エフェクト適用、描画制御を担当

# グリフ管理
var text_glyphs: Array = []  # Array[ArgodeTextGlyph]
var original_text: String = ""
var processed_text: String = ""  # インラインタグ除去後

# レイアウト設定
var base_position: Vector2 = Vector2.ZERO
var line_height: float = 30.0
var character_spacing: float = 2.0
var max_width: float = 400.0  # 自動改行幅

# フォント設定
var default_font: Font = null
var default_font_size: int = 20
var default_color: Color = Color.WHITE

# 時間管理
var start_time: float = 0.0
var current_time: float = 0.0

# 状態管理
var is_active: bool = false
var all_glyphs_visible: bool = false

# デバッグ設定
var debug_enabled: bool = false

signal glyph_appeared(glyph: ArgodeTextGlyph, index: int)
signal all_glyphs_appeared()
signal effects_completed()

func _init():
	text_glyphs.clear()

## テキストからグリフ配列を生成
func create_glyphs_from_text(text: String) -> void:
	"""
	テキストから個別のArgodeTextGlyphを生成
	基本レイアウト計算も実行
	"""
	clear_glyphs()
	original_text = text
	processed_text = text
	
	# 文字単位でグリフを生成
	var current_pos = base_position
	var line_start_x = base_position.x
	
	for i in range(text.length()):
		var char = text[i]
		var glyph = ArgodeTextGlyph.new(char, i)
		
		# フォント・色の基本設定
		glyph.set_font_info(default_font, default_font_size)
		glyph.set_base_color(default_color)
		
		# 改行処理
		if char == "\n":
			current_pos.y += line_height
			current_pos.x = line_start_x
		else:
			# 文字の幅を計算（概算）
			var char_width = get_character_width(char, default_font, default_font_size)
			
			# 自動改行チェック
			if max_width > 0 and current_pos.x + char_width > base_position.x + max_width:
				current_pos.y += line_height
				current_pos.x = line_start_x
			
			glyph.set_base_position(current_pos)
			current_pos.x += char_width + character_spacing
		
		text_glyphs.append(glyph)
	
	ArgodeSystem.log("📝 GlyphManager: Created %d glyphs from text: '%s'" % [text_glyphs.size(), text.substr(0, 20) + ("..." if text.length() > 20 else "")])

## すべてのグリフをクリア
func clear_glyphs() -> void:
	text_glyphs.clear()
	all_glyphs_visible = false

## 指定インデックスのグリフを表示
func show_glyph(index: int) -> void:
	if index < 0 or index >= text_glyphs.size():
		return
	
	var glyph = text_glyphs[index]
	if not glyph.is_visible:
		glyph.set_visible(true, current_time)
		glyph_appeared.emit(glyph, index)
		
		# 全グリフ表示完了チェック
		if index == text_glyphs.size() - 1:
			all_glyphs_visible = true
			all_glyphs_appeared.emit()

## 指定範囲のグリフを表示
func show_glyphs_range(start_index: int, end_index: int) -> void:
	for i in range(start_index, min(end_index + 1, text_glyphs.size())):
		show_glyph(i)

## すべてのグリフを即座に表示
func show_all_glyphs_instantly() -> void:
	"""全グリフを即座に表示し、すべてのエフェクトを最終状態に設定"""
	ArgodeSystem.log("⚡ GlyphManager: Showing all glyphs instantly with final effect states")
	
	for i in range(text_glyphs.size()):
		show_glyph(i)
		
		# エフェクトを最終状態（完了状態）に設定
		var glyph = text_glyphs[i]
		if glyph.effects.size() > 0:
			for effect in glyph.effects:
				if effect.has_method("set_to_final_state"):
					effect.set_to_final_state()
					# エフェクトの最終状態をグリフに手動適用
					_apply_final_effect_state(glyph, effect)
				else:
					# フォールバック: エフェクトを完了状態にマーク
					effect.is_active = true
					effect.is_completed = true
					# 手動で最終状態を適用
					_force_apply_effect_final_state(glyph, effect)
	
	# 全表示完了状態に設定
	all_glyphs_visible = true
	ArgodeSystem.log("✅ GlyphManager: All glyphs and effects set to final state")

## エフェクトの最終状態をグリフに適用
func _apply_final_effect_state(glyph, effect):
	"""スキップ時にエフェクトの最終状態をグリフに直接適用"""
	if effect.effect_name == "ScaleEffect":
		glyph.current_scale = effect.target_scale
	elif effect.effect_name == "MoveEffect":
		if effect.has_property("target_offset"):
			glyph.current_offset = effect.target_offset
	elif effect.effect_name == "ColorEffect":
		if effect.has_property("target_color"):
			glyph.current_color = effect.target_color
	
	ArgodeSystem.log("⚡ Applied final state for %s to glyph '%s'" % [effect.effect_name, glyph.character])

## エフェクトの最終状態を強制的に適用（フォールバック）
func _force_apply_effect_final_state(glyph, effect):
	"""set_to_final_stateメソッドがないエフェクトの最終状態を強制適用"""
	# エフェクト名から最終状態を推測
	var effect_name = effect.effect_name if effect.has_property("effect_name") else effect.get_script().get_path().get_file().get_basename()
	
	if "Scale" in effect_name and effect.has_property("target_scale"):
		glyph.current_scale = effect.target_scale
		ArgodeSystem.log("⚡ Force applied scale %.2f to glyph '%s'" % [effect.target_scale, glyph.character])
	elif "Move" in effect_name and effect.has_property("target_offset"):
		glyph.current_offset = effect.target_offset
		ArgodeSystem.log("⚡ Force applied move %s to glyph '%s'" % [effect.target_offset, glyph.character])
	elif "Color" in effect_name and effect.has_property("target_color"):
		glyph.current_color = effect.target_color
		ArgodeSystem.log("⚡ Force applied color to glyph '%s'" % glyph.character)

## 特定グリフにエフェクトを追加
func add_effect_to_glyph(glyph_index: int, effect) -> void:  # ArgodeTextEffect
	if glyph_index >= 0 and glyph_index < text_glyphs.size():
		text_glyphs[glyph_index].add_effect(effect)

## 範囲のグリフにエフェクトを追加
func add_effect_to_range(start_index: int, end_index: int, effect) -> void:
	for i in range(start_index, min(end_index + 1, text_glyphs.size())):
		var effect_copy = duplicate_effect(effect)  # エフェクトを複製
		add_effect_to_glyph(i, effect_copy)

## 全グリフにエフェクトを追加
func add_effect_to_all(effect) -> void:
	add_effect_to_range(0, text_glyphs.size() - 1, effect)

## エフェクトを複製（基本的な複製）
func duplicate_effect(original_effect):
	# 基本的なエフェクト複製（型に応じてより詳細な実装が必要）
	if original_effect.has_method("duplicate"):
		return original_effect.duplicate()
	else:
		# フォールバック: 同じ型の新しいインスタンス
		ArgodeSystem.log("⚠️ Effect duplication not implemented for: %s" % original_effect.get_effect_name())
		return original_effect

## すべてのグリフのエフェクトを更新
func update_all_effects(delta: float) -> void:
	# タイプライター一時停止中は時間進行を停止
	if typewriter_paused:
		return
		
	current_time += delta
	var any_effects_active = false
	
	for glyph in text_glyphs:
		if glyph.is_visible and glyph.effects.size() > 0:
			var elapsed = current_time - glyph.appear_time
			glyph.update_effects(elapsed)
			
			# アクティブなエフェクトがあるかチェック
			for effect in glyph.effects:
				if effect.is_active and not effect.is_effect_completed():
					any_effects_active = true
	
	# スケールエフェクト適用時の動的レイアウト更新
	update_dynamic_layout()
	
	# 全エフェクト完了シグナル
	if not any_effects_active and all_glyphs_visible:
		effects_completed.emit()

## 動的レイアウト更新（スケール変化に対応）
func update_dynamic_layout() -> void:
	"""スケールエフェクトによる文字サイズ変化を考慮してレイアウトを再計算"""
	if text_glyphs.size() == 0:
		return
	
	var current_pos = base_position
	var line_start_x = base_position.x
	
	for i in range(text_glyphs.size()):
		var glyph = text_glyphs[i]
		var char = glyph.character
		
		# 改行処理
		if char == "\n":
			current_pos.y += line_height
			current_pos.x = line_start_x
			glyph.set_current_position(current_pos)
		else:
			# 現在のスケールを考慮した文字幅を計算
			var base_width = get_character_width(char, default_font, default_font_size)
			var scaled_width = base_width * glyph.current_scale
			
			# 自動改行チェック（スケール後の幅で）
			if max_width > 0 and current_pos.x + scaled_width > base_position.x + max_width:
				current_pos.y += line_height
				current_pos.x = line_start_x
			
			glyph.set_current_position(current_pos)
			current_pos.x += scaled_width + character_spacing

## 文字幅を計算（概算）
func get_character_width(char: String, font: Font, font_size: int) -> float:
	if font and font.has_method("get_string_size"):
		return font.get_string_size(char, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	else:
		# フォールバック: 固定幅
		return font_size * 0.6

## レイアウト設定
func set_layout_settings(pos: Vector2, line_h: float, char_spacing: float, width: float = -1) -> void:
	base_position = pos
	line_height = line_h
	character_spacing = char_spacing
	if width > 0:
		max_width = width

## フォント設定
func set_font_settings(font: Font, size: int, color: Color) -> void:
	default_font = font
	default_font_size = size
	default_color = color

## 時間をリセット
func reset_time() -> void:
	start_time = Time.get_unix_time_from_system()
	current_time = 0.0

## 描画用グリフ情報をすべて取得
func get_all_render_info() -> Array:
	var render_infos = []
	for glyph in text_glyphs:
		if glyph.is_visible:
			render_infos.append(glyph.get_render_info())
	return render_infos

## 表示済みグリフ数を取得
func get_visible_glyph_count() -> int:
	var count = 0
	for glyph in text_glyphs:
		if glyph.is_visible:
			count += 1
	return count

## 指定位置のグリフを取得
func get_glyph_at_index(index: int):  # -> ArgodeTextGlyph
	if index >= 0 and index < text_glyphs.size():
		return text_glyphs[index]
	return null

## 装飾情報をグリフに適用
func apply_decorations(decoration_renderer: ArgodeDecorationRenderer) -> void:
	"""DecorationRendererからの装飾情報をグリフに適用"""
	if not decoration_renderer:
		return
	
	ArgodeSystem.log("🎨 GlyphManager: Applying decorations to %d glyphs" % text_glyphs.size())
	
	for i in range(text_glyphs.size()):
		var glyph = text_glyphs[i]
		var decorations = decoration_renderer.get_active_decorations_at_position(i)
		
		if decorations.size() > 0:
			# 装飾情報に基づいて描画情報を計算
			var render_info = decoration_renderer.calculate_char_render_info(
				glyph.character, glyph.font, glyph.font_size, glyph.base_color, decorations
			)
			
			# 計算された情報をグリフに適用
			if render_info.has("color"):
				glyph.set_base_color(render_info.color)
			
			if render_info.has("scale") and render_info.scale != Vector2.ONE:
				var scale_factor = max(render_info.scale.x, render_info.scale.y)
				glyph.set_base_scale(scale_factor)
				ArgodeSystem.log("📏 Applied scale %.2f to glyph '%s' at position %d" % [scale_factor, glyph.character, i])
			
			if render_info.has("offset") and render_info.offset != Vector2.ZERO:
				glyph.offset_position = render_info.offset
				glyph.set_current_position(glyph.base_position + glyph.offset_position)
				ArgodeSystem.log("🎯 Applied offset %s to glyph '%s' at position %d" % [render_info.offset, glyph.character, i])
			
			if render_info.has("font_size") and render_info.font_size != glyph.font_size:
				glyph.font_size = render_info.font_size
				ArgodeSystem.log("📏 Applied font size %d to glyph '%s' at position %d" % [render_info.font_size, glyph.character, i])

## 全グリフ配列を取得
func get_all_glyphs() -> Array:
	return text_glyphs

## デバッグ情報を出力
func debug_print_all() -> void:
	ArgodeSystem.log("📝 GlyphManager Debug Info:")
	ArgodeSystem.log("  - Original text: '%s'" % original_text)
	ArgodeSystem.log("  - Total glyphs: %d" % text_glyphs.size())
	ArgodeSystem.log("  - Visible glyphs: %d" % get_visible_glyph_count())
	ArgodeSystem.log("  - All visible: %s" % str(all_glyphs_visible))
	ArgodeSystem.log("  - Current time: %.2fs" % current_time)
	
	if debug_enabled:
		for i in range(min(text_glyphs.size(), 5)):  # 最初の5文字のみ詳細表示
			text_glyphs[i].debug_print()

## アクティブ状態を設定
func set_active(active: bool) -> void:
	is_active = active
	if active:
		reset_time()

## タイプライター制御（v1.2.0追加機能）
var typewriter_paused: bool = false
var pause_timer: Timer = null

## タイプライター一時停止
func pause_typewriter(duration: float) -> void:
	"""指定時間タイプライターを一時停止"""
	if not is_active:
		return
	
	typewriter_paused = true
	ArgodeSystem.log("⏸️ GlyphManager: Typewriter paused for %.1f seconds" % duration)
	
	# 既存のタイマーをクリーンアップ
	if pause_timer and is_instance_valid(pause_timer):
		pause_timer.queue_free()
	
	# 新しいタイマーを作成
	pause_timer = Timer.new()
	pause_timer.wait_time = duration
	pause_timer.one_shot = true
	
	# ArgodeSystemにタイマーを追加
	if ArgodeSystem.has_method("add_child"):
		ArgodeSystem.add_child(pause_timer)
	else:
		# フォールバック: Engine.get_main_loop()を使用
		Engine.get_main_loop().root.add_child(pause_timer)
	
	# タイマー完了時に再開
	pause_timer.timeout.connect(_resume_typewriter)
	pause_timer.start()

## タイプライター再開
func _resume_typewriter() -> void:
	"""タイプライターを再開"""
	typewriter_paused = false
	ArgodeSystem.log("▶️ GlyphManager: Typewriter resumed")
	
	# タイマーをクリーンアップ
	if pause_timer and is_instance_valid(pause_timer):
		pause_timer.queue_free()
		pause_timer = null

## タイプライター状態確認
func is_typewriter_paused() -> bool:
	return typewriter_paused
