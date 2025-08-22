extends RefCounted
class_name ArgodeTypewriterService

## タイプライター効果でテキストを1文字ずつ表示するサービス
## ルビ【】、変数[]、タグ{}は一括処理し、改行\nに対応

# タイプライター効果の設定
var typing_speed: float = 0.05  # 1文字あたりの秒数
var is_typing: bool = false
var is_paused: bool = false
var was_skipped: bool = false  # ユーザーによってスキップされたかどうか
var current_text: String = ""
var display_text: String = ""
var current_index: int = 0

# 動的速度制御
var base_speed: float = 0.05  # 基本速度（リセット時に使用）

# インライン待機制御
var pending_inline_waits: Array[Dictionary] = []  # {position: int, wait_time: float}の配列

# コールバック
var on_character_typed: Callable  # 1文字表示されるたびに呼ばれる
var on_typing_finished: Callable  # タイプライター完了時に呼ばれる

# 特殊文字のスキップ処理
var skip_brackets: bool = true  # 【】、[]、{}をスキップするか

signal character_typed(character: String, current_display: String)
signal typing_finished(final_text: String)

func _init():
	pass

## タイプライター効果を開始
func start_typing(text: String, speed: float = 0.05):
	# エスケープされた改行文字を実際の改行文字に変換
	current_text = text.replace("\\n", "\n")
	typing_speed = speed
	display_text = ""
	current_index = 0
	is_typing = true
	is_paused = false
	was_skipped = false  # スキップフラグをリセット
	pending_inline_waits.clear()  # インライン待機をクリア
	
	ArgodeSystem.log("⌨️ Starting typewriter effect: '%s'" % current_text.substr(0, 20) + ("..." if current_text.length() > 20 else ""))
	
	# タイプライター処理を開始
	_process_typing()

## タイプライター処理を一時停止
func pause_typing():
	is_paused = true
	ArgodeSystem.log("⏸️ Typewriter paused")

## タイプライター処理を再開
func resume_typing():
	if is_typing and is_paused:
		is_paused = false
		ArgodeSystem.log("▶️ Typewriter resumed")
		_process_typing()

## タイプライター処理を即座に完了
func complete_typing():
	if is_typing:
		display_text = current_text
		current_index = current_text.length()
		is_typing = false
		is_paused = false
		was_skipped = true  # スキップフラグを設定
		
		# 完全なテキストが表示されるよう文字タイプコールバックを呼び出し
		if on_character_typed.is_valid():
			on_character_typed.call("", display_text)  # 完全なテキストで更新
		character_typed.emit("", display_text)
		
		# 完了コールバックを呼び出し
		if on_typing_finished.is_valid():
			on_typing_finished.call(display_text)
		
		typing_finished.emit(display_text)
		ArgodeSystem.log("⏭️ Typewriter completed instantly (SKIPPED)")

## タイプライター処理を停止
func stop_typing():
	is_typing = false
	is_paused = false
	was_skipped = false  # スキップフラグをリセット
	display_text = ""
	current_index = 0
	ArgodeSystem.log("⏹️ Typewriter stopped")

## メインのタイプライター処理
func _process_typing():
	while is_typing and not is_paused and current_index < current_text.length():
		var char = current_text[current_index]
		
		# 特殊文字の処理
		if skip_brackets and _is_special_character_start(char):
			var skip_length = _get_skip_length()
			if skip_length > 0:
				# 特殊文字列を一括で追加
				var special_text = current_text.substr(current_index, skip_length)
				display_text += special_text
				current_index += skip_length
				
				# 特殊文字も文字タイプイベントを発行
				if on_character_typed.is_valid():
					on_character_typed.call(special_text, display_text)
				character_typed.emit(special_text, display_text)
				
				continue
		
		# 通常の文字を追加
		display_text += char
		current_index += 1
		
		# 文字タイプイベントを発行
		if on_character_typed.is_valid():
			on_character_typed.call(char, display_text)
		character_typed.emit(char, display_text)
		
		# 改行の場合は少し長めに待機
		var wait_time = typing_speed
		if char == "\n":
			wait_time *= 2.0  # 改行は2倍の時間
		
		# 次の文字まで待機
		await Engine.get_main_loop().create_timer(wait_time).timeout
	
	# タイプライター完了
	if is_typing and current_index >= current_text.length():
		is_typing = false
		is_paused = false
		# was_skipped はそのまま（自然完了の場合は false のまま）
		
		if on_typing_finished.is_valid():
			on_typing_finished.call(display_text)
		
		typing_finished.emit(display_text)
		ArgodeSystem.log("✅ Typewriter effect completed naturally (not skipped)")

## 特殊文字の開始かどうかを判定
func _is_special_character_start(char: String) -> bool:
	return char in ["【", "[", "{"]

