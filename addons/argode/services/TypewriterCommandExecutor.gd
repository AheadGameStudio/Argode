extends RefCounted
class_name TypewriterCommandExecutor

## TypewriterCommandExecutor v1.2.0 Phase 3
## 位置ベースコマンド実行制御 - waitコマンド問題解決版

# プリロード（循環参照回避のため動的型付けに変更）
# const ArgodeMessageTypewriter = preload("res://addons/argode/services/ArgodeMessageTypewriter.gd")

## === コマンド実行情報 ===

class CommandExecution:
	var command_type: String = ""        # "wait", "speed", etc.
	var trigger_position: int = 0        # 実行する文字位置
	var parameters: Dictionary = {}      # コマンドパラメータ
	var is_executed: bool = false        # 実行済みフラグ
	
	func _init(type: String, position: int, params: Dictionary = {}):
		command_type = type
		trigger_position = position
		parameters = params

## === プロパティ ===

var command_queue: Array[CommandExecution] = []  # 実行待ちコマンド
var current_position: int = 0                    # 現在の文字位置
var typewriter_ref: WeakRef                      # Typewriterへの参照
var glyph_manager_ref: WeakRef                   # GlyphManagerへの参照

## === 基本API ===

func initialize(typewriter):  # 動的型付け（循環参照回避）
	"""Typewriterとの連携を初期化"""
	typewriter_ref = weakref(typewriter)
	
	# GlyphManagerへの参照を取得
	if typewriter.has_method("get_glyph_manager"):
		var glyph_manager = typewriter.get_glyph_manager()
		if glyph_manager:
			glyph_manager_ref = weakref(glyph_manager)
			ArgodeSystem.log_workflow("🎯 TypewriterCommandExecutor: GlyphManager reference acquired")
		else:
			ArgodeSystem.log_workflow("⚠️ TypewriterCommandExecutor: GlyphManager not found")
	
	command_queue.clear()
	current_position = 0
	ArgodeSystem.log_workflow("🎯 [Phase 3] CommandExecutor initialized")

func register_commands_from_text(text: String):
	"""テキストからコマンドを抽出して登録"""
	command_queue.clear()
	
	ArgodeSystem.log_workflow("🎯 [REGISTER START] register_commands_from_text called")
	ArgodeSystem.log_workflow("🎯 [REGISTER START] Text length: %d" % text.length())
	ArgodeSystem.log_workflow("🎯 [REGISTER START] Text content: '%s'" % text)
	
	# Stage 6: 全リッチテキストコマンドの検出と登録
	var commands: Array = []
	commands.append_array(_extract_wait_commands(text))
	commands.append_array(_extract_decoration_commands(text))
	
	for cmd_data in commands:
		var execution = CommandExecution.new(
			cmd_data.type,
			cmd_data.position,
			cmd_data.parameters
		)
		command_queue.append(execution)
	
	# 位置順にソート
	command_queue.sort_custom(_sort_by_position)
	
	ArgodeSystem.log_workflow("🎯 [Stage 6] Registered %d commands from text" % command_queue.size())
	_log_command_queue()

func check_and_execute_commands(position: int):
	"""指定位置でのコマンド実行チェック"""
	current_position = position
	
	for command in command_queue:
		if not command.is_executed and command.trigger_position <= position:
			_execute_command(command)
			command.is_executed = true

func reset_for_new_text():
	"""新しいテキスト用にリセット"""
	command_queue.clear()
	current_position = 0

## === 内部処理（Phase 3） ===

func _extract_wait_commands(text: String) -> Array:
	"""waitコマンドを抽出（Phase 3実装）"""
	var commands: Array = []
	
	# {w=0.5}、{wait=1.0} パターンの検出
	var regex = RegEx.new()
	regex.compile(r"\{(w|wait)=([0-9.]+)\}")
	
	var results = regex.search_all(text)
	for result in results:
		var command_data = {
			"type": "wait",
			"position": _calculate_display_position(text, result.get_start()),
			"parameters": {
				"duration": float(result.get_string(2))
			},
			"original_start": result.get_start(),
			"original_end": result.get_end()
		}
		commands.append(command_data)
		
		ArgodeSystem.log_workflow("🎯 [Phase 3] Found wait command at position %d (display pos: %d, duration: %.2f)" % [
			result.get_start(), command_data.position, command_data.parameters.duration
		])
	
	return commands

