extends RefCounted
class_name ArgodeMessageRenderer

## メッセージ表示の統括クラス（GlyphSystem統合版）
## Phase 4: TypewriterEffectManager相当をGlyphSystemで実現

# 新設計のプリロード
const TypewriterTextParser = preload("res://addons/argode/services/TypewriterTextParser.gd")

# メッセージウィンドウの参照
var message_window: ArgodeMessageWindow = null
var message_canvas: Control = null

# GlyphSystem統合 (Phase 4の核心)
var glyph_manager: ArgodeGlyphManager = null
var effect_animation_manager = null  # ArgodeEffectAnimationManager
var ruby_renderer: ArgodeRubyRenderer = null  # Task 6-3: ルビレンダラー
var glyph_renderer: ArgodeGlyphRenderer = null  # Task 6-3: GlyphRenderer統合

# 状態管理
var current_text: String = ""
var current_display_length: int = 0
var is_rendering: bool = false

# コールバック
var on_typewriter_completed: Callable

signal rendering_started(text: String)
signal rendering_completed()
signal character_typed(char: String, current_display: String)

func _init(window: ArgodeMessageWindow = null):
	if window:
		set_message_window(window)
	
	# GlyphSystemを初期化
	_initialize_glyph_system()

## GlyphSystemを初期化
func _initialize_glyph_system():
	"""Phase 4: GlyphSystemの初期化（TypewriterEffectManager相当）"""
	glyph_manager = ArgodeGlyphManager.new()
	
	# GlyphRendererを初期化（Task 6-3: 統合描画機能）
	glyph_renderer = ArgodeGlyphRenderer.new()
	ArgodeSystem.log_workflow("🎨 MessageRenderer: GlyphRenderer initialized")
	
	# EffectAnimationManagerを動的読み込み
	var effect_animation_script = load("res://addons/argode/services/ArgodeEffectAnimationManager.gd")
	if effect_animation_script:
		effect_animation_manager = effect_animation_script.new()
	else:
		ArgodeSystem.log("❌ [Phase 4] Failed to load ArgodeEffectAnimationManager")
		return
	
	# GlyphManagerをEffectAnimationManagerに登録
	effect_animation_manager.set_glyph_manager(glyph_manager)
	
	# シグナル接続
	if glyph_manager:
		glyph_manager.glyph_appeared.connect(_on_glyph_appeared)
		glyph_manager.all_glyphs_appeared.connect(_on_all_glyphs_appeared)
		glyph_manager.effects_completed.connect(_on_effects_completed)
	
	ArgodeSystem.log("✅ [Phase 4] GlyphSystem with GlyphRenderer initialized")

## メッセージウィンドウを設定
func set_message_window(window: ArgodeMessageWindow):
	message_window = window
	_find_message_canvas()

func _find_message_canvas():
	if not message_window:
		return
	
	message_canvas = message_window.find_child("*Canvas", true, false)
	if message_canvas:
		ArgodeSystem.log("✅ MessageCanvas found: %s" % message_canvas.name)
		
		# GlyphManagerにキャンバス情報を設定
		if glyph_manager and message_canvas.has_method("get_rect"):
			var canvas_rect = message_canvas.get_rect()
			glyph_manager.set_layout_settings(
				Vector2(10, 10),  # base_position
				30.0,             # line_height
				2.0,              # character_spacing
				canvas_rect.size.x - 20  # max_width
			)

## UIManager互換メソッド
func display_message(text: String, character_name: String = "", properties: Dictionary = {}):
	"""UIManager互換のメッセージ表示メソッド"""
	render_message(character_name, text)

