extends RefCounted
class_name ArgodeMessageRenderer

# メッセージウィンドウの参照
var message_window: ArgodeMessageWindow = null
var message_canvas = null  # ArgodeMessageCanvas型だが型注釈を削除

# タイプライターサービス
var typewriter_service = null

# タイプライター完了時のコールバック
var on_typewriter_completed: Callable

# ルビ表示管理
var ruby_data: Array[Dictionary] = []  # ルビ情報を保存
var current_text: String = ""  # 現在のテキスト
var current_display_length: int = 0  # 現在の表示文字数

# テキスト装飾管理
var text_decorations: Array[Dictionary] = []  # 装飾情報を保存
var decoration_stack: Array[Dictionary] = []  # 装飾スタック（開始/終了ペア管理）

# 文字アニメーション管理
var character_animation = null  # ArgodeCharacterAnimationインスタンス
var is_animation_enabled: bool = true  # アニメーション有効フラグ

func _init(window: ArgodeMessageWindow = null):
	if window:
		set_message_window(window)

## メッセージウィンドウを設定
func set_message_window(window: ArgodeMessageWindow):
	message_window = window
	_find_message_canvas()

## MessageCanvasノードを探す
func _find_message_canvas():
	if not message_window:
		return
	
	# %MessageCanvasでユニーク取得を試行
	message_canvas = message_window.get_node_or_null("%MessageCanvas")
	
	if not message_canvas:
		# クラス名で走査
		message_canvas = _find_node_by_class(message_window, "ArgodeMessageCanvas")
	
	if message_canvas:
		# 描画コールバックを設定
		message_canvas.set_draw_callback(_draw_message_content)
		
		# タイプライターサービスを初期化
		_initialize_typewriter_service()
		
		# 文字アニメーションシステムを初期化
		_initialize_character_animation()
	else:
		ArgodeSystem.log("❌ MessageCanvas not found in message window", 2)

## クラス型でノードを検索
func _find_node_by_class(node: Node, target_class_name: String) -> Node:
	# 現在のノードをチェック
	if node.get_script() and node.get_script().get_global_name() == target_class_name:
		return node
	
	# 子ノードを再帰的に検索
	for child in node.get_children():
		var result = _find_node_by_class(child, target_class_name)
		if result:
			return result
	
	return null

## タイプライターサービスを初期化
func _initialize_typewriter_service():
	# 動的にクラスを作成
	var TypewriterServiceClass = load("res://addons/argode/services/ArgodeTypewriterService.gd")
	typewriter_service = TypewriterServiceClass.new()
	
	# コールバックを設定
	typewriter_service.set_callbacks(_on_character_typed, _on_typing_finished)
	
	ArgodeSystem.log("✅ MessageRenderer: Typewriter service initialized")

## 文字アニメーションシステムを初期化
func _initialize_character_animation():
	# 動的にクラスを作成
	var CharacterAnimationClass = load("res://addons/argode/renderer/ArgodeCharacterAnimation.gd")
	character_animation = CharacterAnimationClass.new()
	
	# シグナル接続
	character_animation.all_animations_completed.connect(_on_all_animations_completed)
	
	ArgodeSystem.log("✅ MessageRenderer: Character animation system initialized")

## タイプライター効果での文字タイプ時のコールバック
func _on_character_typed(character: String, current_display: String):
	# 現在の表示文字数を更新
	current_display_length = current_display.length()
	
	# メッセージキャンバスに現在の表示テキストを設定
	if message_canvas:
		message_canvas.set_message_text(current_display)
	
	# ルビ表示を更新
	_update_ruby_visibility(current_display_length)
	
	# 文字アニメーションのタイムラインを更新
	if character_animation and is_animation_enabled:
		# 新しい文字が表示される際にアニメーション効果をトリガー
		var char_index = current_display_length - 1
		if char_index >= 0:
			character_animation.trigger_character_animation(char_index)

