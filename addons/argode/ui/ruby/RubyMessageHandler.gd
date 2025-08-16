# RubyMessageHandler.gd
# ArgodeScreenから分離されたRuby処理専用クラス
# 責任: Ruby文法解析、行改行調整、Ruby表示処理の統合管理

extends RefCounted
class_name RubyMessageHandler

const RubyParser = preload("res://addons/argode/ui/ruby/RubyParser.gd")
const RubyRichTextLabel = preload("res://addons/argode/ui/RubyRichTextLabel.gd")

# === Ruby処理状態 ===
var current_rubies: Array = []
var adjusted_text: String = ""
var use_ruby_rich_text_label: bool = true

# === 参照保持 ===
var message_label: RichTextLabel = null

func _init(label: RichTextLabel = null):
	"""初期化時にメッセージラベルを設定"""
	message_label = label

func set_message_label(label: RichTextLabel):
	"""メッセージラベルを設定"""
	message_label = label

# === 行改行調整機能 ===

func simple_ruby_line_break_adjustment(text: String) -> String:
	"""行をまたぐルビ対象文字の前にのみ改行を挿入"""
	print("🔧 [Smart Fix] Checking for ruby targets that cross lines")
	
	if not message_label:
		print("❌ [Smart Fix] No message_label available")
		return text
	
	var font = message_label.get_theme_default_font()
	if not font:
		print("❌ [Smart Fix] No font available")
		return text
	
	var font_size = message_label.get_theme_font_size("normal_font_size")
	var container_width = message_label.get_rect().size.x
	
	if container_width <= 0:
		print("❌ [Smart Fix] Invalid container width: %f" % container_width)
		return text
	
	print("🔧 [Smart Fix] Container width: %f, font size: %d" % [container_width, font_size])
	
	# 【漢字｜ひらがな】パターンを検索
	var regex = RegEx.new()
	regex.compile("【([^｜]+)｜[^】]+】")
	
	var result = text
	var matches = regex.search_all(result)
	
	for match in matches:
		var full_match = match.get_string()
		var kanji_part = match.get_string(1)  # 【】内の漢字部分
		var match_start = result.find(full_match)
		
		if match_start >= 0:
			# このルビ対象文字が行をまたぐかどうかをチェック
			if _will_ruby_cross_line(result, match_start, kanji_part, font, font_size, container_width):
				print("🔧 [Cross Line] Ruby target '%s' will cross line - adding break" % kanji_part)
				
				# ルビ対象文字の前に改行を挿入
				var before_ruby = result.substr(0, match_start)
				var from_ruby = result.substr(match_start)
				result = before_ruby.strip_edges() + "\n" + from_ruby
			else:
				print("🔧 [Same Line] Ruby target '%s' stays on same line - no break needed" % kanji_part)
	
	print("🔧 [Smart Fix] Result: '%s'" % result.replace("\n", "\\n"))
	return result