## メインのメッセージ表示メソッド（GlyphSystem版）
func render_message(character_name: String, text: String):
	"""Phase 4: GlyphSystemを使用したメッセージ表示"""
	if not glyph_manager:
		ArgodeSystem.log("❌ [Phase 4] GlyphManager not available", 2)
		return
	
	# MessageCanvasが利用できない場合は再検索
	if not message_canvas and message_window:
		ArgodeSystem.log("🔄 [Phase 4] Re-searching for MessageCanvas...")
		_find_message_canvas()
	
	# MessageCanvasがなくてもGlyphSystemはテキスト処理可能
	if not message_canvas:
		ArgodeSystem.log("⚠️ [Phase 4] MessageCanvas not available, but proceeding with GlyphSystem")
	
	ArgodeSystem.log("🎨 [Phase 4] Starting GlyphSystem message rendering: [%s] %s" % [character_name, text])
	
	# メッセージウィンドウを表示
	if message_window:
		message_window.visible = true
		ArgodeSystem.log_workflow("🎨 [Phase 4] MessageWindow made visible: %s" % str(message_window))
		
		# キャラクター名設定
		if character_name and not character_name.is_empty():
			message_window.set_character_name(character_name)
		else:
			message_window.hide_character_name()
	else:
		ArgodeSystem.log_critical("🚨 [Phase 4] MessageWindow is null - cannot display message")
	
	# レンダリング開始
	is_rendering = true
	current_text = text
	rendering_started.emit(text)
	
	# 新設計: TypewriterTextParserでインラインコマンドを処理
	var parse_result = TypewriterTextParser.parse_text(text)
	var display_text = parse_result.plain_text
	var commands = parse_result.commands
	
	ArgodeSystem.log("🎨 [Phase 4] Text parsed: '%s' -> '%s' (%d commands)" % [text.substr(0, 30), display_text.substr(0, 30), commands.size()])
	
	# GlyphSystemでテキストを処理（タグ除去済みテキスト）
	glyph_manager.create_glyphs_from_text(display_text)
	glyph_manager.set_active(true)
	
	# Phase 4: 検出されたコマンドをエフェクトに変換して適用
	_apply_inline_commands_to_glyphs(commands, display_text, text)
	
	# エフェクトアニメーション開始
	if effect_animation_manager:
		effect_animation_manager.start_animation()
	
	# 🆕 タイプライター効果前にすべてのグリフを非表示にリセット
	glyph_manager.hide_all_glyphs()
	
	# タイプライター効果をシミュレート（段階的表示）
	_start_typewriter_simulation()
	
	# MessageCanvasにGlyphManagerを設定（Task 6-3: GlyphRenderer統合）
	_setup_canvas_glyph_system()

## タイプライター効果のシミュレーション
func _start_typewriter_simulation():
	"""GlyphSystemでタイプライター効果を実現"""
	var glyph_count = glyph_manager.text_glyphs.size()
	# オートプレイモードの場合は少し速めに
	var typing_speed = 0.08 if ArgodeSystem.is_auto_play_mode() else 0.05  # 80ms (auto) / 50ms (normal) per character
	
	ArgodeSystem.log("🎬 [Phase 4] Starting typewriter simulation: %d glyphs, speed: %.2fms" % [glyph_count, typing_speed * 1000])
	
	for i in range(glyph_count):
		# 👍 修正: 各文字間隔を固定にして累積遅延を解決
		if i > 0:  # 最初の文字は即座に表示
			# 入力チェック付き待機
			var timer = Engine.get_main_loop().create_timer(typing_speed)
			
			# タイマー待機中の入力チェック
			while timer.time_left > 0:
				if _should_skip_typewriter():
					# スキップ処理：残りの文字を一気に表示
					ArgodeSystem.log("⏭️ [Phase 4] Typewriter skipped at glyph %d/%d" % [i, glyph_count])
					_complete_remaining_glyphs(i)
					return  # タイプライター終了
				await Engine.get_main_loop().process_frame
			
			# タイマー完了まで待機
			await timer.timeout
		
		# グリフを表示
		glyph_manager.show_glyph(i)
		
		# キャンバス更新
		_update_canvas_display()
		
		# キャラクタータイプシグナル（配列範囲チェック）
		if i < glyph_manager.text_glyphs.size():
			var char = glyph_manager.text_glyphs[i].character
			var current_display = _get_current_display_text()
			character_typed.emit(char, current_display)
	
	# 全文字表示完了
	ArgodeSystem.log("✅ [Phase 4] Typewriter simulation completed normally")
	_on_typewriter_simulation_complete()