## タイプライター効果完了時のコールバック
func _on_typing_finished(final_text: String):
	ArgodeSystem.log("✅ Typewriter effect completed: %s" % final_text.substr(0, 30) + ("..." if final_text.length() > 30 else ""))
	
	# アニメーションが有効な場合の処理
	if character_animation and is_animation_enabled:
		# スキップされた場合のみアニメーションも強制完了
		if typewriter_service and typewriter_service.was_typewriter_skipped():
			ArgodeSystem.log("⏭️ Typewriter was skipped - forcing animation completion")
			character_animation.skip_all_animations()
			_notify_message_completion()
		else:
			# 自然完了の場合はアニメーション完了を待つ
			ArgodeSystem.log("⏳ Typewriter completed naturally - waiting for animations...")
			_wait_for_animations_completion()
	else:
		# アニメーションが無効な場合は即座に完了通知
		ArgodeSystem.log("🔄 No animations enabled, completing immediately")
		_notify_message_completion()

## 全アニメーション完了シグナル受信
func _on_all_animations_completed():
	ArgodeSystem.log("✅ All character animations completed via signal")
	_notify_message_completion()

## アニメーションの完了を待つ
func _wait_for_animations_completion():
	# シグナルベースで処理するため、何もしない
	# 完了時に_on_all_animations_completed()が自動的に呼ばれる
	ArgodeSystem.log("🔄 Waiting for animations completion via signal...")

## アニメーション完了チェックを開始
func _start_animation_completion_check():
	# MessageCanvasが有効な場合はそこにTimerを追加
	if message_canvas:
		var timer = Timer.new()
		timer.wait_time = 0.05  # 50msごとにチェック
		timer.timeout.connect(_check_animation_completion)
		timer.timeout.connect(timer.queue_free)  # 自動削除
		timer.one_shot = false  # 繰り返し実行
		message_canvas.add_child(timer)
		timer.start()
	else:
		# MessageCanvasがない場合は直接完了通知
		ArgodeSystem.log("⚠️ MessageCanvas not available, completing immediately")
		_notify_message_completion()

## アニメーション完了をチェック
func _check_animation_completion():
	if character_animation and character_animation.are_all_animations_completed():
		ArgodeSystem.log("✅ All character animations completed")
		_notify_message_completion()
		# タイマーを停止して削除
		var timer = message_canvas.get_children().filter(func(child): return child is Timer).back()
		if timer:
			timer.stop()
			timer.queue_free()
	# まだ完了していない場合はタイマーが継続して動作

## メッセージ表示完了を通知
func _notify_message_completion():
	# アニメーション更新を停止
	if message_canvas:
		message_canvas.stop_animation_updates()
	
	# StatementManagerに完了を通知
	if on_typewriter_completed.is_valid():
		ArgodeSystem.log("📢 Notifying typewriter completion to StatementManager")
		on_typewriter_completed.call()
	else:
		ArgodeSystem.log("⚠️ Typewriter completion callback not set")

## メッセージをレンダリング
func render_message(character_name: String, text: String):
	if not message_canvas:
		ArgodeSystem.log("❌ MessageCanvas not available for rendering", 2)
		return
	
	# メッセージウィンドウを表示
	if message_window:
		message_window.visible = true
		
		# キャラクター名はMessageWindowのname_plateに表示
		if character_name and not character_name.is_empty():
			message_window.set_character_name(character_name)
		else:
			message_window.hide_character_name()
	
	# タイプライター効果を開始
	if typewriter_service:
		typewriter_service.start_typing(text, 0.05)  # 50ms間隔
		ArgodeSystem.log("🎨 Message rendering started with typewriter: [%s] %s" % [character_name, text.substr(0, 20) + ("..." if text.length() > 20 else "")])
	else:
		# フォールバック：即座に表示
		message_canvas.set_message_text(text)
		ArgodeSystem.log("🎨 Message rendered instantly: [%s] %s" % [character_name, text])