## スキップすべき文字数を取得
func _get_skip_length() -> int:
	var start_char = current_text[current_index]
	var end_char = ""
	
	# 対応する終了文字を決定
	match start_char:
		"【":
			end_char = "】"
		"[":
			end_char = "]"
		"{":
			end_char = "}"
		_:
			return 0
	
	# 終了文字を探す
	var search_start = current_index + 1
	var end_index = current_text.find(end_char, search_start)
	
	if end_index != -1:
		# 開始から終了までの長さ
		return end_index - current_index + 1
	else:
		# 終了文字が見つからない場合は開始文字のみ
		return 1

## コールバックを設定
func set_callbacks(character_callback: Callable, finish_callback: Callable):
	on_character_typed = character_callback
	on_typing_finished = finish_callback

## 現在の状態を取得
func is_currently_typing() -> bool:
	return is_typing

func was_typewriter_skipped() -> bool:
	return was_skipped

func get_current_display_text() -> String:
	return display_text

func get_typing_progress() -> float:
	if current_text.is_empty():
		return 1.0
	return float(current_index) / float(current_text.length())

## デバッグ情報を出力
func debug_print_state():
	ArgodeSystem.log("🔍 TypewriterService Debug Info:")
	ArgodeSystem.log("  - Is typing: %s" % str(is_typing))
	ArgodeSystem.log("  - Is paused: %s" % str(is_paused))
	ArgodeSystem.log("  - Progress: %d/%d (%.1f%%)" % [current_index, current_text.length(), get_typing_progress() * 100])
	ArgodeSystem.log("  - Current text: '%s'" % current_text.substr(0, 50) + ("..." if current_text.length() > 50 else ""))
	ArgodeSystem.log("  - Display text: '%s'" % display_text.substr(0, 50) + ("..." if display_text.length() > 50 else ""))

## 位置ベースコマンド付きタイプライター効果を開始
func start_typing_with_position_commands(text: String, position_commands: Array, inline_command_manager: ArgodeInlineCommandManager, speed: float = 0.05):
	# 通常のタイプライター効果を開始
	start_typing(text, speed)
	
	# 位置ベースコマンドを監視するタイマーを設定
	_monitor_position_commands(position_commands, inline_command_manager)

## 位置ベースコマンドの監視
func _monitor_position_commands(position_commands: Array, inline_command_manager: ArgodeInlineCommandManager):
	ArgodeSystem.log("🎯 TypewriterService: Starting position command monitoring with %d commands" % position_commands.size())
	for i in range(position_commands.size()):
		var cmd = position_commands[i]
		ArgodeSystem.log("🎯   Command %d: %s at position %d" % [i, cmd.get("command_name", "unknown"), cmd.get("display_position", -1)])
	
	# タイプライター進行中に位置をチェック
	while is_typing:
		var current_position = display_text.length()
		
		# 現在位置のコマンドを実行
		for command_info in position_commands:
			if command_info.display_position <= current_position and not command_info.get("executed", false):
				# コマンドを実行
				ArgodeSystem.log("🎯 TypewriterService: Executing inline command at position %d (current_position: %d)" % [command_info.display_position, current_position])
				inline_command_manager.execute_commands_at_position(command_info.display_position)
				command_info["executed"] = true  # 実行済みマーク
				ArgodeSystem.log("✅ TypewriterService: Inline command executed and marked")
		
		# 少し待機してから次のチェック
		await _wait_frame()
	
	# タイプライター完了後、残りのコマンドをすべて実行
	for command_info in position_commands:
		if not command_info.get("executed", false):
			inline_command_manager.execute_commands_at_position(command_info.display_position)

# =============================================================================
# 動的速度制御機能
# =============================================================================

## 基本速度を設定 (新しいタイプライター開始時に使用)
func set_base_speed(speed: float):
	base_speed = speed
	typing_speed = speed

## 現在の速度を一時的に変更 (StatementManagerから使用)
func set_temporary_speed(speed: float):
	typing_speed = speed

## 基本速度にリセット
func reset_to_base_speed():
	typing_speed = base_speed

## 現在の実効速度を取得
func get_current_speed() -> float:
	return typing_speed

## 基本速度を取得
func get_base_speed() -> float:
	return base_speed

## フレーム待機ヘルパー
func _wait_frame():
	await ArgodeSystem.get_tree().process_frame

## インライン待機を追加（{w=1.0}タグ用）
func add_inline_wait(wait_time: float):
	var wait_info = {
		"position": current_index,  # 現在のタイピング位置
		"wait_time": wait_time
	}
	pending_inline_waits.append(wait_info)
	ArgodeSystem.log("📝 Inline wait added at position %d: %.1f seconds" % [current_index, wait_time])