## 残りのグリフを一気に表示（スキップ時）
func _complete_remaining_glyphs(start_index: int):
	"""タイプライター完了時に残りの文字を一気に表示"""
	var glyph_count = glyph_manager.text_glyphs.size()
	
	for i in range(start_index, glyph_count):
		glyph_manager.show_glyph(i)
		
		# 各文字のシグナルも発火（一貫性のため）
		if i < glyph_manager.text_glyphs.size():
			var char = glyph_manager.text_glyphs[i].character
			var current_display = _get_current_display_text()
			character_typed.emit(char, current_display)
	
	# キャンバス更新
	_update_canvas_display()
	ArgodeSystem.log("⏭️ [Phase 4] Typewriter skipped - all remaining glyphs shown instantly")
	
	# 完了処理
	_on_typewriter_simulation_complete()

## タイプライタースキップ判定
func _should_skip_typewriter() -> bool:
	"""タイプライター効果をスキップすべきかチェック"""
	# オートプレイモードの場合は、タイプライター効果を必ず表示
	if ArgodeSystem.is_auto_play_mode():
		return false
	
	# 通常モードでの入力チェック
	if Input.is_action_just_pressed("argode_advance") or Input.is_action_just_pressed("ui_accept"):
		return true
	if Input.is_action_just_pressed("argode_skip"):
		return true
	
	return false

## タイプライター完了処理（統一化）
func _on_typewriter_simulation_complete():
	"""タイプライター完了時の共通処理"""
	ArgodeSystem.log("✅ [Phase 4] All glyphs appeared - message rendering complete")
	is_rendering = false
	rendering_completed.emit()
	
	# 完了コールバック呼び出し
	if on_typewriter_completed.is_valid():
		on_typewriter_completed.call()

## MessageCanvasにGlyphSystemを設定（Task 6-3: GlyphRenderer統合）
func _setup_canvas_glyph_system():
	"""MessageCanvasにGlyphManagerとGlyphRendererを設定"""
	if message_canvas and message_canvas.has_method("set_glyph_manager"):
		message_canvas.set_glyph_manager(glyph_manager)
		ArgodeSystem.log_workflow("🎨 MessageRenderer: GlyphManager set to MessageCanvas")
	elif message_canvas:
		ArgodeSystem.log_workflow("⚠️ MessageCanvas does not support GlyphSystem (missing set_glyph_manager method)")
	
	# MessageCanvasのGlyphRenderer設定を最適化
	if message_canvas and message_canvas.has_method("configure_glyph_renderer"):
		message_canvas.configure_glyph_renderer(true, 100, true)  # デバッグON、最大100グリフ、バッチON
		ArgodeSystem.log_workflow("🎨 MessageRenderer: GlyphRenderer configured for debugging")
	
	# GlyphRendererのデバッグモードも直接有効化
	if glyph_renderer:
		glyph_renderer.set_debug_mode(true)
		ArgodeSystem.log_workflow("🎨 MessageRenderer: GlyphRenderer debug mode enabled")

## キャンバス表示を更新
func _update_canvas_display():
	"""GlyphSystemの状態をMessageCanvasに反映"""
	if not glyph_manager:
		return
	
	# 表示可能な文字列を構築
	var display_text = ""
	for glyph in glyph_manager.text_glyphs:
		if glyph.is_visible:
			display_text += glyph.character
	
	# MessageCanvasがある場合のみ設定
	if message_canvas and message_canvas.has_method("set_message_text"):
		message_canvas.set_message_text(display_text)
	else:
		# MessageCanvasがない場合はログ出力のみ
		ArgodeSystem.log("📺 [Phase 4] GlyphSystem display: %s" % display_text)

## 現在の表示テキストを取得
func _get_current_display_text() -> String:
	if not glyph_manager:
		return ""
	
	var display_text = ""
	for glyph in glyph_manager.text_glyphs:
		if glyph.is_visible:
			display_text += glyph.character
	return display_text