## 位置ベースコマンド付きメッセージをレンダリング
func render_message_with_position_commands(character_name: String, display_text: String, position_commands: Array, inline_command_manager: ArgodeInlineCommandManager):
	if not message_canvas:
		ArgodeSystem.log("❌ MessageCanvas not available for rendering", 2)
		return
	
	# ルビデータと装飾データを初期化・抽出
	_extract_ruby_data(position_commands)
	_extract_decoration_data(position_commands)
	current_text = display_text
	current_display_length = 0
	
	# 文字アニメーションシステムの初期化
	if character_animation and is_animation_enabled:
		character_animation.initialize_for_text(display_text.length())
		ArgodeSystem.log("✨ Character animation initialized for text length: %d" % display_text.length())
		
		# MessageCanvasでアニメーション更新を開始
		if message_canvas:
			message_canvas.start_animation_updates(_update_character_animations)
	
	# メッセージウィンドウを表示
	if message_window:
		message_window.visible = true
		
		# キャラクター名はMessageWindowのname_plateに表示
		if character_name and not character_name.is_empty():
			message_window.set_character_name(character_name)
		else:
			message_window.hide_character_name()
	
	# 位置ベースタイプライター効果を開始
	if typewriter_service:
		typewriter_service.start_typing_with_position_commands(display_text, position_commands, inline_command_manager, 0.05)
		ArgodeSystem.log("🎨 Message rendering started with position commands: [%s] %s" % [character_name, display_text.substr(0, 20) + ("..." if display_text.length() > 20 else "")])
	else:
		# フォールバック：即座に表示
		message_canvas.set_message_text(display_text)
		ArgodeSystem.log("🎨 Message rendered instantly with position commands: [%s] %s" % [character_name, display_text])

## メッセージウィンドウを非表示
func hide_message():
	if message_window:
		message_window.visible = false
		ArgodeSystem.log("👻 Message window hidden")

## メッセージをクリア
func clear_message():
	if message_canvas:
		message_canvas.set_message_text("")
	
	ArgodeSystem.log("🧹 Message cleared")

## タイプライター効果を即座に完了
func complete_typewriter():
	if typewriter_service and typewriter_service.is_currently_typing():
		ArgodeSystem.log("⏭️ Typewriter effect being completed by user (SKIP)")
		typewriter_service.complete_typing()
		
		# アニメーションもスキップ（ユーザーが明示的にスキップした場合のみ）
		if character_animation and is_animation_enabled:
			character_animation.skip_all_animations()
			ArgodeSystem.log("⏭️ Character animations skipped due to user skip")
			
			# アニメーション完了を即座に通知
			_notify_message_completion()
	else:
		ArgodeSystem.log("⚠️ Typewriter already completed or not running")

## タイプライター効果を停止
func stop_typewriter():
	if typewriter_service:
		typewriter_service.stop_typing()
		ArgodeSystem.log("⏹️ Typewriter effect stopped")

## タイプライター完了コールバックを設定
func set_typewriter_completion_callback(callback: Callable):
	on_typewriter_completed = callback

## スキップ状態付きでタイプライター完了コールバックを設定
func set_typewriter_completion_callback_with_skip_flag(callback: Callable):
	on_typewriter_completed = callback

## 実際の描画処理（CanvasからCallableで呼ばれる）
func _draw_message_content(canvas, character_name: String, text: String):
	# 基本的な描画設定
	var canvas_size = canvas.get_canvas_size()
	var margin = Vector2(20, 20)
	var line_spacing = 5.0
	
	# MessageCanvasのフォントシステムを使用
	var message_font = canvas.get_argode_font()
	var font_size = canvas.font_size
	
	# 色設定
	var text_color = Color.WHITE
	
	var draw_position = margin
	
	# メッセージテキストのみを描画（キャラクター名はMessageWindowが担当）
	if text and not text.is_empty():
		var available_width = canvas_size.x - (margin.x * 2)
		_draw_decorated_text(canvas, text, draw_position, available_width, message_font, font_size, text_color, line_spacing)
		
		# ルビを描画
		_draw_ruby_text(canvas, text, draw_position, message_font, font_size)

## 改行対応テキスト描画
func _draw_wrapped_text(canvas, text: String, start_pos: Vector2, max_width: float, font: Font, font_size: int, color: Color, line_spacing: float):
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