func _will_ruby_cross_line(text: String, ruby_start_pos: int, kanji_part: String, font: Font, font_size: int, container_width: float) -> bool:
	"""ルビ対象文字が行をまたぐかどうかを判定"""
	
	# ruby_start_pos以前の文字で、最後の改行位置を見つける
	var line_start_pos = 0
	var last_newline = text.rfind("\n", ruby_start_pos - 1)
	if last_newline >= 0:
		line_start_pos = last_newline + 1
	
	# 現在行の開始からルビ対象文字までのテキスト
	var line_before_ruby = text.substr(line_start_pos, ruby_start_pos - line_start_pos)
	
	# 現在行の幅を計算
	var current_line_width = font.get_string_size(line_before_ruby, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	
	# ルビ対象文字の幅を計算
	var kanji_width = font.get_string_size(kanji_part, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	
	# ルビ対象文字を追加すると行幅を超えるかどうか
	var will_cross = (current_line_width + kanji_width) > container_width
	
	print("📏 [Line Check] Line before ruby: '%s' (width: %f)" % [line_before_ruby.replace("\n", "\\n"), current_line_width])
	print("📏 [Line Check] Kanji '%s' width: %f, total would be: %f, container: %f" % [kanji_part, kanji_width, current_line_width + kanji_width, container_width])
	print("📏 [Line Check] Will cross line: %s" % will_cross)
	
	return will_cross

# === Ruby表示処理 ===

func set_text_with_ruby_draw(text: String):
	"""ルビ付きテキストを設定（RubyRichTextLabel優先）"""
	print("🔍 [Ruby Debug] set_text_with_ruby_draw called with: '%s'" % text)
	print("🔍 [Ruby Debug] use_ruby_rich_text_label = %s" % use_ruby_rich_text_label)
	print("🔍 [Ruby Debug] message_label is RubyRichTextLabel = %s" % (message_label is RubyRichTextLabel))
	
	# RubyRichTextLabelが利用可能な場合は優先使用
	if use_ruby_rich_text_label and message_label is RubyRichTextLabel:
		print("🎨 [RubyRichTextLabel] Using RubyRichTextLabel system")
		
		# ルビを解析
		var parse_result = _parse_ruby_syntax(text)
		var clean_text = parse_result.text
		var rubies = parse_result.rubies
		
		print("🎨 [RubyRichTextLabel] Clean text: '%s'" % clean_text)
		print("🎨 [RubyRichTextLabel] Found %d rubies" % rubies.size())
		
		# メインテキストを設定
		message_label.text = clean_text
		
		# ルビデータを計算して設定
		var ruby_label = message_label as RubyRichTextLabel
		if ruby_label and ruby_label.has_method("calculate_ruby_positions"):
			ruby_label.calculate_ruby_positions(rubies)
		
		# 状態を保存
		current_rubies = rubies
		adjusted_text = clean_text  # ← クリーンなテキストを保存
	else:
		# フォールバック処理
		print("⚠️ [Ruby Fallback] Using standard text display")
		if message_label:
			message_label.text = text
		adjusted_text = text

func _parse_ruby_syntax(text: String) -> Dictionary:
	"""【漢字｜ふりがな】形式のテキストを解析"""
	print("🚀🚀🚀 [NEW PARSE] _parse_ruby_syntax CALLED WITH FIXED CODE! 🚀🚀🚀")
	
	# BBCodeを保持しつつルビを処理する新しいアプローチ
	print("🔍 [Ruby Parse] Original text: '%s'" % text)
	
	var clean_text = ""
	var rubies = []
	var pos = 0
	
	print("🔍 [Ruby Debug] Parsing text with BBCode preserved: '%s'" % text)
	
	var ruby_pattern = RegEx.new()
	ruby_pattern.compile("【([^｜]+)｜([^】]+)】")
	
	var offset = 0
	var matches = ruby_pattern.search_all(text)
	print("🔍 [Ruby Debug] Found %d ruby matches" % matches.size())
	
	for result in matches:
		# マッチ前のテキスト
		var before_text = text.substr(offset, result.get_start() - offset)
		clean_text += before_text
		print("🔍 [Ruby Parse] Before text: '%s', clean_text_length_before: %d" % [before_text, clean_text.length()])
		
		# BBCodeを除去して実際の表示位置を計算
		var regex_bbcode = RegEx.new()
		regex_bbcode.compile("\\[/?[^\\]]*\\]")
		var clean_text_without_bbcode = regex_bbcode.sub(clean_text, "", true)
		var kanji_start_pos = clean_text_without_bbcode.length()
		
		# 漢字部分
		var kanji = result.get_string(1)
		var reading = result.get_string(2)
		clean_text += kanji
		
		print("🔍 [Ruby Parse] Added kanji: '%s', clean_pos=%d (BBCode-adjusted), clean_text_after='%s'" % [kanji, kanji_start_pos, clean_text])
		
		# ルビ情報を保存（BBCode除去後の位置で）
		rubies.append({
			"kanji": kanji,
			"reading": reading,
			"clean_pos": kanji_start_pos
		})
		
		offset = result.get_end()
	
	# 残りのテキスト
	clean_text += text.substr(offset)
	
	print("🔍 [Ruby Debug] Result: clean_text='%s', rubies=%s" % [clean_text, rubies])
	return {"text": clean_text, "rubies": rubies}

# === データアクセス ===

func get_current_ruby_data() -> Array:
	"""現在のルビデータを取得（TypewriterTextからアクセス用）"""
	if message_label and message_label.has_method("get_ruby_data"):
		return message_label.get_ruby_data()
	return current_rubies if current_rubies else []

func get_adjusted_text() -> String:
	"""改行調整されたテキストを取得（TypewriterTextからアクセス用）"""
	print("🚀 [CRITICAL] get_adjusted_text() called - adjusted_text: '%s'" % adjusted_text.replace("\n", "\\n"))
	if adjusted_text.is_empty():
		print("🚀 [CRITICAL] adjusted_text is empty, returning message_label.text")
		print("⚠️ [Ruby Text Access] adjusted_text is empty, returning message_label.text")
		return message_label.text if message_label else ""
	print("🚀 [CRITICAL] Returning adjusted text length: %d" % adjusted_text.length())
	print("🔍 [Ruby Text Access] Returning adjusted text: '%s'" % adjusted_text.replace("\n", "\\n"))
	return adjusted_text

func process_ruby_message(text: String) -> String:
	"""Ruby処理のメインエントリーポイント - 行改行調整を適用してからRuby表示"""
	# 1. 行改行調整
	var adjusted = simple_ruby_line_break_adjustment(text)
	
	# 2. Ruby表示処理
	set_text_with_ruby_draw(adjusted)
	
	# 3. 調整されたテキスト（ルビ記号除去済み）を返す
	return adjusted_text
