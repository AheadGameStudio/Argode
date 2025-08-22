# ArgodeUIControlService.gd
extends RefCounted

class_name ArgodeUIControlService

## タイプライター・UI制御サービス（ArgodeUIManagerと連携）
## 責任: タイプライター制御、UI一時停止管理、UIとの協調制御

# UI一時停止制御
var is_ui_paused: bool = false
var ui_pause_reason: String = ""

# タイプライター制御状態
var typewriter_speed_stack: Array[float] = []
var typewriter_pause_count: int = 0

# ArgodeUIManagerの参照
var ui_manager: ArgodeUIManager = null

# シグナル: タイプライター完了時
signal typewriter_completed()

func _init():
	_setup_ui_manager_connection()

## ArgodeUIManagerとの連携を設定
func _setup_ui_manager_connection():
	ui_manager = ArgodeSystem.UIManager
	
	if ui_manager:
		# 🎬 WORKFLOW: UI制御システム初期化（GitHub Copilot重要情報）
		ArgodeSystem.log_workflow("UIControlService connected to ArgodeUIManager")
	else:
		# 🚨 CRITICAL: 重要なエラー（GitHub Copilot重要情報）
		ArgodeSystem.log_critical("ArgodeUIManager not found - UI control disabled")

## UI操作を一時停止
func pause_ui_operations(reason: String):
	is_ui_paused = true
	ui_pause_reason = reason
	
	# 🎬 WORKFLOW: UI一時停止（GitHub Copilot重要情報）
	ArgodeSystem.log_workflow("UI operations paused: %s" % reason)

## UI操作を再開
func resume_ui_operations(reason: String = ""):
	if is_ui_paused:
		is_ui_paused = false
		var previous_reason = ui_pause_reason
		ui_pause_reason = ""
		
		# 🎬 WORKFLOW: UI再開（GitHub Copilot重要情報）
		ArgodeSystem.log_workflow("UI operations resumed (was: %s)" % previous_reason)

## UI一時停止状態をチェック
func is_ui_operations_paused() -> bool:
	return is_ui_paused

## タイプライター速度をスタックにプッシュ
func push_typewriter_speed(new_speed: float):
	typewriter_speed_stack.push_back(new_speed)
	
	# UIManagerのタイプライター制御と連携
	if ui_manager and ui_manager.has_method("set_typewriter_speed"):
		ui_manager.set_typewriter_speed(new_speed)
	
	# 🔍 DEBUG: タイプライター制御詳細（通常は非表示）
	ArgodeSystem.log_debug_detail("Typewriter speed pushed: %f (stack depth: %d)" % [new_speed, typewriter_speed_stack.size()])

## タイプライター速度をスタックからポップ
func pop_typewriter_speed():
	if typewriter_speed_stack.is_empty():
		# 🚨 CRITICAL: 重要なエラー（GitHub Copilot重要情報）
		ArgodeSystem.log_critical("Cannot pop typewriter speed: stack is empty")
		return
	
	typewriter_speed_stack.pop_back()
	
	# スタックの最上位またはデフォルト速度を適用
	var current_speed = get_current_typewriter_speed()
	if ui_manager and ui_manager.has_method("set_typewriter_speed"):
		ui_manager.set_typewriter_speed(current_speed)
	
	# 🔍 DEBUG: タイプライター制御詳細（通常は非表示）
	ArgodeSystem.log_debug_detail("Typewriter speed popped: %f (stack depth: %d)" % [current_speed, typewriter_speed_stack.size()])

## 現在のタイプライター速度を取得
func get_current_typewriter_speed() -> float:
	if typewriter_speed_stack.is_empty():
		return 1.0  # デフォルト速度
	return typewriter_speed_stack[-1]

## タイプライターを一時停止
func pause_typewriter():
	typewriter_pause_count += 1
	
	if ui_manager and ui_manager.has_method("pause_typewriter"):
		ui_manager.pause_typewriter()
	
	# 🔍 DEBUG: タイプライター制御詳細（通常は非表示）
	ArgodeSystem.log_debug_detail("Typewriter paused (count: %d)" % typewriter_pause_count)

## タイプライターを再開
func resume_typewriter():
	if typewriter_pause_count > 0:
		typewriter_pause_count -= 1
		
		if typewriter_pause_count == 0:
			if ui_manager and ui_manager.has_method("resume_typewriter"):
				ui_manager.resume_typewriter()
		
		# 🔍 DEBUG: タイプライター制御詳細（通常は非表示）
		ArgodeSystem.log_debug_detail("Typewriter resumed (count: %d)" % typewriter_pause_count)

## タイプライターが一時停止中かチェック
func is_typewriter_paused() -> bool:
	return typewriter_pause_count > 0

## タイプライターが動作中かチェック
func is_typewriter_active() -> bool:
	if ui_manager and ui_manager.has_method("is_typewriter_active"):
		return ui_manager.is_typewriter_active()
	return false

## タイプライターを強制完了
func complete_typewriter():
	if ui_manager and ui_manager.has_method("complete_typewriter"):
		ui_manager.complete_typewriter()
		# 🔍 DEBUG: タイプライター制御詳細（通常は非表示）
		ArgodeSystem.log_debug_detail("Typewriter force completed")

## UI状態をリセット
func reset_ui_state():
	is_ui_paused = false
	ui_pause_reason = ""
	typewriter_speed_stack.clear()
	typewriter_pause_count = 0
	
	# 🎬 WORKFLOW: UI状態リセット（GitHub Copilot重要情報）
	ArgodeSystem.log_workflow("UIControlService state reset")

## デバッグ用：UI制御状態を出力
func debug_print_ui_state():
	# 🔍 DEBUG: UI制御状態詳細（通常は非表示）
	ArgodeSystem.log_debug_detail("UIControlService State:")
	ArgodeSystem.log_debug_detail("  ui_paused: %s, reason: %s" % [str(is_ui_paused), ui_pause_reason])
	ArgodeSystem.log_debug_detail("  typewriter_pause_count: %d" % typewriter_pause_count)
	ArgodeSystem.log_debug_detail("  typewriter_speed_stack: %s" % str(typewriter_speed_stack))
	ArgodeSystem.log_debug_detail("  ui_manager: %s" % ("connected" if ui_manager != null else "not connected"))
