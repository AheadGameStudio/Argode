extends RefCounted
class_name ArgodeTextRenderer

## 基本テキスト描画を専門に扱うレンダラー
## ArgodeMessageRendererから基本描画機能を分離

# 描画設定
var font_cache: Dictionary = {}
var default_color: Color = Color.WHITE
var line_spacing: float = 5.0

func _init():
	pass

## 基本的なテキスト描画
func draw_text_at_position(canvas, text: String, position: Vector2, font: Font, font_size: int, color: Color = Color.WHITE):
	"""単一行テキストを指定位置に描画"""
	if text.is_empty():
		return
	
	canvas.draw_text_at(text, position, font, font_size, color)

## 改行対応テキスト描画
func draw_wrapped_text(canvas, text: String, start_pos: Vector2, max_width: float, font: Font, font_size: int, color: Color, line_spacing: float = 5.0):
	"""改行とワードラップに対応したテキスト描画"""
	# テキストは既にInlineCommandManagerで正規化済み（\nに変換済み）
	var lines = text.split("\n")
	var current_y = start_pos.y
	
	for line in lines:
		if line.is_empty():
			current_y += font.get_height(font_size) + line_spacing
			continue
		
		# 文字が収まらない場合は単語で分割
		var words = line.split(" ")
		var current_line = ""
		
		for word in words:
			var test_line = current_line + (" " if not current_line.is_empty() else "") + word
			var text_width = font.get_string_size(test_line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			
			if text_width <= max_width:
				current_line = test_line
			else:
				# 現在の行を描画
				if not current_line.is_empty():
					canvas.draw_text_at(current_line, Vector2(start_pos.x, current_y), font, font_size, color)
					current_y += font.get_height(font_size) + line_spacing
				current_line = word
		
		# 最後の行を描画
		if not current_line.is_empty():
			canvas.draw_text_at(current_line, Vector2(start_pos.x, current_y), font, font_size, color)
			current_y += font.get_height(font_size) + line_spacing

## 文字単位での描画（アニメーション対応）
func draw_character_by_character(canvas, text: String, start_pos: Vector2, max_width: float, font: Font, font_size: int, base_color: Color, display_length: int, get_char_render_info_callback: Callable, get_animation_values_callback: Callable) -> Vector2:
	"""文字単位でアニメーション効果を適用しながら描画"""
	var current_x = start_pos.x
	var current_y = start_pos.y
	var current_position = 0
	
	# 文字単位で描画
	for i in range(text.length()):
		var char = text[i]
		
		if char == "\n":
			# 改行処理
			current_x = start_pos.x
			current_y += font.get_height(font_size) + line_spacing
			current_position += 1
			continue
		
		# 表示範囲外の文字は完全にスキップ（最も厳密なチェック）
		if current_position >= display_length:
			break
		
		# 描画情報を取得（装飾情報を含む）
		var render_info = base_color
		var current_font_size = font_size  # 元のフォントサイズを保持
		if get_char_render_info_callback.is_valid():
			var info = get_char_render_info_callback.call(char, font, font_size, base_color, current_position)
			render_info = info.get("color", base_color)
			current_font_size = info.get("font_size", font_size)
		
		# アニメーション効果を適用
		var final_position = Vector2(current_x, current_y)
		var final_color = render_info
		var should_render = true  # 描画フラグ
		
		if get_animation_values_callback.is_valid():
			var animation_values = get_animation_values_callback.call(current_position)
			
			# アニメーション値を適用
			if animation_values.has("alpha"):
				final_color.a *= animation_values.alpha
				# アルファ値が低い場合は描画しない（開始値を考慮してしきい値を下げる）
				if final_color.a < 0.01:
					should_render = false
			if animation_values.has("x_offset"):
				final_position.x += animation_values.x_offset
			if animation_values.has("y_offset"):
				final_position.y += animation_values.y_offset
			elif animation_values.has("offset_y"):  # 後方互換
				final_position.y += animation_values.offset_y
		
		# 文字を描画（アニメーション効果適用後）
		if should_render and final_color.a >= 0.01:  # アニメーション開始値を描画できるよう調整
			canvas.draw_text_at(char, final_position, font, current_font_size, final_color)
		
		# 次の文字位置を計算
		var char_width = font.get_string_size(char, HORIZONTAL_ALIGNMENT_LEFT, -1, current_font_size).x
		current_x += char_width
		current_position += 1
		
		# 行の幅制限チェック（簡易版）
		if current_x > start_pos.x + max_width:
			current_x = start_pos.x
			current_y += font.get_height(font_size) + line_spacing
	
	return Vector2(current_x, current_y)

## テキストサイズを計算
func calculate_text_size(text: String, font: Font, font_size: int, max_width: float = -1) -> Vector2:
	"""テキストの描画サイズを計算"""
	if text.is_empty():
		return Vector2.ZERO
	
	var lines = text.split("\n")
	var total_height = 0.0
	var max_line_width = 0.0
	
	for line in lines:
		var line_size = font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, max_width, font_size)
		max_line_width = max(max_line_width, line_size.x)
		total_height += line_size.y + line_spacing
	
	# 最後の行のline_spacingは不要
	if lines.size() > 0:
		total_height -= line_spacing
	
	return Vector2(max_line_width, total_height)

## 指定位置の文字座標を計算
func calculate_character_position(text: String, target_position: int, draw_position: Vector2, font: Font, font_size: int, max_display_length: int = -1) -> Vector2:
	"""指定された文字位置の正確な描画座標を計算"""
	var current_x = draw_position.x
	var current_y = draw_position.y
	
	# 表示されている文字数まで制限
	var max_position = target_position
	if max_display_length > 0:
		max_position = min(target_position, min(max_display_length, text.length()))
	else:
		max_position = min(target_position, text.length())
	
	# 対象位置まで1文字ずつ座標を計算
	for i in range(max_position):
		var char = text[i]
		
		if char == "\n":
			current_x = draw_position.x
			current_y += font.get_height(font_size) + line_spacing
		else:
			# 対象位置に到達したら現在の座標を返す（文字幅加算前）
			if i == target_position:
				return Vector2(current_x, current_y)
			
			var char_width = font.get_string_size(char, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			current_x += char_width
	
	return Vector2(current_x, current_y)

## フォント管理
func cache_font(font_key: String, font: Font):
	"""フォントをキャッシュに保存"""
	font_cache[font_key] = font

func get_cached_font(font_key: String) -> Font:
	"""キャッシュからフォントを取得"""
	return font_cache.get(font_key, null)

func clear_font_cache():
	"""フォントキャッシュをクリア"""
	font_cache.clear()
