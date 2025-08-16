# RubyTextRenderer.gd
# 参考: https://github.com/clvs7-gh/godot-sample-project-furigana-ruby
# 複数Labelを使った完全なルビレイアウトシステム
@tool
extends Control
class_name RubyTextRenderer

# 設定パラメータ
@export var main_font: FontFile = null  # メインテキストのフォント
@export var ruby_font: FontFile = null  # フリガナのフォント
@export var ruby_color: Color = Color(0.4, 0.4, 0.4)  # フリガナの色
@export var vertical_spacing: float = 24  # 行間
@export var ruby_spacing_extra: float = 3  # フリガナの追加スペース

# デフォルトフォントの設定（プロジェクトのフォントを使用）
# TODO: Argodeプロジェクトとして汎用のフォントファイル（再配布可能な多言語対応のもの）に置き換える
# TODO: ゲームプロジェクト側で設定できるようにする。
var default_main_font_path: String = "res://assets/common/fonts/03スマートフォントUI.otf"
var default_ruby_font_path: String = "res://assets/common/fonts/03スマートフォントUI.otf"

# ルビデータ配列
var rubies: Array = []
var main_label: RichTextLabel = null
var ruby_labels: Array = []

# シグナル
signal text_updated()

func _ready():
	# デフォルトフォントを設定
	_setup_default_fonts()
	
	# メインラベルを作成
	if not main_label:
		main_label = RichTextLabel.new()
		main_label.bbcode_enabled = true
		main_label.fit_content = true
		main_label.scroll_active = false
		# 最小サイズを設定
		main_label.custom_minimum_size = Vector2(200, 50)
		add_child(main_label)
		
		# アンカーとマージンを設定
		main_label.anchor_left = 0
		main_label.anchor_top = 0
		main_label.anchor_right = 1
		main_label.anchor_bottom = 1
		main_label.offset_left = 0
		main_label.offset_top = 0
		main_label.offset_right = 0
		main_label.offset_bottom = 0
	
	# フォントを適用
	_apply_fonts()

func _setup_default_fonts():
	"""デフォルトフォントの設定"""
	if not main_font and ResourceLoader.exists(default_main_font_path):
		main_font = load(default_main_font_path)
		print("🔤 RubyTextRenderer: Default main font loaded: ", default_main_font_path)
	
	if not ruby_font and ResourceLoader.exists(default_ruby_font_path):
		ruby_font = load(default_ruby_font_path) 
		print("🔤 RubyTextRenderer: Default ruby font loaded: ", default_ruby_font_path)

func _apply_fonts():
	"""メインラベルにフォントを適用"""
	if main_label and main_font:
		main_label.theme = null
		main_label.add_theme_font_override("normal_font", main_font)
		print("✅ RubyTextRenderer: Main font applied")

func set_text_with_ruby(text: String):
	"""ルビ付きテキストを設定"""
	print("📝 RubyTextRenderer: Setting text: %s" % text)
	clear_ruby_labels()
	var parsed_text = _parse_ruby_text(text)
	print("📝 RubyTextRenderer: Parsed text: %s" % parsed_text)
	main_label.text = parsed_text
	
	# レイアウト更新を強制
	await get_tree().process_frame
	main_label.queue_redraw()
	
	print("📝 RubyTextRenderer: Main label text set to: %s" % main_label.text)
	print("📝 RubyTextRenderer: Main label visible: %s, size: %s" % [main_label.visible, main_label.size])
	
	_apply_ruby_layout()