## GlyphSystemイベントハンドラー
func _on_glyph_appeared(glyph, index: int):
	"""個別グリフ表示時のハンドラー"""
	ArgodeSystem.log("🔤 [Phase 4] Glyph appeared: '%s' at index %d" % [glyph.character, index])

func _on_all_glyphs_appeared():
	"""全グリフ表示完了時のハンドラー（旧システム用・非推奨）"""
	# 新しいタイプライターシミュレーションでは _on_typewriter_simulation_complete() を使用
	ArgodeSystem.log("⚠️ [Phase 4] Legacy glyph handler called - use _on_typewriter_simulation_complete instead")

func _on_effects_completed():
	"""エフェクト完了時のハンドラー"""
	ArgodeSystem.log("✨ [Phase 4] All glyph effects completed")

## タイプライター状態チェック
func is_typewriter_active() -> bool:
	return is_rendering

## タイプライター強制完了
func complete_typewriter():
	"""外部からタイプライター効果を強制完了させる"""
	if not is_rendering:
		return
	
	# 全てのグリフを即座に表示
	if glyph_manager:
		for i in range(glyph_manager.text_glyphs.size()):
			glyph_manager.show_glyph(i)
			
			# 各文字のシグナルも発火（一貫性のため）
			if i < glyph_manager.text_glyphs.size():
				var char = glyph_manager.text_glyphs[i].character
				var current_display = _get_current_display_text()
				character_typed.emit(char, current_display)
		
		# キャンバス更新
		_update_canvas_display()
		
		# 完了処理
		_on_typewriter_simulation_complete()
		
		ArgodeSystem.log("⏭️ [Phase 4] Typewriter force completed by external call")

## タイプライター完了コールバック設定
func set_typewriter_completion_callback(callback: Callable):
	on_typewriter_completed = callback

## メッセージクリア
func clear_message():
	if glyph_manager:
		glyph_manager.clear_glyphs()
		glyph_manager.set_active(false)
	
	if effect_animation_manager:
		effect_animation_manager.stop_animation()
	
	# MessageCanvasがある場合のみクリア
	if message_canvas and message_canvas.has_method("set_message_text"):
		message_canvas.set_message_text("")
	
	current_text = ""
	is_rendering = false

## Phase 4: インラインコマンド→エフェクト変換
func _apply_inline_commands_to_glyphs(commands: Array, display_text: String, original_text: String):
	"""検出されたインラインコマンドをグリフエフェクトに変換して適用"""
	if not glyph_manager or commands.is_empty():
		return
	
	ArgodeSystem.log("🎨 [Phase 4] Applying %d inline commands to glyphs" % commands.size())
	
	# デバッグ: 検出されたコマンドの詳細を出力
	for i in range(commands.size()):
		var command = commands[i]
		ArgodeSystem.log("🎨🔍 [COMMAND DEBUG %d] Type: '%s', Params: '%s', Start: %d" % [i, command.get("type", ""), command.get("params", ""), command.get("start", 0)])
	
	for command in commands:
		var command_type = command.get("type", "")
		var command_params = command.get("params", "")
		var command_start = command.get("start", 0)
		var is_pair = command.get("is_pair", false)
		var content = command.get("content", "")
		
		# コマンドタイプ別の処理
		match command_type:
			"color":
				_apply_color_effect(command_params, command_start, display_text, original_text, is_pair, content)
			"scale":
				_apply_scale_effect(command_params, command_start, display_text, original_text, is_pair, content)
			"move":
				_apply_move_effect(command_params, command_start, display_text, original_text)
			"w", "wait":
				# Wait効果は既にTypewriterTextParserで処理済み
				pass
			_:
				ArgodeSystem.log("⚠️ [Phase 4] Unknown inline command: %s" % command_type)

