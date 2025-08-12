# ArgodeUIScene.gd
# UICommandで表示されるControlシーンの基底クラス
extends Control
class_name ArgodeUIScene

# シグナル定義
signal screen_result(result: Variant)  # call_screenで結果を返す
signal close_screen()                  # 自分自身を閉じる
signal argode_command_requested(command_name: String, parameters: Dictionary)

# ArgodeSystemへの参照
var argode_system: Node = null
var adv_screen: Node = null  # メッセージウィンドウ等への参照

func _ready():
	print("🎬 [ArgodeUIScene] Scene ready:", get_scene_file_path())
	_setup_argode_references()

func _setup_argode_references():
	"""ArgodeSystemやAdvScreenへの参照を設定"""
	# ArgodeSystemを取得
	argode_system = get_node("/root/ArgodeSystem")
	if argode_system:
		print("✅ [ArgodeUIScene] ArgodeSystem reference obtained")
		
		# UIManagerからAdvScreenを取得
		if argode_system.UIManager and argode_system.UIManager.current_screen:
			adv_screen = argode_system.UIManager.current_screen
			print("✅ [ArgodeUIScene] AdvScreen reference obtained:", adv_screen.name)
		else:
			print("⚠️ [ArgodeUIScene] AdvScreen not found")
	else:
		print("❌ [ArgodeUIScene] ArgodeSystem not found")

# === ゲームコマンド実行機能 ===

func execute_argode_command(command_name: String, parameters: Dictionary = {}) -> void:
	"""Argodeコマンドを実行"""
	print("🎯 [ArgodeUIScene] Executing command:", command_name, "with params:", parameters)
	
	if not argode_system:
		push_error("❌ ArgodeSystem not available")
		return
	
	# AdvScriptPlayerを通じてコマンドを実行
	if argode_system.Player:
		match command_name:
			"jump", "call", "return":
				# ジャンプ/コール系コマンドは直接実行
				_execute_script_command(command_name, parameters)
			"set":
				# 変数設定
				_execute_variable_command(parameters)
			"save", "load":
				# セーブ/ロード系
				_execute_save_load_command(command_name, parameters)
			_:
				# その他のコマンドはシグナル経由
				argode_command_requested.emit(command_name, parameters)
	else:
		push_error("❌ AdvScriptPlayer not available")

func _execute_script_command(command_name: String, parameters: Dictionary):
	"""スクリプトコマンド（jump/call/return）を実行"""
	match command_name:
		"jump":
			var label = parameters.get("label", "")
			var file = parameters.get("file", "")
			if label.is_empty():
				push_error("❌ Jump command requires label")
				return
			
			print("🚀 [ArgodeUIScene] Executing jump to:", label)
			if file.is_empty():
				argode_system.Player.jump_to_label(label)
			else:
				argode_system.Player.jump_to_label_in_file(label, file)
		
		"call":
			var label = parameters.get("label", "")
			var file = parameters.get("file", "")
			if label.is_empty():
				push_error("❌ Call command requires label")
				return
			
			print("📞 [ArgodeUIScene] Executing call to:", label)
			if file.is_empty():
				argode_system.Player.call_label(label)
			else:
				argode_system.Player.call_label_in_file(label, file)
		
		"return":
			print("↩️ [ArgodeUIScene] Executing return")
			argode_system.Player.return_from_call()

func _execute_variable_command(parameters: Dictionary):
	"""変数設定コマンドを実行"""
	var var_name = parameters.get("name", "")
	var value = parameters.get("value", null)
	
	if var_name.is_empty():
		push_error("❌ Variable command requires name")
		return
	
	print("📊 [ArgodeUIScene] Setting variable:", var_name, "=", value)
	if argode_system.Variables:
		argode_system.Variables.set_variable(var_name, value)
	else:
		push_error("❌ VariableManager not available")

func _execute_save_load_command(command_name: String, parameters: Dictionary):
	"""セーブ/ロードコマンドを実行"""
	var slot = parameters.get("slot", 0)
	
	match command_name:
		"save":
			print("💾 [ArgodeUIScene] Saving to slot:", slot)
			# セーブ機能の実装（ArgodeSystemにセーブマネージャーがある場合）
			if argode_system.has_method("save_game"):
				argode_system.save_game(slot)
		
		"load":
			print("📂 [ArgodeUIScene] Loading from slot:", slot)
			# ロード機能の実装
			if argode_system.has_method("load_game"):
				argode_system.load_game(slot)

# === UI操作機能 ===

func show_message(speaker: String, message: String):
	"""メッセージウィンドウに表示"""
	if adv_screen and adv_screen.has_method("show_message"):
		adv_screen.show_message(speaker, message)
		print("💬 [ArgodeUIScene] Message shown:", speaker, "-", message)
	else:
		print("⚠️ [ArgodeUIScene] Cannot show message - AdvScreen not available")

func show_choices(choices: Array[String]) -> int:
	"""選択肢を表示して結果を取得"""
	if adv_screen and adv_screen.has_method("show_choices"):
		var choice_result = await adv_screen.show_choices(choices)
		print("🤔 [ArgodeUIScene] Choice selected:", choice_result)
		return choice_result
	else:
		print("⚠️ [ArgodeUIScene] Cannot show choices - AdvScreen not available")
		return -1

func hide_message_window():
	"""メッセージウィンドウを隠す"""
	if argode_system.UIManager:
		argode_system.UIManager.set_visibility(false)
		print("🙈 [ArgodeUIScene] Message window hidden")

func show_message_window():
	"""メッセージウィンドウを表示"""
	if argode_system.UIManager:
		argode_system.UIManager.set_visibility(true)
		print("👁️ [ArgodeUIScene] Message window shown")

# === call_screen結果返し機能 ===

func return_result(result: Variant):
	"""call_screenの結果を返す"""
	print("📋 [ArgodeUIScene] Returning result:", result)
	screen_result.emit(result)

func close_self():
	"""自分自身を閉じる"""
	print("🔚 [ArgodeUIScene] Closing self")
	close_screen.emit()

# === 便利メソッド ===

func get_variable(var_name: String) -> Variant:
	"""変数の値を取得"""
	if argode_system and argode_system.Variables:
		return argode_system.Variables.get_variable(var_name)
	return null

func set_variable(var_name: String, value: Variant):
	"""変数を設定"""
	if argode_system and argode_system.Variables:
		argode_system.Variables.set_variable(var_name, value)

func is_flag_set(flag_name: String) -> bool:
	"""フラグの状態をチェック"""
	return get_variable(flag_name) == true

func set_flag(flag_name: String, value: bool = true):
	"""フラグを設定"""
	set_variable(flag_name, value)