func _extract_decoration_commands(text: String) -> Array:
	"""装飾コマンドを抽出（Stage 6実装）"""
	var commands: Array = []
	
	ArgodeSystem.log_workflow("🔍 EXTRACT DEBUG: Full text to search: '%s'" % text)
	
	# {color=#ff0000}...{/color} パターン
	var color_regex = RegEx.new()
	color_regex.compile(r"\{color=([^}]+)\}([^{]*)\{/color\}")
	ArgodeSystem.log_workflow("🔍 EXTRACT DEBUG: Color regex pattern: \\{color=([^}]+)\\}([^{]*)\\{/color\\}")
	
	var color_results = color_regex.search_all(text)
	ArgodeSystem.log_workflow("🔍 EXTRACT DEBUG: Found %d color matches" % color_results.size())
	
	for result in color_results:
		ArgodeSystem.log_workflow("🔍 EXTRACT DEBUG: Color match found:")
		ArgodeSystem.log_workflow("  - Full match: '%s'" % result.get_string(0))
		ArgodeSystem.log_workflow("  - Color value: '%s'" % result.get_string(1))
		ArgodeSystem.log_workflow("  - Content text: '%s'" % result.get_string(2))
		ArgodeSystem.log_workflow("  - Start position: %d" % result.get_start())
		ArgodeSystem.log_workflow("  - End position: %d" % result.get_end())
		
		var start_pos = _calculate_display_position(text, result.get_start())
		commands.append({
			"type": "color_start",
			"position": start_pos,
			"parameters": {"color": result.get_string(1)},
			"original_start": result.get_start(),
			"original_end": result.get_end()
		})
		
		# 終了位置も計算（テキスト内容を考慮）
		var content_length = result.get_string(2).length()
		commands.append({
			"type": "color_end", 
			"position": start_pos + content_length,
			"parameters": {},
			"original_start": result.get_start(),
			"original_end": result.get_end()
		})
		
		ArgodeSystem.log_workflow("🎨 [Stage 6] Found color command: %s at positions %d-%d" % [
			result.get_string(1), start_pos, start_pos + content_length
		])
	
	# {scale=1.5}...{/scale} パターン
	var scale_regex = RegEx.new()
	scale_regex.compile(r"\{scale=([^}]+)\}([^{]*)\{/scale\}")
	var scale_results = scale_regex.search_all(text)
	
	for result in scale_results:
		var start_pos = _calculate_display_position(text, result.get_start())
		var content_length = result.get_string(2).length()
		
		commands.append({
			"type": "scale_start",
			"position": start_pos,
			"parameters": {"scale": float(result.get_string(1))},
			"original_start": result.get_start(),
			"original_end": result.get_end()
		})
		
		commands.append({
			"type": "scale_end",
			"position": start_pos + content_length,
			"parameters": {},
			"original_start": result.get_start(),
			"original_end": result.get_end()
		})
		
		ArgodeSystem.log_workflow("🎨 [Stage 6] Found scale command: %s at positions %d-%d" % [
			result.get_string(1), start_pos, start_pos + content_length
		])
	
	# {move=x,y}...{/move} パターン
	var move_regex = RegEx.new()
	move_regex.compile(r"\{move=([^,]+),([^}]+)\}([^{]*)\{/move\}")
	var move_results = move_regex.search_all(text)
	
	for result in move_results:
		var start_pos = _calculate_display_position(text, result.get_start())
		var content_length = result.get_string(3).length()
		
		commands.append({
			"type": "move_start",
			"position": start_pos,
			"parameters": {
				"x": float(result.get_string(1)),
				"y": float(result.get_string(2))
			},
			"original_start": result.get_start(),
			"original_end": result.get_end()
		})
		
		commands.append({
			"type": "move_end",
			"position": start_pos + content_length,
			"parameters": {},
			"original_start": result.get_start(),
			"original_end": result.get_end()
		})
		
		ArgodeSystem.log_workflow("🎨 [Stage 6] Found move command: (%s,%s) at positions %d-%d" % [
			result.get_string(1), result.get_string(2), start_pos, start_pos + content_length
		])
	
	return commands

func _calculate_display_position(text: String, original_position: int) -> int:
	"""元のテキスト位置から表示位置を計算（Phase 3核心機能）"""
	# Phase 3: コマンドタグを除外した実際の表示位置を計算
	var display_text = ""
	var current_pos = 0
	
	# 元のテキストを文字単位で走査
	while current_pos < text.length() and current_pos < original_position:
		var char = text[current_pos]
		
		if char == "{":
			# コマンドタグの開始を検出
			var tag_end = text.find("}", current_pos)
			if tag_end != -1:
				# タグ全体をスキップ
				current_pos = tag_end + 1
				continue
		
		# 通常の文字として追加
		display_text += char
		current_pos += 1
	
	var display_position = display_text.length()
	ArgodeSystem.log_workflow("🎯 [Phase 3] Position mapping: original %d -> display %d (text: '%s')" % [
		original_position, display_position, display_text
	])
	
	return display_position

