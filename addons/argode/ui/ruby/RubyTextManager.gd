class_name RubyTextManager
extends RefCounted

"""
Ruby文字（ふりがな）処理の専用マネージャークラス
ArgodeScreen.gdからRuby関連機能を分離し、単一責任原則に基づいて設計
"""

# 依存クラスのpreload
const RubyParser = preload("res://addons/argode/ui/ruby/RubyParser.gd")

# シグナル
signal ruby_text_updated(ruby_data: Array)
signal ruby_visibility_changed(visible_count: int)

# 依存性注入用プロパティ
var message_label: RichTextLabel
var canvas_layer: CanvasLayer
var debug_enabled: bool = false

# Ruby関連プロパティ
var current_ruby_data: Array = []
var display_ruby_data: Array = []
var use_draw_ruby: bool = true
var show_ruby_debug: bool = false

# フォント設定
var ruby_font: Font
var ruby_main_font: Font

# 子マネージャー（後のフェーズで実装）
var parser: RefCounted  # RubyParser
var renderer: RefCounted  # RubyRenderer
var position_calculator: RefCounted  # RubyPositionCalculator
var layout_adjuster: RefCounted  # RubyLayoutAdjuster

## 初期化 ##

func _init(label: RichTextLabel, layer: CanvasLayer = null):
	"""コンストラクタ - 依存性の注入"""
	message_label = label
	canvas_layer = layer
	_initialize()

func _initialize():
	"""内部初期化処理"""
	if message_label == null:
		push_error("RubyTextManager: message_label is required")
		return
	
	# フォント設定の初期化
	setup_fonts()
	
	# デバッグログ
	if debug_enabled:
		print("✅ RubyTextManager initialized successfully")

## メインAPI ##

func set_text_with_ruby(text: String) -> void:
	"""Ruby付きテキストの設定（メインエントリーポイント）"""
	if debug_enabled:
		print("🎯 [RubyManager] Setting text with ruby: '%s'" % text)
	
	# Ruby構文の解析
	var parsed_result = parse_ruby_syntax(text)
	var clean_text = parsed_result.get("text", "")
	var rubies = parsed_result.get("rubies", [])
	
	# Ruby データの保存
	current_ruby_data = rubies
	
	# Ruby位置の計算
	if not rubies.is_empty() and message_label:
		display_ruby_data = calculate_positions(rubies, clean_text)
		if debug_enabled:
			print("📍 [RubyManager] Calculated %d ruby positions" % display_ruby_data.size())
	else:
		display_ruby_data = []
	
	# シグナル発火
	ruby_text_updated.emit(current_ruby_data)

func parse_ruby_syntax(text: String) -> Dictionary:
	"""Ruby構文の解析 - 完全移植されたRubyParserクラスを使用"""
	if debug_enabled:
		print("🎯 [RubyManager] Parsing ruby syntax using fully migrated RubyParser")
	
	# ArgodeScreenから完全移植されたRubyParserクラスを使用
	var result = RubyParser.parse_ruby_syntax(text)
	
	if debug_enabled:
		print("📝 [RubyManager] Parse result: %s" % result)
		RubyParser.debug_parse_result(result)
	
	return result

func reverse_ruby_conversion(bbcode_text: String) -> String:
	"""BBCode→Ruby形式逆変換 - RubyParserを使用"""
	if debug_enabled:
		print("🎯 [RubyManager] Reversing ruby conversion using RubyParser")
	
	return RubyParser.reverse_ruby_conversion(bbcode_text)

func calculate_positions(rubies: Array, main_text: String) -> Array:
	"""Ruby位置の計算 - 現在は仮実装、後でRubyPositionCalculatorに移行"""
	# TODO: RubyPositionCalculatorクラスに移行予定
	return _temporary_calculate_positions(rubies, main_text)