## カラーエフェクト適用
func _apply_color_effect(params: String, start_pos: int, display_text: String, original_text: String, is_pair: bool = false, content: String = ""):
	"""カラーエフェクトを該当文字範囲に適用"""
	# パラメータ解析: "=#ff0000" または "=red" -> Color値
	var color_str = params.replace("=", "").strip_edges()
	var color: Color
	
	ArgodeSystem.log("🎨🔍 [COLOR DEBUG] Processing color parameter: '%s', is_pair: %s, content: '%s'" % [color_str, is_pair, content])
	
	# 16進数カラーコード
	if color_str.begins_with("#"):
		color = Color(color_str)
		ArgodeSystem.log("🎨✅ [COLOR DEBUG] Parsed hex color: %s" % color)
	# 名前付きカラー
	else:
		color = _parse_color_string(color_str)
		if color == Color.TRANSPARENT:
			ArgodeSystem.log("🎨❌ [COLOR DEBUG] Unknown color name: '%s'" % color_str)
			return
		ArgodeSystem.log("🎨✅ [COLOR DEBUG] Parsed named color '%s': %s" % [color_str, color])
	
	# ペアタグの場合：範囲特定エフェクト適用
	if is_pair and not content.is_empty():
		var target_range = _calculate_pair_tag_range(content, display_text)
		if target_range["start"] >= 0 and target_range["end"] >= 0:
			ArgodeSystem.log("🎨 [Phase 4] Applying color %s to range %d-%d ('%s')" % [color, target_range["start"], target_range["end"], content])
			_apply_color_to_range(color, target_range["start"], target_range["end"])
		else:
			ArgodeSystem.log("🎨❌ [COLOR DEBUG] Failed to calculate range for content: '%s'" % content)
	# 単一タグの場合：従来通り全文適用
	else:
		ArgodeSystem.log("🎨 [Phase 4] Applying color %s to all text (single tag)" % color)
		_apply_color_to_range(color, 0, glyph_manager.text_glyphs.size() - 1)

## 範囲特定ヘルパー
func _calculate_pair_tag_range(content: String, display_text: String) -> Dictionary:
	"""ペアタグの内容からdisplay_text内の範囲を計算"""
	var start_pos = display_text.find(content)
	if start_pos == -1:
		return {"start": -1, "end": -1}
	
	var end_pos = start_pos + content.length() - 1
	ArgodeSystem.log("🎨🔍 [RANGE DEBUG] Found content '%s' at range %d-%d in display_text" % [content, start_pos, end_pos])
	
	return {"start": start_pos, "end": end_pos}

## 色エフェクト範囲適用
func _apply_color_to_range(color: Color, start_index: int, end_index: int):
	"""指定範囲のグリフに色エフェクトを適用"""
	if not glyph_manager or glyph_manager.text_glyphs.is_empty():
		return
	
	# 範囲チェック
	var max_index = glyph_manager.text_glyphs.size() - 1
	start_index = max(0, start_index)
	end_index = min(max_index, end_index)
	
	ArgodeSystem.log("🎨 [RANGE APPLY] Applying color %s to glyph range %d-%d" % [color, start_index, end_index])
	
	for i in range(start_index, end_index + 1):
		if i < glyph_manager.text_glyphs.size():
			var glyph = glyph_manager.text_glyphs[i]
			var color_effect = ArgodeColorEffect.new(color, 0.0)  # 即座に色変更
			glyph.add_effect(color_effect)
			ArgodeSystem.log("🎨🎭 [COLOR DEBUG] Added color effect to glyph[%d] '%s'" % [i, glyph.character])

