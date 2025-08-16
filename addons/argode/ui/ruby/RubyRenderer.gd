## RubyRenderer.gd
## Ruby文字の描画・レイアウト計算を担当するクラス
## ArgodeScreenから描画関連機能を分離

class_name RubyRenderer
extends RefCounted

# === プロパティ ===
var ruby_font: Font
var ruby_main_font: Font 
var show_ruby_debug: bool = false

# === 初期化 ===
func _init():
	print("🎨 RubyRenderer initialized")

# === フォント設定 ===
func setup_ruby_fonts():
	"""ルビ描画用フォントを設定"""
	var default_font_path = "res://assets/common/fonts/03スマートフォントUI.otf"
	
	# メインフォント設定
	if FileAccess.file_exists(default_font_path):
		ruby_main_font = load(default_font_path)
		ruby_font = ruby_main_font  # ルビも同じフォントを使用
		print("🎨 Ruby draw fonts loaded: ", default_font_path)
	else:
		ruby_main_font = ThemeDB.fallback_font
		ruby_font = ThemeDB.fallback_font
		print("⚠️ Using fallback font for ruby drawing")

# === 描画実行 ===
func execute_ruby_drawing(screen: ArgodeScreen, ruby_data: Array):
	"""ArgodeScreenのコンテキストでルビ描画を実行"""
	print("🔍 [RubyRenderer] Drawing %d rubies" % ruby_data.size())
	
	if ruby_data.is_empty() or not ruby_font:
		print("🔍 [RubyRenderer] No ruby data or font available")
		return
	
	# デバッグ表示: メッセージラベルの境界
	if show_ruby_debug and screen.message_label:
		var label_global_pos = screen.message_label.global_position
		var label_size = screen.message_label.size
		var screen_global_pos = screen.global_position
		var relative_pos = label_global_pos - screen_global_pos
		var rect = Rect2(relative_pos, label_size)
		screen.draw_rect(rect, Color.CYAN, false, 2.0)
		screen.draw_string(ThemeDB.fallback_font, relative_pos + Vector2(5, -10), "Message Label Area", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.CYAN)
	
	# 各ルビを描画
	for ruby_info in ruby_data:
		draw_single_ruby(screen, ruby_info)

# === 個別ルビ描画 ===
func draw_single_ruby(screen: ArgodeScreen, ruby_info: Dictionary):
	"""単一のルビを描画"""
	var reading = ruby_info.get("reading", "")
	var kanji = ruby_info.get("kanji", "")
	var position = ruby_info.get("position", Vector2.ZERO)
	# 色を明るくし、メインテキストに近い色に
	var color = ruby_info.get("color", Color(0.9, 0.9, 0.9, 1.0))
	
	# ルビの描画位置（position には既にメッセージラベルの位置が含まれている）
	var draw_pos = position
	
	# デバッグ表示
	if show_ruby_debug:
		# ルビの基点を緑の円で表示
		screen.draw_circle(draw_pos, 3.0, Color.GREEN)
		
		# ルビの範囲を青い矩形で表示
		var ruby_font_size = 14
		var ruby_width = ruby_font.get_string_size(reading, HORIZONTAL_ALIGNMENT_LEFT, -1, ruby_font_size).x
		var ruby_rect = Rect2(draw_pos, Vector2(ruby_width, ruby_font_size))
		screen.draw_rect(ruby_rect, Color.BLUE, false, 1.0)
		
		# デバッグ情報をテキストで表示
		var debug_text = "漢字: %s | ルビ: %s" % [kanji, reading]
		screen.draw_string(ThemeDB.fallback_font, draw_pos + Vector2(0, ruby_font_size + 15), debug_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.YELLOW)
	
	# ルビテキストを描画（サイズも少し大きく）
	var font_size = 14
	screen.draw_string(ruby_font, draw_pos, reading, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

# === テキスト調整 ===
func simple_ruby_line_break_adjustment(text: String, message_label: RichTextLabel) -> String:
	"""行をまたぐルビ対象文字の前にのみ改行を挿入"""
	print("🔧 [RubyRenderer Smart Fix] Checking for ruby targets that cross lines")
	
	if not message_label:
		print("❌ [RubyRenderer Smart Fix] No message_label available")
		return text
	
	var font = message_label.get_theme_default_font()
	if not font:
		print("❌ [RubyRenderer Smart Fix] No font available")
		return text
	
	# TODO: 完全な実装はArgodeScreenから移行予定
	print("🔧 [RubyRenderer] simple_ruby_line_break_adjustment - basic implementation")
	return text

# === デバッグ設定 ===
func set_debug_mode(enabled: bool):
	"""デバッグモードの設定"""
	show_ruby_debug = enabled
	print("🔧 RubyRenderer debug mode: %s" % show_ruby_debug)
