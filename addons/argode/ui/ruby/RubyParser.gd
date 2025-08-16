class_name RubyParser
extends RefCounted

"""
Ruby文字（ふりがな）構文解析の専用クラス
【漢字｜ふりがな】形式の構文を解析し、クリーンテキストとルビデータを生成
"""

## 静的メソッド ##

static func parse_ruby_syntax(text: String) -> Dictionary:
	"""【漢字｜ふりがな】形式のテキストを解析
	ArgodeScreen._parse_ruby_syntax()から完全移植 - BBCode保持機能付き
	"""
	print("🚀🚀🚀 [NEW RUBY PARSER] parse_ruby_syntax CALLED WITH ARGODE CODE! 🚀🚀🚀")
	
	# BBCodeを保持しつつルビを処理する新しいアプローチ（ArgodeScreenから移植）
	print("🔍 [RubyParser] Original text: '%s'" % text)
	
	var clean_text = ""
	var rubies: Array[Dictionary] = []  # 型付き配列に修正
	var pos = 0
	
	print("🔍 [RubyParser Debug] Parsing text with BBCode preserved: '%s'" % text)
	
	var ruby_pattern = RegEx.new()
	ruby_pattern.compile("【([^｜]+)｜([^】]+)】")
	
	var offset = 0
	var matches = ruby_pattern.search_all(text)
	print("🔍 [RubyParser Debug] Found %d ruby matches" % matches.size())
	
	for result in matches:
		# マッチ前のテキスト
		var before_text = text.substr(offset, result.get_start() - offset)
		clean_text += before_text
		print("🔍 [RubyParser] Before text: '%s', clean_text_length_before: %d" % [before_text, clean_text.length()])
		
		# BBCodeを除去して実際の表示位置を計算
		var regex_bbcode = RegEx.new()
		regex_bbcode.compile("\\[/?[^\\]]*\\]")
		var clean_text_without_bbcode = regex_bbcode.sub(clean_text, "", true)
		var kanji_start_pos = clean_text_without_bbcode.length()
		
		# 漢字部分
		var kanji = result.get_string(1)
		var reading = result.get_string(2)
		clean_text += kanji
		
		print("🔍 [RubyParser] Added kanji: '%s', clean_pos=%d (BBCode-adjusted), clean_text_after='%s'" % [kanji, kanji_start_pos, clean_text])
		
		# ルビ情報を保存（BBCode除去後の位置で）
		rubies.append({
			"kanji": kanji,
			"reading": reading,
			"clean_pos": kanji_start_pos
		})
		
		offset = result.get_end()
	
	# 残りのテキスト
	clean_text += text.substr(offset)
	
	print("🔍 [RubyParser Debug] Result: clean_text='%s', rubies=%s" % [clean_text, rubies])
	return {"text": clean_text, "rubies": rubies}

static func reverse_ruby_conversion(bbcode_text: String) -> String:
	"""BBCode形式のルビを【｜】形式に逆変換
	ArgodeScreen._reverse_ruby_conversion()から完全移植
	"""
	var result_text = bbcode_text
	
	# パターン1: 漢字[font_size=10]（読み）[/font_size] -> 【漢字｜読み】 (URLタグ無し)
	var regex1 = RegEx.new()
	regex1.compile("([^\\[\\]]+)\\[font_size=10\\]（([^）]+)）\\[/font_size\\]")
	
	# パターン2: [url=xxx]漢字[font_size=10]（読み）[/font_size][/url] -> [url=xxx]【漢字｜読み】[/url]
	var regex2 = RegEx.new()
	regex2.compile("(\\[url=[^\\]]+\\])([^\\[\\]]+)\\[font_size=10\\]（([^）]+)）\\[/font_size\\](\\[/url\\])")
	
	# パターン2を先に処理（URLタグ付き）
	var matches2 = regex2.search_all(result_text)
	for i in range(matches2.size() - 1, -1, -1):
		var match = matches2[i]
		var url_start = match.get_string(1)  # [url=xxx]
		var kanji = match.get_string(2)      # 漢字
		var reading = match.get_string(3)    # 読み
		var url_end = match.get_string(4)    # [/url]
		var ruby_format = url_start + "【" + kanji + "｜" + reading + "】" + url_end
		
		result_text = result_text.substr(0, match.get_start()) + ruby_format + result_text.substr(match.get_end())
	
	# パターン1を処理（URLタグ無し）
	var matches1 = regex1.search_all(result_text)
	for i in range(matches1.size() - 1, -1, -1):
		var match = matches1[i]
		var kanji = match.get_string(1)
		var reading = match.get_string(2)
		var ruby_format = "【" + kanji + "｜" + reading + "】"
		
		result_text = result_text.substr(0, match.get_start()) + ruby_format + result_text.substr(match.get_end())
	
	print("� [RubyParser] Ruby reverse conversion: '%s' -> '%s'" % [bbcode_text, result_text])
	return result_text