## スケールエフェクト適用
func _apply_scale_effect(params: String, start_pos: int, display_text: String, original_text: String, is_pair: bool = false, content: String = ""):
	"""スケールエフェクトを該当文字範囲に適用"""
	# パラメータ解析: "=1.5" -> 1.5
	var scale_str = params.replace("=", "").strip_edges()
	var scale_value = scale_str.to_float()
	if scale_value <= 0:
		return
	
	ArgodeSystem.log("🎨🔍 [SCALE DEBUG] Processing scale parameter: '%s', is_pair: %s, content: '%s'" % [scale_str, is_pair, content])
	
	# ペアタグの場合：範囲特定エフェクト適用
	if is_pair and not content.is_empty():
		var target_range = _calculate_pair_tag_range(content, display_text)
		if target_range["start"] >= 0 and target_range["end"] >= 0:
			ArgodeSystem.log("🎨 [Phase 4] Applying scale %s to range %d-%d ('%s')" % [scale_value, target_range["start"], target_range["end"], content])
			_apply_scale_to_range(scale_value, target_range["start"], target_range["end"])
		else:
			ArgodeSystem.log("🎨❌ [SCALE DEBUG] Failed to calculate range for content: '%s'" % content)
	# 単一タグの場合：従来通り全文適用
	else:
		ArgodeSystem.log("🎨 [Phase 4] Applying scale %s to all text (single tag)" % scale_value)
		_apply_scale_to_range(scale_value, 0, glyph_manager.text_glyphs.size() - 1)

## スケールエフェクト範囲適用
func _apply_scale_to_range(scale_value: float, start_index: int, end_index: int):
	"""指定範囲のグリフにスケールエフェクトを適用"""
	if not glyph_manager or glyph_manager.text_glyphs.is_empty():
		return
	
	# 範囲チェック
	var max_index = glyph_manager.text_glyphs.size() - 1
	start_index = max(0, start_index)
	end_index = min(max_index, end_index)
	
	ArgodeSystem.log("🎨 [RANGE APPLY] Applying scale %s to glyph range %d-%d" % [scale_value, start_index, end_index])
	
	for i in range(start_index, end_index + 1):
		if i < glyph_manager.text_glyphs.size():
			var glyph = glyph_manager.text_glyphs[i]
			var scale_effect = ArgodeScaleEffect.new(scale_value, 0.3)  # 0.3秒でスケール変化
			glyph.add_effect(scale_effect)
			ArgodeSystem.log("🎨🎭 [SCALE DEBUG] Added scale effect to glyph[%d] '%s'" % [i, glyph.character])

## 移動エフェクト適用
func _apply_move_effect(params: String, start_pos: int, display_text: String, original_text: String):
	"""移動エフェクトを該当文字範囲に適用"""
	# パラメータ解析: "=10,5" -> Vector2(10, 5)
	var move_str = params.replace("=", "").strip_edges()
	var coords = move_str.split(",")
	if coords.size() != 2:
		return
	
	var move_x = coords[0].to_float()
	var move_y = coords[1].to_float()
	var move_offset = Vector2(move_x, move_y)
	
	ArgodeSystem.log("🎨 [Phase 4] Applying move %s to text range" % str(move_offset))
	
	# 簡易実装: 全文字に移動を適用
	for glyph in glyph_manager.text_glyphs:
		var move_effect = ArgodeMoveEffect.new(move_offset, 0.5)  # 0.5秒で移動
		glyph.add_effect(move_effect)

# ====================================================================================
# Task 6-3: ルビシステム統合
# ====================================================================================

## 現在のメッセージにルビ情報を追加
func add_ruby_to_current_message(base_text: String, ruby_text: String) -> void:
	"""MessageRendererにルビ情報を追加（既存RubyRendererシステム活用）"""
	ArgodeSystem.log_workflow("📖 MessageRenderer: ルビ追加 - '%s'（%s）" % [base_text, ruby_text])
	
	# RubyRendererが存在しない場合は作成
	if not ruby_renderer:
		ruby_renderer = ArgodeRubyRenderer.new()
		ArgodeSystem.log_workflow("📖 RubyRenderer作成完了")
	
	# 現在の表示テキストとルビ情報を追加
	var current_display = _get_current_display_text()
	var current_length = current_display.length()
	
	# RubyRendererに直接ルビを追加
	ruby_renderer.add_ruby_display(base_text, ruby_text, current_display, current_length)
	
	ArgodeSystem.log_workflow("✅ ルビ情報追加完了: '%s'（%s）" % [base_text, ruby_text])