func _parse_ruby_text(input_text: String) -> String:
	"""ルビ指定を含むテキストのパース"""
	rubies.clear()
	var result_text = input_text
	
	# パターン1: 【漢字｜読み】
	var regex1 = RegEx.new()
	regex1.compile("【([^｜]+)｜([^】]+)】")
	
	# パターン2: %ruby{漢字,読み}（参考プロジェクト形式）
	var regex2 = RegEx.new()
	regex2.compile("%ruby\\{([^,]+),([^}]+)\\}")
	
	var all_matches = []
	
	# 両方のパターンのマッチを収集
	var matches1 = regex1.search_all(result_text)
	for match in matches1:
		all_matches.append({"match": match, "type": 1})
	
	var matches2 = regex2.search_all(result_text)
	for match in matches2:
		all_matches.append({"match": match, "type": 2})
	
	# 後ろから処理するため降順でソート
	all_matches.sort_custom(func(a, b): return a.match.get_start() > b.match.get_start())
	
	# ルビ情報を抽出してテキストをクリーンアップ
	for match_info in all_matches:
		var match = match_info.match
		var kanji = match.get_string(1).strip_edges()
		var reading = match.get_string(2).strip_edges()
		
		var tag_start = match.get_start()
		var tag_end = match.get_end()
		
		# クリーンアップされた位置を計算（後ろから処理）
		var clean_start = tag_start
		for ruby in rubies:
			if ruby.original_pos > tag_start:
				clean_start -= (ruby.original_length - ruby.clean_length)
		
		# ルビ情報を保存
		rubies.append({
			"kanji": kanji,
			"reading": reading,
			"clean_pos": clean_start,
			"clean_length": kanji.length(),
			"original_pos": tag_start,
			"original_length": tag_end - tag_start
		})
		
		# テキストから ルビ記法を削除してクリーンテキストに置換
		result_text = result_text.left(tag_start) + kanji + result_text.right(result_text.length() - tag_end)
		
		print("🏷️ Ruby parsed: %s -> %s" % [match.get_string(0), kanji])
	
	# ルビ情報を位置でソート（前から処理するため）
	rubies.sort_custom(func(a, b): return a.clean_pos < b.clean_pos)
	
	return result_text

func _apply_ruby_layout():
	"""ルビのレイアウトを適用"""
	if not main_label or rubies.is_empty():
		print("⚠️ RubyTextRenderer: No main_label or rubies empty")
		return
	
	await get_tree().process_frame  # レイアウトが確定するまで待つ
	
	var main_font_res = main_label.get("custom_fonts/font") if main_label.get("custom_fonts/font") else main_font
	if not main_font_res:
		push_warning("⚠️ RubyTextRenderer: No main font available")
		return
	
	print("📝 RubyTextRenderer: Applying layout for %d rubies" % rubies.size())
	
	# 各ルビに対してLabelを作成・配置
	for ruby in rubies:
		var ruby_label = _create_ruby_label(ruby)
		if ruby_label:
			ruby_labels.append(ruby_label)
			add_child(ruby_label)
			print("🏷️ Ruby label added as child: %s" % ruby.reading)
			print("🏷️ Ruby label parent: %s" % ruby_label.get_parent().name)
			print("🏷️ Ruby label tree position: %s" % ruby_label.get_path())
			_position_ruby_label(ruby_label, ruby, main_font_res)
			
			# 可視性とサイズの確認
			print("🔍 Ruby label details:")
			print("   - Text: '%s'" % ruby_label.text)
			print("   - Visible: %s" % ruby_label.visible)
			print("   - Position: %s" % ruby_label.position)
			print("   - Size: %s" % ruby_label.size)
			print("   - Modulate: %s" % ruby_label.modulate)
			print("   - Global position: %s" % ruby_label.global_position)
	
	print("✅ RubyTextRenderer: Layout applied, %d ruby labels created" % ruby_labels.size())
	text_updated.emit()

func _create_ruby_label(ruby: Dictionary) -> Label:
	"""ルビ用Labelを作成"""
	var label = Label.new()
	label.text = ruby.reading
	label.modulate = ruby_color
	
	print("🔧 Creating ruby label: '%s'" % ruby.reading)
	print("   - Modulate color: %s" % ruby_color)
	
	# フォント設定（Godot 4対応）
	if ruby_font:
		label.add_theme_font_override("font", ruby_font)
		label.add_theme_font_size_override("font_size", max(8, int(16 * 0.6)))
		print("✅ Ruby label font set: ", ruby_font.resource_path)
	elif main_font:
		# メインフォントをルビ用として使用
		label.add_theme_font_override("font", main_font)
		label.add_theme_font_size_override("font_size", max(8, int(16 * 0.6)))
		print("✅ Ruby label using main font: ", main_font.resource_path)
	
	# サイズを最小に設定
	label.size = Vector2.ZERO
	label.custom_minimum_size = Vector2.ZERO
	
	# 確実に可視にする
	label.visible = true
	label.show()
	
	print("🔧 Ruby label created - visible: %s, text: '%s'" % [label.visible, label.text])
	
	return label

