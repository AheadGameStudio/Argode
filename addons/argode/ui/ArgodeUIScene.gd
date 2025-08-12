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
				argode_system.Player.play_from_label(label)
			else:
				# ファイル跨ぎのジャンプはLabelRegistryを使用
				if argode_system.LabelRegistry and argode_system.LabelRegistry.has_method("jump_to_label"):
					argode_system.LabelRegistry.jump_to_label(label, argode_system.Player)
				else:
					push_error("❌ Cross-file jump not supported - LabelRegistry not available")
		
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
				# ファイル跨ぎのcallはまだ未サポート（必要に応じて実装）
				push_error("❌ Cross-file call not yet supported")
		
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

# === 辞書型変数のヘルパーメソッド ===

func get_nested_variable(path: String) -> Variant:
	"""ネストした変数の値を取得（例: "player.level" or "flags.story.chapter1"）"""
	if argode_system and argode_system.Variables:
		return argode_system.Variables.get_nested_variable(path)
	return null

func set_nested_variable(path: String, value: Variant):
	"""ネストした変数を設定（例: "player.level = 5"）"""
	if argode_system and argode_system.Variables:
		argode_system.Variables.set_nested_variable(path, value)

func get_flag(flag_name: String) -> bool:
	"""フラグの値を取得（boolean型として）"""
	if argode_system and argode_system.Variables:
		return argode_system.Variables.get_flag(flag_name)
	return false

func set_flag_in_group(group: String, flag_name: String, value: bool = true):
	"""グループ内のフラグを設定（例: set_flag_in_group("story", "chapter1_complete", true)）"""
	set_nested_variable(group + "." + flag_name, value)

func toggle_flag(flag_name: String):
	"""フラグの状態を切り替える"""
	if argode_system and argode_system.Variables:
		argode_system.Variables.toggle_flag(flag_name)

func create_variable_group(group_name: String, initial_data: Dictionary = {}):
	"""変数グループを作成"""
	if argode_system and argode_system.Variables:
		argode_system.Variables.create_variable_group(group_name, initial_data)

func add_to_variable_group(group_name: String, key: String, value: Variant):
	"""変数グループに要素を追加"""
	if argode_system and argode_system.Variables:
		argode_system.Variables.add_to_variable_group(group_name, key, value)

func get_variable_group(group_name: String) -> Dictionary:
	"""変数グループ全体を取得"""
	if argode_system and argode_system.Variables:
		return argode_system.Variables.get_variable_group(group_name)
	return {}

# === 便利メソッド（辞書型対応版） ===

func setup_story_flags():
	"""ストーリーフラグを初期化"""
	create_variable_group("story", {
		"prologue_complete": false,
		"chapter1_complete": false,
		"chapter2_complete": false,
		"ending_seen": false
	})

func setup_character_status():
	"""キャラクターステータスを初期化"""
	create_variable_group("characters", {})
	
	# 各キャラクターの初期設定
	add_to_variable_group("characters", "player", {
		"name": "プレイヤー",
		"level": 1,
		"friendship": {}
	})

func get_character_friendship(character_name: String) -> int:
	"""キャラクターとの好感度を取得"""
	var friendship = get_nested_variable("characters.player.friendship." + character_name)
	return friendship if friendship != null else 0

func modify_character_friendship(character_name: String, amount: int):
	"""キャラクターとの好感度を変更"""
	var current = get_character_friendship(character_name)
	set_nested_variable("characters.player.friendship." + character_name, current + amount)
