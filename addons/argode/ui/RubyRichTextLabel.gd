# RubyRichTextLabel.gd
# ルビ表示機能付きのRichTextLabel
extends RichTextLabel
class_name RubyRichTextLabel

# ルビ表示用のデータ
var ruby_data: Array[Dictionary] = []
var display_ruby_data: Array[Dictionary] = []  # 実際に表示するルビ情報
var raw_ruby_data: Array = []  # スキップ時の再計算用に生ルビデータを保存

# 調整パラメータ
var ruby_offset_x: float = 0.0  ## ルビのX位置オフセット（正確な中央配置のため無効化）

# フォント設定
var ruby_font: Font
var ruby_main_font: Font

# デバッグ設定
var show_ruby_debug = true  # デバッグ表示を有効化
var debug_baseline_data: Array[Dictionary] = []  # ベースライン情報を保存

# 行のベースライン位置キャッシュ（行の高さが変わってもルビ位置を安定させるため）
var line_baseline_cache: Dictionary = {}  # line_number -> baseline_y の辞書
var previous_text_length: int = 0  # テキスト変更を検出するため
var previous_text_content: String = ""  # より正確な変更検出のため

func _ready():
	# フォントを設定
	_setup_ruby_fonts()
	# テキスト変更の監視：プロセス中でチェック
	previous_text_length = text.length()
	previous_text_content = text

func _process(_delta):
	"""フレームごとにテキスト変更を監視 - パフォーマンス向上のため無効化"""
	# 頻繁なキャッシュクリアが動きの原因となるため、必要最小限のみクリア
	pass

func _setup_ruby_fonts():
	"""ルビ表示用のフォントを設定"""
	# メインテキストのフォントを取得
	if has_theme_font_override("font"):
		ruby_main_font = get_theme_font("font")
	else:
		ruby_main_font = get_theme_default_font()
	
	# ルビ用フォントも同じものを使用（サイズは小さく）
	ruby_font = ruby_main_font
	
	print("🔤 [Ruby Font] Main font: %s, Ruby font: %s" % [ruby_main_font, ruby_font])

func _draw():
	"""ルビを描画"""
	if not show_ruby_debug and display_ruby_data.is_empty():
		return
	
	print("🎨 [Ruby Draw] Drawing %d rubies (debug=%s)" % [display_ruby_data.size(), show_ruby_debug])
	
	# デバッグ表示
	if show_ruby_debug:
		_draw_debug_info()
		_draw_baseline_debug()
	
	# ルビを描画
	for ruby_info in display_ruby_data:
		_draw_single_ruby(ruby_info)

func _draw_debug_info():
	"""デバッグ情報を描画"""
	var debug_color = Color.YELLOW
	var font_size = 12
	
	# 背景として薄い矩形を描画
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.3))
	
	# デバッグテキスト
	var debug_text = "Ruby Debug: %d rubies" % display_ruby_data.size()
	if ruby_main_font:
		draw_string(ruby_main_font, Vector2(5, 20), debug_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, debug_color)

func _draw_baseline_debug():
	"""ベースライン情報をデバッグ表示"""
	if debug_baseline_data.is_empty():
		return
	
	print("🔍 [Debug Draw] Drawing %d baseline(s)" % debug_baseline_data.size())
	
	# RichTextLabelの実際のテキスト描画位置をデバッグ表示
	var actual_text_height = get_content_height()
	var line_count = get_line_count()
	print("🔍 [RichTextLabel Debug] content_height=%f, line_count=%d" % [actual_text_height, line_count])
	
	# 実際の行の高さを取得してみる
	for i in range(min(line_count, 4)):  # 最初の4行まで
		var line_height = get_theme_font("font").get_height(get_theme_font_size("font_size"))
		var expected_y = i * line_height
		print("🔍 [RichTextLabel] Line %d expected at y=%f" % [i, expected_y])
		# 期待される位置に緑の線を描画
		draw_line(Vector2(0, expected_y), Vector2(size.x, expected_y), Color.GREEN, 1.0)
	
	for baseline_info in debug_baseline_data:
		var line_num = baseline_info.line
		var baseline_y = baseline_info.baseline_y
		var ruby_y = baseline_info.ruby_y
		
		# ベースライン（青）
		draw_line(Vector2(0, baseline_y), Vector2(size.x, baseline_y), Color.BLUE, 2.0)
		# ルビライン（赤）
		draw_line(Vector2(0, ruby_y), Vector2(size.x, ruby_y), Color.RED, 1.0)
		
		# 行番号を表示
		var font = get_theme_font("font") if get_theme_font("font") else ruby_main_font
		if font:
			draw_string(font, Vector2(5, baseline_y - 5), "Line %d (base: %.1f, ruby: %.1f)" % [line_num, baseline_y, ruby_y], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.YELLOW)

