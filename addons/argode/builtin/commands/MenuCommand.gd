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
		
		# 選択肢のステートメントを直接実行（insertではなく直接実行で継続性を保つ）
		if choice_statements.size() > 0:
			log_info("🎯 Executing choice statements directly...")
			await statement_manager._execute_child_statements(choice_statements)
			log_info("✅ Choice statements execution completed")
		
		# 実行完了後は通常通り継続（何も特別な処理は不要）
		log_info("🔄 MenuCommand execution completed, proceeding to next statement")
	else:
		log_warning("No valid choice was selected")
	
	# StatementManagerの実行を再開（選択肢実行後も正常に継続）
	statement_manager.set_waiting_for_command(false, "MenuCommand completed")

## 選択肢ダイアログを表示
func _show_choice_dialog():
	"""選択肢ダイアログを表示し、ユーザーの選択を待つ"""
	
	# UIManagerを取得
	var ui_manager = ArgodeSystem.UIManager
	if not ui_manager:
		log_error("UIManager not found")
		return
	
	# choiceシーンがまだ管理されていない場合は追加
	if not ui_manager.get_all_ui().has("choice"):
		var choice_scene_path = ArgodeSystem.built_in_ui_paths.get("choice", "")
		if choice_scene_path.is_empty():
			log_error("Choice scene path not found in built_in_ui_paths")
			return
		
		if not ResourceLoader.exists(choice_scene_path):
			log_error("Choice scene file does not exist: %s" % choice_scene_path)
			return
		
		# choiceシーンをUIManagerに追加
		ui_manager.add_ui(choice_scene_path, "choice", 50)  # Z-Index 50で表示
		log_info("Choice scene added to UIManager")
	
	# 選択肢ダイアログのインスタンスを取得
	choice_dialog = ui_manager.get_ui("choice")
	if not choice_dialog:
		log_error("Failed to get choice dialog instance")
		return
	
	log_info("Choice dialog instance obtained: %s" % choice_dialog.get_class())
	
	# 選択肢データを設定
	if choice_dialog.has_method("setup_choices"):
		log_info("Calling setup_choices with %d options" % choice_options.size())
		choice_dialog.setup_choices(choice_options)
		log_info("Choice options set up in dialog")
	else:
		log_error("Choice dialog does not have setup_choices method")
		return
	
	# 選択完了シグナルを接続
	if choice_dialog.has_signal("choice_selected"):
		if not choice_dialog.choice_selected.is_connected(_on_choice_selected):
			choice_dialog.choice_selected.connect(_on_choice_selected)
			log_info("Choice selection signal connected")
		else:
			log_info("Choice selection signal was already connected")
	else:
		log_error("Choice dialog does not have choice_selected signal")
		return
	
	# choiceシーンを表示
	log_info("Showing choice dialog...")
	ui_manager.show_ui("choice")
	log_info("Choice dialog displayed")
	
	# StatementManagerを一時停止してユーザー入力を無効化
	var statement_manager = ArgodeSystem.StatementManager
	if statement_manager:
		statement_manager.pause_ui_operations("MenuCommand choice dialog displayed")
	
	# 選択を待機
	is_waiting_for_choice = true
	selected_choice_index = -1
	
	log_info("Starting choice wait loop...")
	# 選択完了まで待機（StatementManagerの実行状態を考慮）
	while is_waiting_for_choice:
		# 実行が停止された場合は待機終了
		if not ArgodeSystem.StatementManager or not ArgodeSystem.StatementManager.is_executing:
			log_warning("Execution stopped during choice wait")
			break
		await Engine.get_main_loop().process_frame
	
	log_info("Choice wait completed, selected index: %d" % selected_choice_index)
	
	# StatementManagerの一時停止を解除
	if statement_manager:
		statement_manager.resume_ui_operations("MenuCommand choice dialog completed")
	
	# ダイアログを非表示
	ui_manager.hide_ui("choice")
	log_info("Choice dialog hidden")
	
	# シグナル接続を解除
	if choice_dialog and choice_dialog.choice_selected.is_connected(_on_choice_selected):
		choice_dialog.choice_selected.disconnect(_on_choice_selected)

## 選択肢選択時のコールバック
func _on_choice_selected(choice_index: int):
	"""ユーザーが選択肢を選択した時のコールバック"""
	log_info("Choice selected by user: %d" % choice_index)
	selected_choice_index = choice_index
	is_waiting_for_choice = false