func _execute_command(command: CommandExecution):
	"""コマンドを実行"""
	ArgodeSystem.log_workflow("🎯 [Stage 6] Executing %s command at position %d" % [command.command_type, command.trigger_position])
	
	match command.command_type:
		"wait":
			_execute_wait_command(command)
		"color_start":
			_execute_color_start_command(command)
		"color_end":
			_execute_color_end_command(command)
		"scale_start":
			_execute_scale_start_command(command)
		"scale_end":
			_execute_scale_end_command(command)
		"move_start":
			_execute_move_start_command(command)
		"move_end":
			_execute_move_end_command(command)
		_:
			ArgodeSystem.log_warning("🎯 [Stage 6] Unknown command type: %s" % command.command_type)

func _execute_wait_command(command: CommandExecution):
	"""waitコマンド実行"""
	var duration = command.parameters.get("duration", 1.0)
	var typewriter = typewriter_ref.get_ref() if typewriter_ref else null
	
	if not typewriter:
		ArgodeSystem.log_warning("🎯 [Phase 3] Wait command failed: typewriter reference lost")
		return
	
	ArgodeSystem.log_workflow("🎯 [Phase 3] Executing wait: %.2f seconds at position %d" % [duration, command.trigger_position])
	
	# Typewriterを**即座に**一時停止
	typewriter.pause_typing()
	
	# 指定時間後に再開
	var timer = Timer.new()
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(_on_wait_timer_timeout.bind(timer, typewriter))
	
	# タイマーをシーンツリーに追加
	if ArgodeSystem.get_tree():
		ArgodeSystem.get_tree().root.add_child(timer)
		timer.start()

func _on_wait_timer_timeout(timer: Timer, typewriter):  # 動的型付け
	"""wait完了時の処理"""
	ArgodeSystem.log_workflow("🎯 [Phase 3] Wait completed, resuming typewriter")
	
	# wait中は is_paused = true なので、is_typing のみチェック
	if typewriter and typewriter.is_typing:
		typewriter.resume_typing()
		ArgodeSystem.log_workflow("🎯 [Phase 3] Typewriter successfully resumed")
	else:
		ArgodeSystem.log_warning("🎯 [Phase 3] Typewriter not in typing state during wait completion")
	
	# タイマーを削除
	if timer and is_instance_valid(timer):
		timer.queue_free()

## === 装飾コマンド実行機能（Stage 6） ===

func _execute_color_start_command(command: CommandExecution):
	"""色変更開始コマンド実行"""
	var color = command.parameters.get("color", "#ffffff")
	ArgodeSystem.log_workflow("🎨🎨 [COLOR START] Starting color effect: %s at position %d" % [color, command.trigger_position])
	
	# GlyphManagerがあるかチェック
	if not glyph_manager_ref or not glyph_manager_ref.get_ref():
		ArgodeSystem.log_workflow("⚠️ GlyphManager not available for color effect")
		return
	
	var glyph_manager = glyph_manager_ref.get_ref()
	
	# 色文字列をColor型に変換
	var target_color = _parse_color_string(color)
	ArgodeSystem.log_workflow("🎨🎨 [COLOR START] Parsed color: %s → %s" % [color, target_color])
	
	# 位置範囲の計算（終了コマンドとペアになる）
	var start_pos = command.trigger_position
	var end_pos = _find_matching_end_position("color_end", start_pos)
	ArgodeSystem.log_workflow("🎨🎨 [COLOR START] Position range: %d → %d" % [start_pos, end_pos])
	
	# 色エフェクトを作成して範囲に適用
	var color_effect = ArgodeColorEffect.new(target_color, 0.0)  # 即座変更
	if end_pos >= 0:
		glyph_manager.add_effect_to_range(start_pos, end_pos - 1, color_effect)
		ArgodeSystem.log_workflow("🎨 Applied color effect to range %d-%d" % [start_pos, end_pos - 1])
	else:
		# 終了位置が見つからない場合は単一文字に適用
		glyph_manager.add_effect_to_glyph(start_pos, color_effect)
		ArgodeSystem.log_workflow("🎨 Applied color effect to single glyph %d" % start_pos)

func _execute_color_end_command(command: CommandExecution):
	"""色変更終了コマンド実行"""
	ArgodeSystem.log_workflow("🎨 [Stage 6] Ending color effect at position %d" % command.trigger_position)
	# 終了コマンドは開始時に範囲適用済みのため、ログ出力のみ