static func extract_ruby_matches(text: String) -> Array:
	"""テキストからRuby構文の一致部分を抽出（解析のみ）"""
	var ruby_pattern = RegEx.new()
	ruby_pattern.compile("【([^｜]+)｜([^】]+)】")
	
	var matches = ruby_pattern.search_all(text)
	var result = []
	
	for match in matches:
		result.append({
			"full_match": match.get_string(),
			"kanji": match.get_string(1),
			"reading": match.get_string(2),
			"start": match.get_start(),
			"end": match.get_end()
		})
	
	print("🔍 [RubyParser] Extracted %d ruby matches" % result.size())
	return result

static func clean_bbcode_tags(text: String) -> String:
	"""BBCodeタグを除去してクリーンなテキストを返す"""
	var regex_bbcode = RegEx.new()
	regex_bbcode.compile("\\[/?[^\\]]*\\]")
	var clean_text = regex_bbcode.sub(text, "", true)
	
	print("🧹 [RubyParser] BBCode cleaned: '%s' -> '%s'" % [text, clean_text])
	return clean_text

static func validate_ruby_syntax(text: String) -> Dictionary:
	"""Ruby構文の妥当性をチェック"""
	var ruby_pattern = RegEx.new()
	ruby_pattern.compile("【([^｜]+)｜([^】]+)】")
	
	var matches = ruby_pattern.search_all(text)
	var errors = []
	var warnings = []
	
	for match in matches:
		var kanji = match.get_string(1)
		var reading = match.get_string(2)
		
		# 空文字チェック
		if kanji.is_empty():
			errors.append("Empty kanji in ruby syntax at position %d" % match.get_start())
		if reading.is_empty():
			errors.append("Empty reading in ruby syntax at position %d" % match.get_start())
		
		# 長さチェック（警告）
		if reading.length() > kanji.length() * 3:
			warnings.append("Reading '%s' is very long for kanji '%s'" % [reading, kanji])
	
	var is_valid = errors.is_empty()
	print("🔍 [RubyParser] Validation result: valid=%s, errors=%d, warnings=%d" % [is_valid, errors.size(), warnings.size()])
	
	return {
		"valid": is_valid,
		"errors": errors,
		"warnings": warnings,
		"match_count": matches.size()
	}

## デバッグ用 ##

static func debug_parse_result(result: Dictionary) -> void:
	"""パース結果のデバッグ出力"""
	print("📋 [RubyParser Debug] Parse Result:")
	print("  - Clean text: '%s'" % result.get("text", ""))
	print("  - Ruby count: %d" % result.get("rubies", []).size())
	
	var rubies = result.get("rubies", [])
	for i in range(rubies.size()):
		var ruby = rubies[i]
		print("  - Ruby[%d]: kanji='%s', reading='%s', clean_pos=%d" % [
			i, ruby.get("kanji", ""), ruby.get("reading", ""), ruby.get("clean_pos", -1)
		])

static func performance_test(text: String, iterations: int = 1000) -> Dictionary:
	"""パフォーマンステスト用"""
	var start_time = Time.get_ticks_msec()
	
	for i in range(iterations):
		parse_ruby_syntax(text)
	
	var end_time = Time.get_ticks_msec()
	var total_time = end_time - start_time
	var avg_time = float(total_time) / iterations
	
	print("⚡ [RubyParser] Performance test: %d iterations in %dms (avg: %.2fms)" % [iterations, total_time, avg_time])
	
	return {
		"iterations": iterations,
		"total_time_ms": total_time,
		"average_time_ms": avg_time,
		"text_length": text.length()
	}