func _draw_single_ruby(ruby_info: Dictionary):
	"""単一のルビを描画"""
	var reading = ruby_info.get("reading", "")
	var position = ruby_info.get("position", Vector2.ZERO)
	var color = ruby_info.get("color", Color.WHITE)
	var kanji_text = ruby_info.get("kanji", "")
	var font_ascent = ruby_info.get("font_ascent", 0)
	var line_separation = ruby_info.get("line_separation", 0)
	var current_line = ruby_info.get("current_line", 0)

	if reading.is_empty() or not ruby_font:
		return
	
	# ルビ対象文字が完全に表示されているかチェック
	if not kanji_text.is_empty():
		var displayed_text = get_parsed_text()
		var regex = RegEx.new()
		regex.compile("\\[/?[^\\]]*\\]")  # BBCodeタグを除去
		var clean_displayed_text = regex.sub(displayed_text, "", true)
		
		# ルビ対象文字がまだ表示されていない場合はdraw_stringしない
		if not clean_displayed_text.contains(kanji_text):
			return
	
	# メインフォントサイズに応じてルビフォントサイズを調整
	var main_font_size = 16
	if has_theme_font_size_override("font_size"):
		main_font_size = get_theme_font_size("font_size")
	elif get_theme_font_size("font_size") > 0:
		main_font_size = get_theme_font_size("font_size")
	
	var ruby_font_size = max(8, main_font_size * 0.7)  # メインフォントサイズの70%
	
	# ルビテキストを描画
	var _ruby_text_pos:Vector2 = position	# このほうがきれいに表示される
	draw_string(ruby_font, _ruby_text_pos, reading, HORIZONTAL_ALIGNMENT_LEFT, -1, ruby_font_size, color)

	# デバッグ用の位置マーカー
	if show_ruby_debug:
		draw_circle(position, 3, Color.RED)
		draw_circle(position + Vector2(0, ruby_font_size), 2, Color.BLUE)

func set_ruby_data(data: Array[Dictionary]):
	"""ルビデータを設定"""
	ruby_data = data.duplicate(true)
	display_ruby_data = ruby_data.duplicate(true)
	# 新しいルビデータが設定されたので行ベースラインキャッシュをクリア
	line_baseline_cache.clear()
	queue_redraw()

func set_display_ruby_data(data: Array[Dictionary]):
	"""表示用ルビデータを設定（タイプライター効果用）"""
	display_ruby_data = data.duplicate(true)
	queue_redraw()

func clear_ruby_data():
	"""ルビデータをクリア"""
	ruby_data.clear()
	display_ruby_data.clear()
	# ルビデータがクリアされたので行ベースラインキャッシュもクリア
	line_baseline_cache.clear()
	queue_redraw()