func _position_ruby_label(ruby_label: Label, ruby: Dictionary, main_font_res: Font):
	"""ルビLabelの位置を計算・設定"""
	# メインテキストでの文字位置を計算
	var main_text = main_label.text
	var text_before_kanji = main_text.substr(0, ruby.clean_pos)
	var kanji_text = ruby.kanji
	
	# フォントサイズ情報取得（Godot 4対応）
	var font_size = 16  # デフォルトサイズ
	if main_label.has_theme_font_size_override("normal_font_size"):
		font_size = main_label.get_theme_font_size("normal_font_size")
	
	var kanji_size = main_font_res.get_string_size(kanji_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var ruby_font_size = 10  # デフォルトフリガナサイズ
	if ruby_label.has_theme_font_size_override("font_size"):
		ruby_font_size = ruby_label.get_theme_font_size("font_size")
	
	var ruby_size = Vector2(50, 12)  # デフォルト
	var ruby_font_res = ruby_font if ruby_font else main_font
	if ruby_font_res:
		ruby_size = ruby_font_res.get_string_size(ruby.reading, HORIZONTAL_ALIGNMENT_LEFT, -1, ruby_font_size)
	
	# 改行を考慮した位置計算
	var lines = text_before_kanji.split("\n")
	var line_index = lines.size() - 1
	var char_pos_in_line = lines[-1].length() if lines.size() > 0 else 0
	
	# X位置計算（文字位置 + 中央揃え調整）
	var line_text = lines[-1] if lines.size() > 0 else ""
	var before_kanji_in_line_size = main_font_res.get_string_size(line_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var x_pos = before_kanji_in_line_size.x + (kanji_size.x - ruby_size.x) / 2
	
	# Y位置計算を修正 - ルビを確実に見える位置に配置
	var line_height = main_font_res.get_height(font_size)
	var y_pos = line_index * (line_height + vertical_spacing) - ruby_size.y - ruby_spacing_extra
	
	# ルビを常に見える位置に配置（メインテキストの上ではなく、同じ行の上に）
	y_pos = -ruby_size.y - 3  # メインテキストから3px上に配置
	
	# デバッグ用：試しに正の値でも配置してみる
	if true:  # テスト用に正の値を試す
		y_pos = 3  # メインテキストから3px下に配置（テスト用）
		print("🧪 Testing ruby below main text at y_pos: %.1f" % y_pos)
	
	print("🔧 Final ruby Y position: %.1f (ruby_size: %s, line_height: %.1f)" % [y_pos, ruby_size, line_height])
	
	# フリガナが長すぎる場合は文字間隔を調整（Godot 4では制限的）
	if ruby_size.x > kanji_size.x:
		# Godot 4では文字間隔調整が限定的なため、警告のみ
		print("⚠️ Ruby text '%s' is wider than kanji '%s'" % [ruby.reading, ruby.kanji])
	
	ruby_label.position = Vector2(x_pos, y_pos)
	
	print("📍 Ruby positioned: %s at (%.1f, %.1f)" % [ruby.reading, x_pos, y_pos])

func clear_ruby_labels():
	"""ルビLabelをクリア"""
	for label in ruby_labels:
		if is_instance_valid(label):
			label.queue_free()
	ruby_labels.clear()

func _exit_tree():
	clear_ruby_labels()

# 参考プロジェクトから学んだ位置計算メソッド（Godot 4版）
func _calculate_text_metrics(font: Font, text: String, font_size: int) -> Dictionary:
	"""テキストの詳細なメトリクスを計算"""
	return {
		"size": font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size),
		"height": font.get_height(font_size),
		"ascent": font.get_ascent(font_size),
		"descent": font.get_descent(font_size)
	}