func update_ruby_visibility(typed_position: int) -> void:
	"""タイプライター効果でのRuby可視性更新"""
	if current_ruby_data.is_empty():
		return
	
	var visible_count = 0
	for ruby_info in display_ruby_data:
		var clean_pos = ruby_info.get("clean_pos", 0)
		var kanji_length = ruby_info.get("kanji", "").length()
		
		# タイプ済み位置がRuby対象文字を含むかチェック
		if typed_position >= clean_pos + kanji_length:
			ruby_info["visible"] = true
			visible_count += 1
		else:
			ruby_info["visible"] = false
	
	ruby_visibility_changed.emit(visible_count)
	
	if debug_enabled:
		print("👁️ [RubyManager] Updated visibility: %d/%d rubies visible" % [visible_count, display_ruby_data.size()])

func adjust_line_breaks(text: String) -> String:
	"""行跨ぎ調整 - 現在は仮実装、後でRubyLayoutAdjusterに移行"""
	# TODO: RubyLayoutAdjusterクラスに移行予定
	return text  # 仮実装

## 設定API ##

func setup_fonts(main_font: Font = null, ruby_font_param: Font = null) -> void:
	"""Ruby描画用フォントの設定"""
	var default_font_path = "res://assets/common/fonts/03スマートフォントUI.otf"
	
	# メインフォント設定
	if main_font:
		ruby_main_font = main_font
	elif FileAccess.file_exists(default_font_path):
		ruby_main_font = load(default_font_path)
	else:
		ruby_main_font = ThemeDB.fallback_font
	
	# Rubyフォント設定
	if ruby_font_param:
		ruby_font = ruby_font_param
	else:
		ruby_font = ruby_main_font  # 同じフォントを使用
	
	if debug_enabled:
		print("🎨 [RubyManager] Fonts configured: main=%s, ruby=%s" % [ruby_main_font != null, ruby_font != null])

func set_debug_mode(enabled: bool) -> void:
	"""デバッグモードの設定"""
	debug_enabled = enabled
	show_ruby_debug = enabled
	print("🔧 [RubyManager] Debug mode: %s" % enabled)

func set_draw_mode(enabled: bool) -> void:
	"""Ruby描画モードの設定"""
	use_draw_ruby = enabled
	if debug_enabled:
		print("🖼️ [RubyManager] Draw mode: %s" % enabled)

## 情報取得API ##

func get_current_ruby_data() -> Array:
	"""現在のRubyデータを取得"""
	return current_ruby_data.duplicate()

func get_display_ruby_data() -> Array:
	"""表示用Rubyデータを取得"""
	return display_ruby_data.duplicate()

func get_ruby_count() -> int:
	"""Ruby文字の総数を取得"""
	return current_ruby_data.size()

func is_ruby_enabled() -> bool:
	"""Ruby機能が有効かどうか"""
	return use_draw_ruby

## 内部実装（一時的） ##

func _temporary_parse_ruby_syntax(text: String) -> Dictionary:
	"""一時的なRuby構文解析実装 - 後でRubyParserに移行"""
	# これは既存のArgodeScreen._parse_ruby_syntax()から移植予定
	# 現在は簡易実装
	return {"text": text, "rubies": []}

func _temporary_calculate_positions(rubies: Array, main_text: String) -> Array:
	"""一時的な位置計算実装 - 後でRubyPositionCalculatorに移行"""
	# これは既存のArgodeScreen._calculate_ruby_positions()から移植予定
	var result = []
	for ruby_info in rubies:
		var temp_info = ruby_info.duplicate()
		temp_info["position"] = Vector2.ZERO  # 仮の位置
		temp_info["visible"] = false
		result.append(temp_info)
	return result

## デバッグ用 ##

func debug_info() -> Dictionary:
	"""デバッグ情報の取得"""
	return {
		"ruby_count": get_ruby_count(),
		"display_count": display_ruby_data.size(),
		"debug_enabled": debug_enabled,
		"draw_enabled": use_draw_ruby,
		"message_label_valid": message_label != null,
		"canvas_layer_valid": canvas_layer != null,
		"fonts_loaded": ruby_font != null and ruby_main_font != null
	}

func print_debug_info() -> void:
	"""デバッグ情報の出力"""
	var info = debug_info()
	print("🔍 [RubyManager Debug] %s" % info)