func _adjust_text_for_ruby_line_breaks(text: String, ruby_positions: Array) -> String:
	"""ルビ対象文字が行をまたがないように改行文字を挿入"""
	if ruby_positions.is_empty():
		return text
	
	print("🔧 [Ruby Line Break] Adjusting text for ruby line breaks")
	print("🔧 [Ruby Line Break] Ruby positions count: %d" % ruby_positions.size())
	
	# フォントを安全に取得
	var font = get_theme_font("font")
	if not font:
		font = ruby_main_font
	if not font:
		font = get_theme_default_font()
	
	if not font:
		print("🔧 [Ruby Line Break] Warning: No font available, returning original text")
		return text
	
	# 利用可能な幅を取得
	var available_width = get_content_width()
	if available_width <= 0:
		# より確実な幅の取得方法
		available_width = size.x
		if has_theme_stylebox("normal"):
			var stylebox = get_theme_stylebox("normal")
			if stylebox:
				available_width -= stylebox.get_margin(SIDE_LEFT) + stylebox.get_margin(SIDE_RIGHT)
		if available_width <= 0:
			available_width = 400  # 最小デフォルト値
	
	print("🔧 [Ruby Line Break] Available width: %d (size.x: %d)" % [available_width, size.x])
	
	# フォントサイズを取得
	var font_size = 16
	if has_theme_font_size_override("font_size"):
		font_size = get_theme_font_size("font_size")
	elif get_theme_font_size("font_size") > 0:
		font_size = get_theme_font_size("font_size")
	
	print("🔧 [Ruby Line Break] Using font size: %d" % font_size)
	
	var result_text = ""
	var current_x = 0.0
	var i = 0
	
	while i < text.length():
		var char = text[i]
		
		# 明示的な改行文字の処理
		if char == "\n":
			result_text += char
			current_x = 0.0
			i += 1
			continue
		
		# この位置からルビ対象文字が始まるかチェック
		var ruby_length = _get_ruby_length_at_position(text, i, ruby_positions)
		
		if ruby_length > 0:
			# ルビ対象文字の全体幅を計算
			var ruby_text = text.substr(i, ruby_length)
			var ruby_width = font.get_string_size(ruby_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			
			print("🔧 [Ruby Line Break] Found ruby text: '%s' at pos %d, width: %d" % [ruby_text, i, ruby_width])
			print("🔧 [Ruby Line Break] Current X: %d, Available: %d, Would fit: %s" % [current_x, available_width, (current_x + ruby_width <= available_width)])
			
			# 現在の行に収まるかチェック - より積極的な改行判定
			if current_x > 10 and current_x + ruby_width > available_width * 0.9:  # 90%で改行判定
				# 改行を挿入してルビ対象文字を次の行に移動
				result_text += "\n"
				current_x = 0.0
				print("🔧 [Ruby Line Break] ✅ Inserted line break before ruby text: '%s' (width would exceed 90%% of available)" % ruby_text)
			
			# ルビ対象文字を追加
			result_text += ruby_text
			current_x += ruby_width
			i += ruby_length
		else:
			# 通常の文字処理
			var char_width = font.get_string_size(char, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			
			# 自動改行チェック - より積極的な改行判定
			if current_x + char_width > available_width * 0.95 and current_x > 10:  # 95%で改行判定
				result_text += "\n"
				current_x = char_width
				print("🔧 [Ruby Line Break] Normal char line break at: '%s'" % char)
			else:
				current_x += char_width
			
			result_text += char
			i += 1
	
	print("🔧 [Ruby Line Break] Final result text: '%s'" % result_text.replace("\n", "\\n"))
	return result_text

func _get_ruby_length_at_position(text: String, pos: int, ruby_positions: Array) -> int:
	"""指定した位置からルビ対象文字が始まる場合、その長さを返す"""
	for ruby_info in ruby_positions:
		var kanji = ruby_info.get("kanji", "")
		var clean_pos = ruby_info.get("clean_pos", -1)
		
		if clean_pos == pos:
			print("🔧 [Ruby Position Check] Found ruby at pos %d: '%s' (length: %d)" % [pos, kanji, kanji.length()])
			return kanji.length()
	
	return 0

func get_ruby_data() -> Array:
	"""現在のルビデータを取得"""
	return ruby_data

func get_raw_ruby_data() -> Array:
	"""生ルビデータを取得（スキップ時の再計算用）"""
	return raw_ruby_data

func _get_character_position(text: String, char_index: int, font_size: int) -> Dictionary:
	"""指定した文字の位置を計算（RichTextLabelの実際の描画位置に基づく）"""
	if char_index < 0 or char_index >= text.length():
		return {"x": 0.0, "y": 0.0, "line": 0}
	
	# RichTextLabelの実際のコンテンツサイズと行数を取得
	var content_height = get_content_height()
	var line_count = get_line_count()
	var actual_line_height = content_height / max(1, line_count) if line_count > 0 else 20
	
	print("🔍 [Real Position] content_height=%f, line_count=%d, actual_line_height=%f" % [content_height, line_count, actual_line_height])
	
	# 利用可能な幅を取得（RichTextLabelの実際の内容領域）
	var available_width = get_content_width()
	if available_width <= 0:
		available_width = size.x - 10  # パディングを考慮
	
	# フォント情報を取得
	var font_ascent = ruby_main_font.get_ascent(font_size)
	
	# 文字を一文字ずつ処理して改行位置を計算
	var current_x = 0.0
	var current_line = 0
	var line_start_index = 0
	var line_positions = []  # 各行の開始X座標を記録
	
	for i in range(char_index + 1):
		var char = text[i]
		
		# 明示的な改行文字
		if char == "\n":
			current_x = 0.0
			current_line += 1
			line_start_index = i + 1
			continue
		
		# 文字幅を計算
		var char_width = ruby_main_font.get_string_size(char, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		
		# 自動改行チェック
		if current_x + char_width > available_width and current_x > 0:
			# 改行が必要
			current_x = char_width
			current_line += 1
			line_start_index = i
		else:
			current_x += char_width
	
	# RichTextLabelの実際の描画に合わせた位置を計算
	# パディングやマージンを考慮
	var padding_top = get_theme_constant("margin_top") if get_theme_constant("margin_top") > 0 else 0
	
	# 行のベースライン位置をキャッシュして安定化
	var cache_key = str(current_line)
	var real_y: float
	
	if line_baseline_cache.has(cache_key):
		# キャッシュされた位置を使用（既存の行は位置を固定）
		real_y = line_baseline_cache[cache_key]
		print("🔍 [Baseline Cache] Using cached baseline for line %d: %f" % [current_line, real_y])
	else:
		# 新しい行なので位置を計算してキャッシュ
		real_y = padding_top + current_line * actual_line_height + font_ascent
		line_baseline_cache[cache_key] = real_y
		print("🔍 [Baseline Cache] Cached new baseline for line %d: %f (padding=%d, line_height=%f, ascent=%f)" % [current_line, real_y, padding_top, actual_line_height, font_ascent])
	
	
	print("🔍 [Real Position] char_index=%d, line=%d, real_y=%f (padding_top=%d, line*height=%f, ascent=%f)" % [char_index, current_line, real_y, padding_top, current_line * actual_line_height, font_ascent])
	
	# X座標の計算：current_xは現在の文字が終わった位置なので、文字幅を引いて開始位置を求める
	var char_width = ruby_main_font.get_string_size(text[char_index], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var final_x = current_x - char_width
	
	print("🔍 [X Position Debug] char_index=%d, current_x=%f, char_width=%f, final_x=%f, char='%s'" % [char_index, current_x, char_width, final_x, text[char_index]])
	
	return {
		"x": final_x,
		"y": real_y,
		"line": current_line,
		"font_ascent": font_ascent,
		"line_separation": 0
	}

func update_ruby_positions_for_visible(visible_rubies: Array, typed_position: int):
	"""タイプライター位置に応じてルビの表示を更新"""
	print("🔍 [Ruby Visibility] typed_position=%d, ruby_data.size()=%d" % [typed_position, ruby_data.size()])
	
	if ruby_data.is_empty():
		print("🔍 [Ruby Visibility] ruby_data is empty - returning early")
		return
	
	var visible_ruby_data = []
	for ruby_info in visible_rubies:
		var kanji_start_pos = ruby_info.get("clean_pos", 0)
		var kanji_text = ruby_info.get("kanji", "")
		var kanji_end_pos = kanji_start_pos + kanji_text.length()
		
		# ルビ対象文字が完全に表示されている場合のみルビを表示
		if kanji_end_pos <= typed_position:
			visible_ruby_data.append(ruby_info)
			print("🔍 [Ruby Visible] Kanji '%s' at pos %d-%d is fully visible (typed: %d)" % [kanji_text, kanji_start_pos, kanji_end_pos, typed_position])
		else:
			print("🔍 [Ruby Hidden] Kanji '%s' at pos %d-%d not yet fully visible (typed: %d)" % [kanji_text, kanji_start_pos, kanji_end_pos, typed_position])
	
	print("🔍 [Ruby Visibility] visible_rubies count: %d" % visible_ruby_data.size())
	
	# 表示するルビがある場合のみ位置を計算
	if visible_ruby_data.size() > 0:
		_calculate_ruby_positions_for_visible(visible_ruby_data, get_parsed_text())
	else:
		print("🔍 [Ruby Visibility] No visible rubies - clearing display data")
		display_ruby_data.clear()
		queue_redraw()

func _calculate_ruby_positions_for_visible(visible_rubies: Array, target_text: String = ""):
	"""表示中のルビの位置を計算（座標系がシンプルに）"""
	print("📍 [Ruby Position Calc] _calculate_ruby_positions_for_visible")
	
	if visible_rubies.size() == 0:
		print("🔍 [Ruby Protection] No visible rubies - clearing display data")
		display_ruby_data.clear()
		queue_redraw()
		return
	
	display_ruby_data.clear()
	
	if not ruby_main_font:
		return
	
	# フォントサイズを正確に取得
	var font_size = 16  # デフォルト値
	if has_theme_font_size_override("font_size"):
		font_size = get_theme_font_size("font_size")
		print("🔍 [Font Size] Using theme override: %d" % font_size)
	elif get_theme_font_size("font_size") > 0:
		font_size = get_theme_font_size("font_size")
		print("🔍 [Font Size] Using theme default: %d" % font_size)
	else:
		print("🔍 [Font Size] Using fallback default: %d" % font_size)
	
	for ruby in visible_rubies:
		var kanji_text = ruby.get("kanji", "")
		var reading_text = ruby.get("reading", "")
		var kanji_pos_in_text = ruby.get("clean_pos", 0)
		
		print("🔍 [Visible Ruby] kanji='%s', reading='%s', clean_pos=%s (original ruby: %s)" % [kanji_text, reading_text, kanji_pos_in_text, ruby])
		
		# BBCodeタグを除去したプレーンテキストを取得
		var displayed_text = target_text if not target_text.is_empty() else get_parsed_text()
		
		# BBCodeタグを除去してテキスト幅を正確に計算
		var regex = RegEx.new()
		regex.compile("\\[/?[^\\]]*\\]")  # BBCodeタグをマッチ
		var clean_displayed_text = regex.sub(displayed_text, "", true)
		
		# clean_posを完全に信頼する（重複文字問題の解決）
		var kanji_start_in_displayed = kanji_pos_in_text
		
		# デバッグ情報を詳しく出力
		print("🔍 [Ruby Position] kanji='%s', clean_pos=%d, clean_text_length=%d" % [kanji_text, kanji_pos_in_text, clean_displayed_text.length()])
		if kanji_pos_in_text >= 0 and kanji_pos_in_text < clean_displayed_text.length():
			var text_at_pos = clean_displayed_text.substr(kanji_pos_in_text, min(kanji_text.length(), clean_displayed_text.length() - kanji_pos_in_text))
			print("🔍 [Ruby Position] text_at_clean_pos='%s' (expected='%s')" % [text_at_pos, kanji_text])
		
		# サニティチェック1：位置が有効な範囲内か確認
		if kanji_start_in_displayed < 0 or kanji_start_in_displayed >= clean_displayed_text.length():
			print("🔍 [Ruby Position] clean_pos out of range, using position 0")
			kanji_start_in_displayed = 0
		# サニティチェック2は一時的に無効化してclean_posを信頼

		# 改行を考慮した位置計算（自動改行対応）
		var char_position = _get_character_position(clean_displayed_text, kanji_start_in_displayed, font_size)
		var text_width = char_position.x
		var line_number = char_position.line
		var y_offset = char_position.y
		var font_ascent = char_position.get("font_ascent", ruby_main_font.get_ascent(font_size))
		
		# 漢字とルビの幅を計算
		var kanji_width = ruby_main_font.get_string_size(kanji_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var ruby_font_size = max(8, font_size * 0.7)  # メインフォントサイズの70%
		var ruby_width = ruby_font.get_string_size(reading_text, HORIZONTAL_ALIGNMENT_LEFT, -1, ruby_font_size).x
		
		# ルビを漢字の中央に配置：漢字の開始位置 + (漢字幅 - ルビ幅) / 2（オフセットなしで正確な中央配置）
		var ruby_x = text_width + (kanji_width - ruby_width) / 2
		
		print("🔍 [Ruby X-Calc] kanji='%s': text_width=%f, kanji_width=%f, ruby_width=%f" % [kanji_text, text_width, kanji_width, ruby_width])
		print("🔍 [Ruby X-Calc] centering: text_width=%f + (kanji_width=%f - ruby_width=%f) / 2 = %f" % [text_width, kanji_width, ruby_width, ruby_x])
		# ルビの縦位置：ベースラインからルビフォントサイズ分上に配置（マージンを8pxに増加）
		var ruby_y = y_offset - ruby_font_size - 14
		
		print("🔍 [Ruby Position Debug] line_number=%d, y_offset=%f, font_ascent=%f, ruby_font_size=%d, final_ruby_y=%f" % [line_number, y_offset, font_ascent, ruby_font_size, ruby_y])
		
		# デバッグ用にベースライン情報を記録
		if show_ruby_debug:
			var baseline_info = {
				"line": line_number,
				"y_offset": y_offset,
				"font_ascent": font_ascent,
				"baseline_y": y_offset,  # テキストのベースライン
				"ruby_y": ruby_y,
				"kanji_text": kanji_text
			}
			debug_baseline_data.append(baseline_info)
		
		display_ruby_data.append({
			"reading": reading_text,
			"kanji": kanji_text,
			"position": Vector2(ruby_x, ruby_y),
			"color": Color(0.9, 0.9, 0.9, 1.0)
		})
		
		print("🔍 [Ruby Position] Ruby '%s' at position (%f, %f) [line %d]" % [reading_text, ruby_x, ruby_y, line_number])
		print("🔍 [Ruby Debug] font_size=%d, kanji_text='%s', kanji_pos_in_text=%d" % [font_size, kanji_text, kanji_pos_in_text])
		print("🔍 [Ruby Debug] displayed_text='%s'" % displayed_text)
		print("🔍 [Ruby Debug] clean_displayed_text='%s'" % clean_displayed_text)
		print("🔍 [Ruby Debug] kanji_start_in_displayed=%d (searched from %d)" % [kanji_start_in_displayed, max(0, kanji_pos_in_text - 10)])
		print("🔍 [Ruby Debug] text_width=%f, y_offset=%f" % [text_width, y_offset])
		print("🔍 [Ruby Debug] line_number=%d, y_offset=%f" % [line_number, y_offset])
		print("🔍 [Ruby Debug] kanji_width=%f, ruby_width=%f" % [kanji_width, ruby_width])
		print("🔍 [Ruby Debug] final ruby_x=%f (text_width + (kanji_width - ruby_width) / 2)" % ruby_x)
	
	print("🔍 [Ruby Position] Updated display_ruby_data with %d rubies" % display_ruby_data.size())
	queue_redraw()

func calculate_ruby_positions(rubies: Array, target_text: String = ""):
	"""全ルビの描画位置を計算（タイプライター完了時用）"""
	print("🔍 [Ruby Debug] calculate_ruby_positions called with %d rubies" % rubies.size())
	
	# 受け取ったルビ配列の詳細を出力
	for i in range(rubies.size()):
		var ruby = rubies[i]
		print("🔍 [Received Ruby %d] kanji='%s', reading='%s', clean_pos=%s" % [i, ruby.get("kanji", "?"), ruby.get("reading", "?"), ruby.get("clean_pos", "?")])
	
	# 生ルビデータを保存（スキップ時の再計算用）
	raw_ruby_data = rubies.duplicate(true)
	
	ruby_data.clear()
	debug_baseline_data.clear()  # デバッグ情報もクリア
	
	if not ruby_main_font or rubies.is_empty():
		print("🔍 [Ruby Debug] Missing font or no rubies, exiting")
		return
	
	# フォントサイズを正確に取得
	var font_size = 16  # デフォルト値
	if has_theme_font_size_override("font_size"):
		font_size = get_theme_font_size("font_size")
		print("🔍 [Font Size] Using theme override: %d" % font_size)
	elif get_theme_font_size("font_size") > 0:
		font_size = get_theme_font_size("font_size")
		print("🔍 [Font Size] Using theme default: %d" % font_size)
	else:
		print("🔍 [Font Size] Using fallback default: %d" % font_size)
	
	for i in range(rubies.size()):
		var ruby = rubies[i]
		var kanji_text = ruby.kanji
		var reading_text = ruby.reading
		var kanji_pos_in_text = ruby.clean_pos
		
		print("🔍 [Processing Ruby %d] kanji='%s', reading='%s', clean_pos=%d (from ruby.clean_pos)" % [i, kanji_text, reading_text, kanji_pos_in_text])
		
		# BBCodeタグを除去したプレーンテキストを取得
		var displayed_text = target_text if not target_text.is_empty() else get_parsed_text()
		
		# BBCodeタグを除去してテキスト幅を正確に計算
		var regex = RegEx.new()
		regex.compile("\\[/?[^\\]]*\\]")  # BBCodeタグをマッチ
		var clean_displayed_text = regex.sub(displayed_text, "", true)
		
		# clean_posを完全に信頼する（重複文字問題の解決）
		var kanji_start_in_displayed = kanji_pos_in_text
		
		# デバッグ情報を詳しく出力
		print("🔍 [Ruby Position Fix] kanji='%s', clean_pos=%d, clean_text_length=%d" % [kanji_text, kanji_pos_in_text, clean_displayed_text.length()])
		if kanji_pos_in_text >= 0 and kanji_pos_in_text < clean_displayed_text.length():
			var text_at_pos = clean_displayed_text.substr(kanji_pos_in_text, min(kanji_text.length(), clean_displayed_text.length() - kanji_pos_in_text))
			print("🔍 [Ruby Position Fix] text_at_clean_pos='%s' (expected='%s') - MATCH: %s" % [text_at_pos, kanji_text, text_at_pos == kanji_text])
		
		# サニティチェック：位置が有効な範囲内か確認
		if kanji_start_in_displayed < 0 or kanji_start_in_displayed >= clean_displayed_text.length():
			print("� [Ruby Position Fix] clean_pos out of range, using position 0")
			kanji_start_in_displayed = 0
		else:
			# 位置の正確性を確認
			var expected_text = clean_displayed_text.substr(kanji_start_in_displayed, min(kanji_text.length(), clean_displayed_text.length() - kanji_start_in_displayed))
			if expected_text != kanji_text:
				print("🚨 [Ruby Position Fix] Position mismatch! Expected '%s' but found '%s' at position %d" % [kanji_text, expected_text, kanji_start_in_displayed])
			else:
				print("✅ [Ruby Position Fix] Position verified! Found '%s' at correct position %d" % [kanji_text, kanji_start_in_displayed])

		# 改行を考慮した位置計算（自動改行対応）
		var char_position = _get_character_position(clean_displayed_text, kanji_start_in_displayed, font_size)
		var text_width = char_position.x
		var line_number = char_position.line
		var y_offset = char_position.y
		var font_ascent = char_position.get("font_ascent", ruby_main_font.get_ascent(font_size))
		
		# 漢字とルビの幅を計算
		var kanji_width = ruby_main_font.get_string_size(kanji_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var ruby_font_size = max(8, font_size * 0.7)  # メインフォントサイズの70%
		var ruby_width = ruby_font.get_string_size(reading_text, HORIZONTAL_ALIGNMENT_LEFT, -1, ruby_font_size).x
		
		# ルビを漢字の中央揃えで配置（オフセットなしで正確な中央配置）
		var ruby_x = text_width + (kanji_width - ruby_width) / 2
		# ルビの縦位置：ベースラインからルビフォントサイズ分上に配置（マージンを8pxに増加）
		var ruby_y = y_offset - ruby_font_size - 14
		
		print("🔍 [Ruby Position Debug (Skip)] line_number=%d, y_offset=%f, font_ascent=%f, final_ruby_y=%f" % [line_number, y_offset, font_ascent, ruby_y])
		print("🔍 [Ruby Position Debug] DETAILED - y_offset=%f, font_ascent=%f, ruby_y_calculation=%f" % [y_offset, font_ascent, y_offset - font_ascent - 8])
		
		# デバッグ用にベースライン情報を記録
		if show_ruby_debug:
			var baseline_info = {
				"line": line_number,
				"y_offset": y_offset,
				"font_ascent": font_ascent,
				"baseline_y": y_offset,  # テキストのベースライン
				"ruby_y": ruby_y,
				"kanji_text": kanji_text
			}
			debug_baseline_data.append(baseline_info)
		
		print("🔍 [Ruby Debug] Calculated position: x=%f, y=%f (font_size=%d)" % [ruby_x, ruby_y, font_size])
		print("🔍 [Ruby Debug] displayed_text='%s'" % displayed_text)
		print("🔍 [Ruby Debug] clean_displayed_text='%s'" % clean_displayed_text)
		print("🔍 [Ruby Debug] kanji_start_in_displayed=%d (searched from %d)" % [kanji_start_in_displayed, max(0, kanji_pos_in_text - 10)])
		print("🔍 [Ruby Debug] text_width=%f, y_offset=%f" % [text_width, y_offset])
		print("🔍 [Ruby Debug] line_number=%d, y_offset=%f" % [line_number, y_offset])
		print("🔍 [Ruby Debug] kanji_width=%f, ruby_width=%f" % [kanji_width, ruby_width])
		print("🔍 [Ruby Debug] final ruby_x=%f (text_width + (kanji_width - ruby_width) / 2)" % ruby_x)
		
		ruby_data.append({
			"reading": reading_text,
			"kanji": kanji_text,
			"clean_pos": kanji_pos_in_text,  # clean_posを保存！
			"position": Vector2(ruby_x, ruby_y),
			"color": Color(0.9, 0.9, 0.9, 1.0)
		})
	
	# デバッグ情報を再描画
	if show_ruby_debug:
		queue_redraw()


	
	# display_ruby_data も更新（タイプライター完了時は全ルビを表示）
	display_ruby_data = ruby_data.duplicate(true)
	queue_redraw()
	
	print("🎨 Ruby positions calculated: %d rubies" % ruby_data.size())