## 装飾コマンドハンドラー（Task 6-3: ColorCommand/ScaleCommand統合）
func handle_decoration_command(command_data: Dictionary) -> void:
	"""装飾コマンドを処理してGlyphSystemに適用"""
	var command = command_data.get("command", "")
	var action = command_data.get("action", "")
	var params = command_data.get("parameters", {})
	
	ArgodeSystem.log_workflow("🎨 MessageRenderer: Handling %s decoration command (%s)" % [command, action])
	
	if not glyph_manager:
		ArgodeSystem.log_workflow("⚠️ GlyphManager not available for decoration command")
		return
	
	# 現在のテキスト位置情報を取得
	var current_position = current_display_length
	
	match command:
		"color":
			_handle_color_decoration(action, params, current_position)
		"scale":
			_handle_scale_decoration(action, params, current_position)
		"move":
			_handle_move_decoration(action, params, current_position)
		_:
			ArgodeSystem.log_workflow("⚠️ Unknown decoration command: %s" % command)

func _handle_color_decoration(action: String, params: Dictionary, position: int):
	"""色装飾の処理"""
	if action == "color_start":
		var color_str = params.get("color", "#ffffff")
		var target_color = _parse_color_string(color_str)
		
		# 現在位置から後続文字に色エフェクトを適用
		var color_effect = ArgodeColorEffect.new(target_color, 0.0)
		glyph_manager.add_effect_to_range(position, glyph_manager.text_glyphs.size() - 1, color_effect)
		ArgodeSystem.log_workflow("🎨 Applied color effect from position %d" % position)

func _handle_scale_decoration(action: String, params: Dictionary, position: int):
	"""スケール装飾の処理"""
	if action == "scale_start":
		var scale_str = params.get("scale", "1.0")
		var scale_value = scale_str.to_float()
		
		# 現在位置から後続文字にスケールエフェクトを適用
		var scale_effect = ArgodeScaleEffect.new(scale_value, 0.3)
		glyph_manager.add_effect_to_range(position, glyph_manager.text_glyphs.size() - 1, scale_effect)
		ArgodeSystem.log_workflow("🎨 Applied scale effect from position %d" % position)

func _handle_move_decoration(action: String, params: Dictionary, position: int):
	"""移動装飾の処理"""
	if action == "move_start":
		var move_str = params.get("move", "0,0")
		var move_parts = move_str.split(",")
		var x = move_parts[0].to_float() if move_parts.size() > 0 else 0.0
		var y = move_parts[1].to_float() if move_parts.size() > 1 else 0.0
		
		# 現在位置から後続文字に移動エフェクトを適用
		var move_effect = ArgodeMoveEffect.new(Vector2(x, y), 0.5)
		glyph_manager.add_effect_to_range(position, glyph_manager.text_glyphs.size() - 1, move_effect)
		ArgodeSystem.log_workflow("🎨 Applied move effect from position %d" % position)

func _parse_color_string(color_str: String) -> Color:
	"""色文字列をColor型に変換"""
	if color_str.begins_with("#"):
		return Color(color_str)
	
	# 名前付き色の処理（拡張版）
	match color_str.to_lower():
		"red": return Color.RED
		"green": return Color.GREEN
		"blue": return Color.BLUE
		"yellow": return Color.YELLOW
		"cyan": return Color.CYAN
		"magenta": return Color.MAGENTA
		"white": return Color.WHITE
		"black": return Color.BLACK
		"orange": return Color.ORANGE
		"purple": return Color.PURPLE
		"pink": return Color.HOT_PINK
		"gray", "grey": return Color.GRAY
		"darkred": return Color.DARK_RED
		"darkgreen": return Color.DARK_GREEN
		"darkblue": return Color.DARK_BLUE
		_: 
			# フォールバック: 未知の色は透明を返す
			ArgodeSystem.log("⚠️ Unknown color name: '%s'" % color_str)
			return Color.TRANSPARENT

	ArgodeSystem.log("🧹 [Phase 4] GlyphSystem message cleared")