func _execute_scale_start_command(command: CommandExecution):
	"""スケール変更開始コマンド実行"""
	var scale = command.parameters.get("scale", 1.0)
	ArgodeSystem.log_workflow("🎨 [Stage 6] Starting scale effect: %.2f at position %d" % [scale, command.trigger_position])
	
	# GlyphManagerがあるかチェック
	if not glyph_manager_ref or not glyph_manager_ref.get_ref():
		ArgodeSystem.log_workflow("⚠️ GlyphManager not available for scale effect")
		return
	
	var glyph_manager = glyph_manager_ref.get_ref()
	
	# 位置範囲の計算
	var start_pos = command.trigger_position
	var end_pos = _find_matching_end_position("scale_end", start_pos)
	
	# スケールエフェクトを作成して範囲に適用
	var scale_effect = ArgodeScaleEffect.new(scale, 0.3)  # 0.3秒でスケール変化
	if end_pos >= 0:
		glyph_manager.add_effect_to_range(start_pos, end_pos - 1, scale_effect)
		ArgodeSystem.log_workflow("🎨 Applied scale effect to range %d-%d" % [start_pos, end_pos - 1])
	else:
		# 終了位置が見つからない場合は単一文字に適用
		glyph_manager.add_effect_to_glyph(start_pos, scale_effect)
		ArgodeSystem.log_workflow("🎨 Applied scale effect to single glyph %d" % start_pos)

func _execute_scale_end_command(command: CommandExecution):
	"""スケール変更終了コマンド実行"""
	ArgodeSystem.log_workflow("🎨 [Stage 6] Ending scale effect at position %d" % command.trigger_position)
	# 終了コマンドは開始時に範囲適用済みのため、ログ出力のみ

func _execute_move_start_command(command: CommandExecution):
	"""移動エフェクト開始コマンド実行"""
	var x = command.parameters.get("x", 0.0)
	var y = command.parameters.get("y", 0.0)
	ArgodeSystem.log_workflow("🎨 [Stage 6] Starting move effect: (%.2f, %.2f) at position %d" % [x, y, command.trigger_position])
	
	# GlyphManagerがあるかチェック
	if not glyph_manager_ref or not glyph_manager_ref.get_ref():
		ArgodeSystem.log_workflow("⚠️ GlyphManager not available for move effect")
		return
	
	var glyph_manager = glyph_manager_ref.get_ref()
	
	# 位置範囲の計算
	var start_pos = command.trigger_position
	var end_pos = _find_matching_end_position("move_end", start_pos)
	
	# 移動エフェクトを作成して範囲に適用
	var move_effect = ArgodeMoveEffect.new(Vector2(x, y), 0.5)  # 0.5秒で移動
	if end_pos >= 0:
		glyph_manager.add_effect_to_range(start_pos, end_pos - 1, move_effect)
		ArgodeSystem.log_workflow("🎨 Applied move effect to range %d-%d" % [start_pos, end_pos - 1])
	else:
		# 終了位置が見つからない場合は単一文字に適用
		glyph_manager.add_effect_to_glyph(start_pos, move_effect)
		ArgodeSystem.log_workflow("🎨 Applied move effect to single glyph %d" % start_pos)

func _execute_move_end_command(command: CommandExecution):
	"""移動エフェクト終了コマンド実行"""
	ArgodeSystem.log_workflow("🎨 [Stage 6] Ending move effect at position %d" % command.trigger_position)
	# 終了コマンドは開始時に範囲適用済みのため、ログ出力のみ

## === ヘルパー関数 ===

func _find_matching_end_position(end_command_type: String, start_position: int) -> int:
	"""開始コマンドに対応する終了コマンドの位置を検索"""
	for cmd in command_queue:
		if cmd.command_type == end_command_type and cmd.trigger_position > start_position:
			return cmd.trigger_position
	return -1  # 終了コマンドが見つからない

func _parse_color_string(color_str: String) -> Color:
	"""色文字列をColor型に変換"""
	if color_str.begins_with("#"):
		return Color(color_str)
	
	# 名前付き色の処理
	match color_str.to_lower():
		"red": return Color.RED
		"green": return Color.GREEN
		"blue": return Color.BLUE
		"yellow": return Color.YELLOW
		"white": return Color.WHITE
		"black": return Color.BLACK
		_: return Color(color_str)  # フォールバック

func _sort_by_position(a: CommandExecution, b: CommandExecution) -> bool:
	"""位置順ソート用比較関数"""
	return a.trigger_position < b.trigger_position

func _log_command_queue():
	"""コマンドキューのデバッグ出力"""
	ArgodeSystem.log_workflow("🎯 [Phase 3] Command queue:")
	for i in range(command_queue.size()):
		var cmd = command_queue[i]
		ArgodeSystem.log_workflow("  %d: %s at position %d (params: %s)" % [
			i, cmd.command_type, cmd.trigger_position, str(cmd.parameters)
		])

func get_pending_commands_count() -> int:
	"""未実行コマンド数を取得"""
	var count = 0
	for command in command_queue:
		if not command.is_executed:
			count += 1
	return count

## === クリーンアップ（タイマー問題解決） ===

func cleanup():
	"""コマンドエグゼキューターのクリーンアップ"""
	command_queue.clear()
	
	# WeakRefをクリア
	if typewriter_ref:
		typewriter_ref = null
	
	ArgodeSystem.log_workflow("🧹 [Phase 3] TypewriterCommandExecutor cleaned up")
