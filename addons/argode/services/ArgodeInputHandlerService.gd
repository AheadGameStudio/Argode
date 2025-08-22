# ArgodeInputHandlerService.gd
extends RefCounted

class_name ArgodeInputHandlerService

## 入力処理・デバウンス制御サービス（ArgodeControllerと連携）
## 責任: 入力デバウンシング、入力状態管理、ArgodeController との協調

# 入力デバウンス制御
var input_debounce_timer: float = 0.0
var last_input_time: int = 0
const INPUT_DEBOUNCE_TIME: float = 0.1  # 100ms

# 入力状態
var is_input_enabled: bool = true
var input_disable_reason: String = ""

# ArgodeControllerの参照
var controller: ArgodeController = null

# シグナル: 有効な入力が処理された時
signal valid_input_received(action_name: String)

func _init():
	# ArgodeControllerとの接続はStatementManagerから行われる（遅延初期化）
	pass

## ArgodeControllerとの連携を設定（StatementManagerから呼び出し）
func _setup_controller_connection():
	# この関数は削除予定 - StatementManagerから直接connect_input_handler_serviceが呼ばれる
	pass

## ArgodeControllerからの入力を処理
func _on_controller_input(action_name: String):
	ArgodeSystem.log_workflow("🎮 InputHandler received: %s" % action_name)
	
	# Argode専用アクションのみを処理
	if not action_name.begins_with("argode_"):
		ArgodeSystem.log_workflow("🎮 Input ignored (not argode): %s" % action_name)
		return
	
	# 入力が無効化されている場合はスキップ
	if not is_input_enabled:
		# 🔍 DEBUG: 入力無効化詳細（通常は非表示）
		ArgodeSystem.log_workflow("🎮 Input ignored (disabled): %s - reason: %s" % [action_name, input_disable_reason])
		return
	
	# デバウンシング処理
	if not _process_input_debouncing():
		# 🔍 DEBUG: デバウンス詳細（通常は非表示）
		ArgodeSystem.log_workflow("🎮 Input debounced: %s" % action_name)
		return
	
	# 有効な入力として処理
	# 🔍 DEBUG: 入力処理詳細（通常は非表示）
	ArgodeSystem.log_workflow("🎮 Valid input processed: %s" % action_name)
	valid_input_received.emit(action_name)

## デバウンシング処理
func _process_input_debouncing() -> bool:
	var current_time_ms = Time.get_ticks_msec()
	var time_since_last = (current_time_ms - last_input_time) / 1000.0
	
	if time_since_last < INPUT_DEBOUNCE_TIME:
		return false  # デバウンス中
	
	last_input_time = current_time_ms
	return true

## 入力を有効化
func enable_input():
	is_input_enabled = true
	input_disable_reason = ""
	# 🔍 DEBUG: 入力状態変更詳細（通常は非表示）
	ArgodeSystem.log_debug_detail("Input enabled")

## 入力を無効化
func disable_input(reason: String = ""):
	is_input_enabled = false
	input_disable_reason = reason
	# 🔍 DEBUG: 入力状態変更詳細（通常は非表示）
	ArgodeSystem.log_debug_detail("Input disabled: %s" % reason)

## 入力が有効かチェック
func is_input_ready() -> bool:
	return is_input_enabled and controller != null

## UI一時停止時の入力制御
func pause_for_ui(reason: String):
	disable_input("UI_PAUSE: " + reason)

## UI一時停止解除時の入力制御
func resume_from_ui():
	if input_disable_reason.begins_with("UI_PAUSE:"):
		enable_input()

## 入力デバウンス時間を動的に変更
func set_debounce_time(new_time: float):
	if new_time >= 0.0:
		# INPUT_DEBOUNCE_TIME = new_time  # const なので変更不可
		# 将来的に動的変更が必要な場合は変数に変更
		# 🔍 DEBUG: デバウンス設定詳細（通常は非表示）
		ArgodeSystem.log_debug_detail("Debounce time change requested: %f (current: %f)" % [new_time, INPUT_DEBOUNCE_TIME])

## デバッグ用：入力状態を出力
func debug_print_input_state():
	# 🔍 DEBUG: 入力状態詳細（通常は非表示）
	ArgodeSystem.log_debug_detail("InputHandlerService State:")
	ArgodeSystem.log_debug_detail("  enabled: %s, reason: %s" % [str(is_input_enabled), input_disable_reason])
	ArgodeSystem.log_debug_detail("  controller: %s" % ("connected" if controller != null else "not connected"))
	ArgodeSystem.log_debug_detail("  debounce_time: %f" % INPUT_DEBOUNCE_TIME)