## 装飾対応テキスト描画（文字単位で装飾を適用）
func _draw_decorated_text(canvas, text: String, start_pos: Vector2, max_width: float, font: Font, font_size: int, base_color: Color, line_spacing: float):
	# テキストは既にInlineCommandManagerで正規化済み（\nに変換済み）
	var current_x = start_pos.x
	var current_y = start_pos.y
	var current_position = 0
	
	# 文字アニメーションシステムが有効かチェック
	var animation_time = 0.0
	if character_animation and is_animation_enabled:
		# 現在の経過時間を取得
		animation_time = Time.get_ticks_msec() / 1000.0
		character_animation.update_animations(0.016)  # 60FPSと仮定して約16ms
	
	# 文字単位で装飾を適用しながら描画
	for i in range(text.length()):
		var char = text[i]
		
		if char == "\n":
			# 改行処理
			current_x = start_pos.x
			current_y += font.get_height(font_size) + line_spacing
			current_position += 1
			continue
		
		# 文字が表示可能な範囲内かチェック
		if current_position >= current_display_length:
			break
		
		# 現在位置での有効な装飾を取得
		var active_decorations = _get_active_decorations_at_position(current_position)
		
		# 装飾を適用した描画設定を計算
		var render_info = _calculate_char_render_info(char, font, font_size, base_color, active_decorations)
		
		# アニメーション効果を適用
		var final_position = Vector2(current_x, current_y)
		var final_color = render_info.color
		var final_scale = 1.0
		
		if character_animation and is_animation_enabled:
			# スキップモードまたは文字がトリガーされている場合のみアニメーション値を取得
			if character_animation.is_skip_requested or character_animation.is_character_ready_to_show(current_position):
				var animation_values = character_animation.get_character_animation_values(current_position)
				
				# アニメーション値を適用（デフォルト値を設定）
				if animation_values.has("alpha"):
					final_color.a *= animation_values.alpha
				elif character_animation.is_skip_requested:
					# スキップ時は強制的にalpha=1.0を保証
					final_color.a *= 1.0
				
				if animation_values.has("y_offset"):
					final_position.y += animation_values.y_offset
				elif animation_values.has("offset_y"):  # 後方互換
					final_position.y += animation_values.offset_y
				
				if animation_values.has("scale"):
					final_scale = animation_values.scale
			else:
				# まだトリガーされていない文字は透明にする
				final_color.a = 0.0
		
		# 文字を描画（アニメーション効果適用後）
		if final_color.a > 0.01:  # ほぼ透明な文字は描画しない
			canvas.draw_text_at(char, final_position, render_info.font, render_info.font_size, final_color)
		
		# 次の文字位置を計算
		var char_width = font.get_string_size(char, HORIZONTAL_ALIGNMENT_LEFT, -1, render_info.font_size).x
		current_x += char_width
		current_position += 1
		
		# 行の幅制限チェック（簡易版）
		if current_x > start_pos.x + max_width:
			current_x = start_pos.x
			current_y += font.get_height(font_size) + line_spacing

## 文字の描画情報を装飾に基づいて計算
func _calculate_char_render_info(char: String, base_font: Font, base_font_size: int, base_color: Color, decorations: Array[Dictionary]) -> Dictionary:
	var render_info = {
		"font": base_font,
		"font_size": base_font_size,
		"color": base_color
	}
	
	# 装飾を順次適用
	for decoration in decorations:
		match decoration.type:
			"color":
				render_info.color = _parse_color_from_args(decoration.args)
			"size":
				render_info.font_size = _parse_size_from_args(decoration.args, base_font_size)
			# 他の装飾タイプ（bold, italic など）はフォント変更で対応予定
	
	return render_info

## 装飾引数から色を解析
func _parse_color_from_args(args: Dictionary) -> Color:
	# {color=#ff0000} または {color=red} 形式をサポート
	if args.has("color"):
		return _parse_color_string(args["color"])
	elif args.has("0"):  # 無名引数
		return _parse_color_string(args["0"])
	return Color.WHITE

## カラー文字列をColor型に変換
func _parse_color_string(color_str: String) -> Color:
	# #で始まる16進数カラー
	if color_str.begins_with("#"):
		return Color(color_str)
	
	# 名前付きカラー
	match color_str.to_lower():
		"red": return Color.RED
		"green": return Color.GREEN
		"blue": return Color.BLUE
		"yellow": return Color.YELLOW
		"white": return Color.WHITE
		"black": return Color.BLACK
		"gray", "grey": return Color.GRAY
		_: return Color.WHITE

