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

## === 基本API ===

func initialize(typewriter):  # 動的型付け（循環参照回避）
	"""Typewriterとの連携を初期化"""
	typewriter_ref = weakref(typewriter)
	command_queue.clear()
	current_position = 0
	ArgodeSystem.log_workflow("🎯 [Phase 3] CommandExecutor initialized")

func register_commands_from_text(text: String):
	"""テキストからコマンドを抽出して登録"""
	command_queue.clear()
	
	# Phase 3: waitコマンドの検出と登録
	var commands = _extract_wait_commands(text)
	
	for cmd_data in commands:
		var execution = CommandExecution.new(
			cmd_data.type,
			cmd_data.position,
			cmd_data.parameters
		)
		command_queue.append(execution)
	
	# 位置順にソート
	command_queue.sort_custom(_sort_by_position)
	
	ArgodeSystem.log_workflow("🎯 [Phase 3] Registered %d commands from text" % command_queue.size())
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
	ArgodeSystem.log_workflow("🎯 [Phase 3] Executing %s command at position %d" % [command.command_type, command.trigger_position])
	
	match command.command_type:
		"wait":
			_execute_wait_command(command)
		_:
			ArgodeSystem.log_warning("🎯 [Phase 3] Unknown command type: %s" % command.command_type)

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

## === ヘルパー関数 ===

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
