extends ArgodeCommandBase
class_name MenuCommand

# 選択肢処理のための内部状態
var choice_dialog = null
var choice_options: Array[Dictionary] = []
var selected_choice_index: int = -1
var is_waiting_for_choice: bool = false
var current_menu_statement: Dictionary = {}  # 実行開始時のステートメントを保存

func _ready():
	command_class_name = "MenuCommand"
	command_execute_name = "menu"
	command_description = "選択肢メニューを表示します"
	command_help = "menu: の形式で使用し、その後に選択肢をインデントして記述します"

func validate_args(args: Dictionary) -> bool:
	# menuコマンドは選択肢データをStatementManagerから取得するため引数は不要
	return true

func execute_core(args: Dictionary) -> void:
	log_info("MenuCommand: 選択肢メニューを表示開始")
	
	# StatementManagerから現在のステートメント情報を取得
	var statement_manager = ArgodeSystem.StatementManager
	if not statement_manager:
		log_error("StatementManager not found")
		return
	
	# StatementManagerの実行を一時停止
	statement_manager.set_waiting_for_command(true, "MenuCommand choice dialog")
	
	# 実行開始時に現在のステートメント情報を保存
	current_menu_statement = statement_manager.get_current_statement()
	if current_menu_statement.is_empty():
		log_error("Could not get current statement from StatementManager")
		statement_manager.set_waiting_for_command(false, "MenuCommand failed")
		return
	
	# ステートメント構造の検証とデバッグ出力
	log_info("🔍 Statement debug - Type: %s, Name: %s, Keys: %s" % [
		current_menu_statement.get("type", "unknown"),
		current_menu_statement.get("name", "unknown"), 
		str(current_menu_statement.keys())
	])
	
	# menuコマンドの検証
	if current_menu_statement.get("type") != "command" or current_menu_statement.get("name") != "menu":
		log_error("Current statement is not a menu command")
		statement_manager.set_waiting_for_command(false, "MenuCommand validation failed")
		return
	
	# 選択肢データを直接解析（RGDパーサーの構造に従う）
	var menu_options = current_menu_statement.get("options", [])
	if menu_options.is_empty():
		log_error("No menu options found in statement")
		statement_manager.set_waiting_for_command(false, "MenuCommand no options")
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
		log_info("📋 Option %d: %s (%d statements)" % [i, option.get("text", ""), option.get("statements", []).size()])
	
	log_info("Found %d choice options" % choice_options.size())
	
	# choiceシーンを表示
	await _show_choice_dialog()
	
	# 選択結果を処理
	if selected_choice_index >= 0 and selected_choice_index < choice_options.size():
		var selected_choice = choice_options[selected_choice_index]
		var choice_statements = selected_choice.get("statements", [])
		
		log_info("Choice selected: %d - %s" % [selected_choice_index, selected_choice.get("text", "")])
		log_info("🔍 Choice statements count: %d" % choice_statements.size())
		
		# ステートメントの詳細をログ出力
		for i in range(choice_statements.size()):
			var stmt = choice_statements[i]
			log_info("📋 Statement %d: Type=%s, Name=%s" % [i, stmt.get("type", "unknown"), stmt.get("name", "unknown")])
		
		# 選択肢のステートメントをContextServiceにプッシュして実行
		if choice_statements.size() > 0:
			log_info("🎯 Pushing choice statements to ContextService...")
			var context_service = ArgodeSystem.StatementManager.context_service
			if context_service:
				context_service.push_context(choice_statements, "menu_choice_" + str(selected_choice_index))
				log_info("✅ Choice statements pushed to context")
			else:
				log_error("ContextService not found")
		
		# 実行完了後は通常通り継続（何も特別な処理は不要）
		log_info("🔄 MenuCommand execution completed, proceeding to next statement")
	else:
		log_warning("No valid choice was selected")
	
	# StatementManagerの実行を再開（選択肢実行後も正常に継続）
	statement_manager.set_waiting_for_command(false, "MenuCommand completed")

## 選択肢ダイアログを表示
func _show_choice_dialog():
	"""選択肢ダイアログを表示して選択結果を待機"""
	# UIManagerからchoiceシーンを取得
	var ui_manager = ArgodeSystem.UIManager
	if not ui_manager:
		log_error("UIManager not found")
		return
	
	# ダイアログシーンを追加
	# TODO: パスをカスタマイズ可能にする（設定ファイルやプロジェクト設定から取得）
	var choice_scene_path = "res://addons/argode/builtin/scenes/default_choice_dialog/default_choice_dialog.tscn"
	var added_successfully = ui_manager.add_ui(choice_scene_path, "choice", 100)
	if not added_successfully:
		log_error("Failed to add choice dialog scene")
		return
	
	log_info("Choice scene added to UIManager")
	
	# ダイアログインスタンスを取得
	choice_dialog = ui_manager.get_ui("choice")
	if not choice_dialog:
		log_error("Failed to get choice dialog instance")
		return
	
	log_info("Choice dialog instance obtained: %s" % choice_dialog.get_class())
	
	# 選択肢データを設定
	log_info("Calling setup_choices with %d options" % choice_options.size())
	choice_dialog.setup_choices(choice_options)
	log_info("Choice options set up in dialog")
	
	# 選択完了シグナルを接続
	if choice_dialog.has_signal("choice_selected"):
		if not choice_dialog.choice_selected.is_connected(_on_choice_selected):
			choice_dialog.choice_selected.connect(_on_choice_selected)
		log_info("Choice selection signal connected")
	else:
		log_warning("Choice dialog does not have choice_selected signal")
	
	# ダイアログを表示
	ui_manager.show_ui("choice")
	log_info("Showing choice dialog...")
	log_info("Choice dialog displayed")
	
	# StatementManagerを一時停止してMenuCommandの選択待ちに移行
	var statement_manager = ArgodeSystem.StatementManager
	if statement_manager.execution_service:
		statement_manager.execution_service.pause_execution()
		log_info("ExecutionService paused for choice dialog")
	
	# 選択待機開始
	log_info("Starting choice wait loop...")
	is_waiting_for_choice = true
	selected_choice_index = -1
	
	# 選択肢が表示されるまで待機
	await Engine.get_main_loop().process_frame
	
	# ヘッドレスモードまたはオートプレイモードの場合は自動選択
	if ArgodeSystem.is_auto_play_mode():
		log_info("🧪 AUTO-PLAY MODE: Auto-selecting first choice")
		await Engine.get_main_loop().process_frame
		# 最初の選択肢を自動選択
		selected_choice_index = 0
		is_waiting_for_choice = false
	else:
		# 通常モードでは入力待ち
		while selected_choice_index == -1:
			await Engine.get_main_loop().process_frame
	
	log_info("Choice selected by user: %d" % selected_choice_index)
	log_info("Choice wait completed, selected index: %d" % selected_choice_index)
	
	# StatementManagerの実行を再開
	if statement_manager.execution_service:
		statement_manager.execution_service.resume_execution()
		log_info("ExecutionService resumed after choice completion")
	
	# ダイアログを非表示
	ui_manager.hide_ui("choice")
	log_info("Choice dialog hidden")

## 選択肢選択時のコールバック
func _on_choice_selected(choice_index: int):
	"""ユーザーが選択肢を選択した時のコールバック"""
	log_info("Choice selected by user: %d" % choice_index)
	selected_choice_index = choice_index
	is_waiting_for_choice = false