## 装飾引数からサイズを解析
func _parse_size_from_args(args: Dictionary, base_size: int) -> int:
	var size_value = base_size
	
	if args.has("size"):
		size_value = int(args["size"])
	elif args.has("0"):  # 無名引数
		size_value = int(args["0"])
	
	# サイズの範囲制限
	return max(8, min(48, size_value))

# =============================================================================
# ルビ表示機能
# =============================================================================

## position_commandsからルビデータを抽出
func _extract_ruby_data(position_commands: Array):
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

# =============================================================================
# テキスト装飾システム
# =============================================================================

## position_commandsから装飾データを抽出
func _extract_decoration_data(position_commands: Array):
	text_decorations.clear()
	decoration_stack.clear()
	
	for command_info in position_commands:
		var command_name = command_info.get("command_name", "")
		var position = command_info.get("display_position", 0)
		var args = command_info.get("args", {})
		
		# 装飾タグかチェック（color, bold, italic, size など）
		if _is_decoration_command(command_name):
			_process_decoration_command(command_name, position, args)

## 装飾コマンドかどうか判定
func _is_decoration_command(command_name: String) -> bool:
	var decoration_commands = ["color", "bold", "italic", "size", "underline"]
	return command_name in decoration_commands

## 装飾コマンドを処理
func _process_decoration_command(command_name: String, position: int, args: Dictionary):
	var is_closing = args.has("_closing") or args.has("/" + command_name)
	
	if is_closing:
		# 終了タグ: スタックから対応する開始タグを探して装飾範囲を確定
		_close_decoration(command_name, position)
	else:
		# 開始タグ: スタックに登録
		_open_decoration(command_name, position, args)

## 装飾の開始を処理
func _open_decoration(command_name: String, position: int, args: Dictionary):
	var decoration_info = {
		"type": command_name,
		"start_position": position,
		"end_position": -1,  # 未確定
		"args": args,
		"is_active": false
	}
	decoration_stack.append(decoration_info)
	ArgodeSystem.log("🎨 Decoration opened: %s at position %d with args: %s" % [command_name, position, str(args)])

## 装飾の終了を処理
func _close_decoration(command_name: String, position: int):
	# スタックから最後に開始された同じタイプの装飾を探す
	for i in range(decoration_stack.size() - 1, -1, -1):
		var decoration_info = decoration_stack[i]
		if decoration_info.type == command_name and decoration_info.end_position == -1:
			# 装飾範囲を確定
			decoration_info.end_position = position
			text_decorations.append(decoration_info)
			decoration_stack.remove_at(i)
			ArgodeSystem.log("🎨 Decoration closed: %s from %d to %d" % [command_name, decoration_info.start_position, position])
			return
	
	ArgodeSystem.log("⚠️ No matching opening tag found for /%s at position %d" % [command_name, position], 1)

## 指定位置で有効な装飾を取得
func _get_active_decorations_at_position(position: int) -> Array[Dictionary]:
	var active_decorations: Array[Dictionary] = []
	
	for decoration in text_decorations:
		if decoration.start_position <= position and position < decoration.end_position:
			active_decorations.append(decoration)
	
	return active_decorations

## タイプライター進行に応じてルビ表示を更新
func _update_ruby_visibility(current_length: int):
	current_display_length = current_length
	
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
func add_ruby_display(base_text: String, ruby_text: String):
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
	_update_ruby_visibility(current_display_length)

## ルビを描画（_draw_message_contentから呼ばれる）
func _draw_ruby_text(canvas, text: String, draw_position: Vector2, font: Font, font_size: int):
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
		var ruby_position = _calculate_ruby_position(text, ruby_info.position, draw_position, font, font_size, line_spacing)
		
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

## 指定された文字位置の正確な描画座標を計算
func _calculate_ruby_position(text: String, target_position: int, draw_position: Vector2, font: Font, font_size: int, line_spacing: float) -> Vector2:
	var current_x = draw_position.x
	var current_y = draw_position.y
	
	# テキストは既にInlineCommandManagerで正規化済み（\nに変換済み）
	
	# 表示されている文字数まで制限
	var max_position = min(target_position, min(current_display_length, text.length()))
	
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

## アニメーション更新処理（MessageCanvasから呼ばれる）
func _update_character_animations(delta: float):
	if character_animation and is_animation_enabled:
		character_animation.update_animations(delta)