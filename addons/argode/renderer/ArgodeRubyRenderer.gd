extends RefCounted
class_name ArgodeRubyRenderer

## ルビ表示を専門に担当するレンダラー
## ArgodeMessageRendererからルビ機能を分離

# ルビデータ管理
var ruby_data: Array[Dictionary] = []

func _init():
	pass

## position_commandsからルビデータを抽出
func extract_ruby_data(position_commands: Array):
	ruby_data.clear()
	
	for command_info in position_commands:
		if command_info.get("command_name") == "ruby" and command_info.has("args"):
			var args = command_info["args"]
			if args.has("base_text") and args.has("ruby_text"):
				var ruby_info = {
					"position": command_info.get("display_position", 0),
					"base_text": args["base_text"],
					"ruby_text": args["ruby_text"],
					"is_visible": false  # 表示フラグ
				}
				ruby_data.append(ruby_info)
				ArgodeSystem.log("📖 Ruby data extracted: '%s' -> '%s' at position %d" % [ruby_info.base_text, ruby_info.ruby_text, ruby_info.position])

## タイプライター進行に応じてルビ表示を更新
func update_ruby_visibility(current_length: int, message_canvas = null):
	for ruby_info in ruby_data:
		var ruby_end_position = ruby_info.position + ruby_info.base_text.length()
		
		# ベーステキストが完全に表示されたらルビを表示
		if current_length >= ruby_end_position and not ruby_info.is_visible:
			ruby_info.is_visible = true
			ArgodeSystem.log("✨ Ruby now visible: '%s' -> '%s'" % [ruby_info.base_text, ruby_info.ruby_text])
			
			# Canvasの再描画をトリガー
			if message_canvas:
				message_canvas.queue_redraw()

## RubyCommandから直接ルビを追加
func add_ruby_display(base_text: String, ruby_text: String, current_text: String, current_display_length: int):
	# 現在のテキスト内でベーステキストの位置を検索
	var position = current_text.find(base_text)
	if position == -1:
		ArgodeSystem.log("⚠️ Ruby base text not found in current text: '%s'" % base_text, 1)
		return
	
	var ruby_info = {
		"position": position,
		"base_text": base_text,
		"ruby_text": ruby_text,
		"is_visible": false  # 表示フラグ
	}
	
	ruby_data.append(ruby_info)
	ArgodeSystem.log("📖 Ruby added directly: '%s' -> '%s' at position %d" % [base_text, ruby_text, position])
	
	# 現在の表示状況に応じてルビ表示を更新
	update_ruby_visibility(current_display_length)

## ルビを描画
func draw_ruby_text(canvas, text: String, draw_position: Vector2, font: Font, font_size: int, text_renderer: ArgodeTextRenderer, current_display_length: int):
	if ruby_data.is_empty():
		return
	
	# 小さめのフォントサイズでルビを描画
	var ruby_font_size = int(font_size * 0.6)  # 60%サイズ
	var ruby_color = Color(0.9, 0.9, 0.9, 1.0)  # 少し薄い色
	var line_spacing = 5.0
	
	# 各ルビについて個別に位置を計算
	for ruby_info in ruby_data:
		if not ruby_info.is_visible:
			continue
			
		# ルビ位置までのテキストを解析して正確な座標を計算
		var ruby_position = text_renderer.calculate_character_position(text, ruby_info.position, draw_position, font, font_size, current_display_length)
		
		ArgodeSystem.log("🔍 Ruby calculation: text='%s', position=%d, calculated_pos=(%.1f, %.1f)" % [ruby_info.ruby_text, ruby_info.position, ruby_position.x, ruby_position.y])
		
		# ベーステキストの幅とルビテキストの幅を計算
		var base_width = font.get_string_size(ruby_info.base_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var ruby_width = font.get_string_size(ruby_info.ruby_text, HORIZONTAL_ALIGNMENT_LEFT, -1, ruby_font_size).x
		
		# X座標: ベーステキストの中央 - ルビテキスト幅の半分 = 中央揃え
		var base_center_x = ruby_position.x + base_width / 2.0
		var ruby_x = base_center_x - ruby_width / 2.0
		
		# Y座標: ベーステキストの上部 - ルビフォントの高さ分上に移動
		var ruby_height = font.get_height(ruby_font_size)
		var ruby_y = ruby_position.y - ruby_height - 2.0  # 2pxの余白も追加
		
		canvas.draw_text_at(ruby_info.ruby_text, Vector2(ruby_x, ruby_y), font, ruby_font_size, ruby_color)
		ArgodeSystem.log("📝 Drew ruby: '%s' at (%.1f, %.1f) [base_center:%.1f, ruby_width:%.1f, position:%d]" % [ruby_info.ruby_text, ruby_x, ruby_y, base_center_x, ruby_width, ruby_info.position])

## ルビデータをクリア
func clear_ruby_data():
	ruby_data.clear()

## ルビデータを取得（デバッグ用）
func get_ruby_data() -> Array[Dictionary]:
	return ruby_data