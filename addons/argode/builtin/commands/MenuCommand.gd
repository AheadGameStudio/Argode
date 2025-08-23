extends ArgodeCommandBase
class_name MenuCommand

# 選択肢処理のための内部状態
var choice_dialog = null
var choice_options: Array[Dictionary] = []
var selected_choice_index: int = -1
var is_waiting_for_choice: bool = false

func _ready():
	command_class_name = "MenuCommand"
	command_execute_name = "menu"
	command_description = "選択肢メニューを表示します"
	command_help = "menu: の形式で使用し、その後に選択肢をインデントして記述します"

func validate_args(args: Dictionary) -> bool:
	return true

## Universal Block Execution対応のシンプル設計
func execute_core(args: Dictionary) -> void:
	print("🎯 MENU: Starting Universal Block Execution menu")
	
	# StatementManagerから現在のステートメント情報を取得
	var statement_manager = ArgodeSystem.StatementManager
	if not statement_manager or not statement_manager.execution_service:
		log_error("StatementManager or ExecutionService not found")
		return
	
	# ExecutionServiceから現在実行中のステートメントを取得
	var current_statement = statement_manager.execution_service.get_executing_statement()
	if current_statement.is_empty():
		log_error("Could not get current statement")
		return
	
	print("🎯 MENU: Got statement - type: %s, name: %s" % [current_statement.get("type"), current_statement.get("name")])
	
	# menuコマンドの検証
	if current_statement.get("type") != "command" or current_statement.get("name") != "menu":
		log_error("Current statement is not a menu command")
		return
	
	# 選択肢データを取得
	var menu_options = current_statement.get("options", [])
	if menu_options.is_empty():
		log_error("No menu options found")
		return
	
	# 選択肢データを変換
	choice_options.clear()
	for i in range(menu_options.size()):
		var option = menu_options[i]
		choice_options.append({
			"index": i,
			"text": option.get("text", ""),
			"statements": option.get("statements", [])
		})
	
	print("🎯 MENU: Found %d choice options" % choice_options.size())
	
	# 選択肢ダイアログを表示（ExecutionServiceの実行は自動的に一時停止）
	await _show_choice_dialog()
	
	# Universal Block Execution: 選択された選択肢のブロックを直接実行
	if selected_choice_index >= 0 and selected_choice_index < choice_options.size():
		var selected_choice = choice_options[selected_choice_index]
		var choice_statements = selected_choice.get("statements", [])
		
		print("🎯 MENU: Choice selected: %d - %s" % [selected_choice_index, selected_choice.get("text", "")])
		
		# Universal Block Execution: 選択肢のステートメントを直接実行
		if choice_statements.size() > 0:
			print("🎯 MENU: Executing %d choice statements via Universal Block Execution" % choice_statements.size())
			await statement_manager.execute_block(choice_statements)
			print("🎯 MENU: Choice statements execution completed")
		else:
			print("🎯 MENU: No statements in choice - proceeding")
	else:
		log_warning("No valid choice was selected")
	
	print("🎯 MENU: Menu execution completed")

## シンプルな選択肢ダイアログ表示
func _show_choice_dialog():
	var ui_manager = ArgodeSystem.UIManager
	if not ui_manager:
		log_error("UIManager not found")
		return
	
	# ダイアログシーンを追加
	var choice_scene_path = "res://addons/argode/builtin/scenes/default_choice_dialog/default_choice_dialog.tscn"
	var added_successfully = ui_manager.add_ui(choice_scene_path, "choice", 100)
	if not added_successfully:
		log_error("Failed to add choice dialog scene")
		return
	
	# ダイアログインスタンスを取得
	choice_dialog = ui_manager.get_ui("choice")
	if not choice_dialog:
		log_error("Failed to get choice dialog instance")
		return
	
	# 選択肢データを設定
	choice_dialog.setup_choices(choice_options)
	
	# 選択完了シグナルを接続
	if choice_dialog.has_signal("choice_selected"):
		if not choice_dialog.choice_selected.is_connected(_on_choice_selected):
			choice_dialog.choice_selected.connect(_on_choice_selected)
	
	# ダイアログを表示
	ui_manager.show_ui("choice")
	print("🎯 MENU: Choice dialog displayed")
	
	# 選択待機
	is_waiting_for_choice = true
	selected_choice_index = -1
	
	await Engine.get_main_loop().process_frame
	
	# オートプレイモードの場合は自動選択
	if ArgodeSystem.is_auto_play_mode():
		print("🎯 MENU: AUTO-PLAY MODE - selecting first choice")
		selected_choice_index = 0
		is_waiting_for_choice = false
	else:
		# 通常モードでは入力待ち
		while selected_choice_index == -1:
			await Engine.get_main_loop().process_frame
	
	print("🎯 MENU: Choice selection completed: %d" % selected_choice_index)
	
	# ダイアログを非表示
	ui_manager.hide_ui("choice")

## 選択肢選択時のコールバック
func _on_choice_selected(choice_index: int):
	print("🎯 MENU: User selected choice: %d" % choice_index)
	selected_choice_index = choice_index
	is_waiting_for_choice = false
