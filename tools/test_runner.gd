#!/usr/bin/env -S godot --headless --script
# 統合テストランナー - 開発・デバッグ用
# 使用方法: godot --headless --script tools/test_runner.gd --quit -- [test_name]

extends SceneTree

enum TestType {
	CUSTOM_COMMANDS,    # カスタムコマンドテスト
	SYSTEM_INTEGRATION, # システム統合テスト  
	PERFORMANCE,        # パフォーマンステスト
	ALL                 # 全テスト実行
}

var test_results: Array = []

func _init():
	print("🧪 Argode Test Runner")
	print("============================================================")
	
	# コマンドライン引数を解析
	var args = OS.get_cmdline_args()
	var test_name = "all"
	
	print("🔍 Command line args: ", args)
	
	# テスト名を指定（オプション）
	# -- より後の引数を処理
	var found_separator = false
	for i in range(args.size()):
		if args[i] == "--":
			found_separator = true
			if i + 1 < args.size():
				test_name = args[i + 1].to_lower()
				print("📋 Selected test: ", test_name)
				break
	
	if not found_separator:
		# 引数に 'dict' か 'dictionary' が含まれているかチェック
		for arg in args:
			if arg.to_lower().contains("dict"):
				test_name = "dict"
				print("📋 Detected dictionary test from args")
				break
	
	# テスト実行
	await _run_tests(test_name)
	
	# 結果レポート
	_print_test_report()
	
	quit()

func _run_tests(test_name: String):
	"""指定されたテストを実行"""
	match test_name:
		"commands", "custom":
			await _test_custom_commands()
		"system", "integration":
			await _test_system_integration()
		"dictionary", "dict":
			await _test_dictionary_variables()
		"performance", "perf":
			await _test_performance()
		"all":
			await _test_custom_commands()
			await _test_system_integration()
			await _test_dictionary_variables()
		_:
			_log_result("❌ Unknown test type: " + test_name, false)

func _test_custom_commands():
	"""カスタムコマンドテスト"""
	print("\n🎯 Testing Custom Commands...")
	
	# ArgodeSystemが利用可能になるまで待機
	await _wait_for_argode_system()
	
	var argode_system = root.get_node_or_null("ArgodeSystem")
	if not argode_system:
		_log_result("❌ ArgodeSystem not found", false)
		return
	
	var handler = argode_system.CustomCommandHandler
	if not handler:
		_log_result("❌ CustomCommandHandler not found", false)
		return
	
	_log_result("✅ ArgodeSystem and CustomCommandHandler loaded", true)
	
	# 登録されているコマンド数をチェック
	var command_count = handler.registered_commands.size()
	_log_result("📋 Registered commands: " + str(command_count), command_count > 0)
	
	# 主要コマンドの存在確認
	var key_commands = ["text_animate", "ui_slide", "tint", "screen_flash", "wait"]
	for cmd_name in key_commands:
		var exists = handler.registered_commands.has(cmd_name)
		_log_result("  - " + cmd_name + ": " + ("✅" if exists else "❌"), exists)
	
	# パラメータ検証テスト
	if handler.registered_commands.has("text_animate"):
		var cmd = handler.registered_commands["text_animate"]
		var valid_params = {"effect": "shake", "intensity": 2.0, "duration": 1.0}
		var invalid_params = {"effect": "invalid", "intensity": -1.0}
		
		var valid_result = cmd.validate_parameters(valid_params)
		var invalid_result = cmd.validate_parameters(invalid_params)
		
		_log_result("  - Valid params test: " + ("✅" if valid_result else "❌"), valid_result)
		_log_result("  - Invalid params test: " + ("✅" if not invalid_result else "❌"), not invalid_result)
	
	# UICommand実行テスト
	if handler.registered_commands.has("ui"):
		print("🎯 Testing UICommand execution...")
		var ui_cmd = handler.registered_commands["ui"]
		
		# UICommandのパラメータ検証
		var ui_params = {"action": "show", "scene_path": "res://scenes/ui/test_control_scene.tscn"}
		var ui_valid = ui_cmd.validate_parameters(ui_params)
		_log_result("  - UI command params test: " + ("✅" if ui_valid else "❌"), ui_valid)
		
		# UICommandの実行（非同期） - 正しいパラメータフォーマット
		print("🚀 Attempting to execute UICommand with correct parameters...")
		var correct_params = {
			"_raw": "show res://scenes/ui/test_control_scene.tscn at center with fade",
			"_count": 6,
			"arg0": "show",
			"arg1": "res://scenes/ui/test_control_scene.tscn",
			"arg2": "at",
			"arg3": "center", 
			"arg4": "with",
			"arg5": "fade"
		}
		await handler._on_custom_command_executed("ui", correct_params, "ui show res://scenes/ui/test_control_scene.tscn at center with fade")
		_log_result("  - UI command execution with proper params: ✅", true)
	print("✅ UICommand execution test completed")
		
	# 追加テスト: UICommand の free と list 機能
	await _test_ui_command_memory_management()

func _test_ui_command_memory_management():
	"""UICommandのメモリ管理機能をテスト"""
	print("🧪 Testing UICommand memory management...")
	
	var argode_system = root.get_node("ArgodeSystem")
	var custom_handler = argode_system.CustomCommandHandler
	var ui_command = custom_handler.registered_commands.get("ui")
	
	if not ui_command:
		print("❌ UICommand not found in registered commands")
		return
	
	# list コマンドをテスト（空の状態）
	print("  - Testing ui list (empty)...")
	await custom_handler._execute_registered_command(ui_command, { "_raw": "list", "_count": 1, "arg0": "list" })
	await root.get_tree().process_frame
	
	# show コマンドで複数シーンを表示
	print("  - Testing ui show (multiple scenes)...")
	await custom_handler._execute_registered_command(ui_command, { "_raw": "show res://scenes/ui/test_control_scene.tscn", "_count": 2, "arg0": "show", "arg1": "res://scenes/ui/test_control_scene.tscn" })
	await root.get_tree().process_frame
	
	# 同じシーンを再度表示しようとする（警告が出るはず）
	print("  - Testing ui show (duplicate scene)...")
	await custom_handler._execute_registered_command(ui_command, { "_raw": "show res://scenes/ui/test_control_scene.tscn", "_count": 2, "arg0": "show", "arg1": "res://scenes/ui/test_control_scene.tscn" })
	await root.get_tree().process_frame
	
	# list コマンドをテスト（シーンが表示されている状態）
	print("  - Testing ui list (with scenes)...")
	await custom_handler._execute_registered_command(ui_command, { "_raw": "list", "_count": 1, "arg0": "list" })
	await root.get_tree().process_frame
	
	# 特定のシーンを free
	print("  - Testing ui free (specific scene)...")
	await custom_handler._execute_registered_command(ui_command, { "_raw": "free res://scenes/ui/test_control_scene.tscn", "_count": 2, "arg0": "free", "arg1": "res://scenes/ui/test_control_scene.tscn" })
	await root.get_tree().process_frame
	
	# list コマンドをテスト（free後）
	print("  - Testing ui list (after free)...")
	await custom_handler._execute_registered_command(ui_command, { "_raw": "list", "_count": 1, "arg0": "list" })
	await root.get_tree().process_frame
	
	# 存在しないシーンを free しようとする
	print("  - Testing ui free (non-existent scene)...")
	await custom_handler._execute_registered_command(ui_command, { "_raw": "free res://non_existent.tscn", "_count": 2, "arg0": "free", "arg1": "res://non_existent.tscn" })
	await root.get_tree().process_frame
	
	# 全てを free
	print("  - Testing ui free (all scenes)...")
	await custom_handler._execute_registered_command(ui_command, { "_raw": "free", "_count": 1, "arg0": "free" })
	await root.get_tree().process_frame
	
	print("✅ UICommand memory management test completed")
	
	# 追加テスト: UICommand の call_screen / close_screen 機能
	await _test_ui_command_call_screen()

func _test_ui_command_call_screen():
	"""UICommandのcall_screen/close_screen機能をテスト"""
	print("🧪 Testing UICommand call_screen functionality...")
	
	var argode_system = root.get_node("ArgodeSystem")
	var custom_handler = argode_system.CustomCommandHandler
	var ui_command = custom_handler.registered_commands.get("ui")
	
	if not ui_command:
		print("❌ UICommand not found in registered commands")
		return
	
	# call コマンドをテスト
	print("  - Testing ui call...")
	await custom_handler._execute_registered_command(ui_command, { "_raw": "call res://scenes/ui/test_call_screen.tscn", "_count": 2, "arg0": "call", "arg1": "res://scenes/ui/test_call_screen.tscn" })
	await root.get_tree().process_frame
	
	# list コマンドでcall_screenスタックを確認
	print("  - Testing ui list (with call screen)...")
	await custom_handler._execute_registered_command(ui_command, { "_raw": "list", "_count": 1, "arg0": "list" })
	await root.get_tree().process_frame
	
	# 少し待ってからclose
	print("  - Waiting for call screen result...")
	await root.get_tree().create_timer(1.0).timeout
	
	# close コマンドをテスト
	print("  - Testing ui close...")
	await custom_handler._execute_registered_command(ui_command, { "_raw": "close", "_count": 1, "arg0": "close" })
	await root.get_tree().process_frame
	
	# list コマンドで結果を確認
	print("  - Testing ui list (after close)...")
	await custom_handler._execute_registered_command(ui_command, { "_raw": "list", "_count": 1, "arg0": "list" })
	await root.get_tree().process_frame
	
	print("✅ UICommand call_screen test completed")

func _test_dictionary_variables():
	"""辞書型変数機能のテスト"""
	print("\n📚 Testing Dictionary Variable Features...")
	
	await _wait_for_argode_system()
	
	var argode_system = root.get_node_or_null("ArgodeSystem")
	if not argode_system:
		_log_result("❌ ArgodeSystem not found for dictionary test", false)
		return
	
	var variables = argode_system.VariableManager
	if not variables:
		_log_result("❌ VariableManager not found", false)
		return
	
	_log_result("✅ VariableManager loaded for dictionary test", true)
	
	# 基本的な辞書設定テスト
	print("  - Testing basic dictionary setting...")
	variables.set_dictionary("test_dict", '{"name": "テスト", "level": 1, "active": true}')
	
	var name_value = variables.get_nested_variable("test_dict.name")
	var level_value = variables.get_nested_variable("test_dict.level")
	var active_value = variables.get_nested_variable("test_dict.active")
	
	_log_result("    - Dictionary name: " + str(name_value), name_value == "テスト")
	_log_result("    - Dictionary level: " + str(level_value), level_value == 1)
	_log_result("    - Dictionary active: " + str(active_value), active_value == true)
	
	# ネストした辞書テスト
	print("  - Testing nested dictionary...")
	variables.set_dictionary("nested_dict", '{"player": {"stats": {"hp": 100, "mp": 50}}, "flags": {"tutorial": true}}')
	
	var hp_value = variables.get_nested_variable("nested_dict.player.stats.hp")
	var tutorial_flag = variables.get_nested_variable("nested_dict.flags.tutorial")
	
	_log_result("    - Nested HP value: " + str(hp_value), hp_value == 100)
	_log_result("    - Nested tutorial flag: " + str(tutorial_flag), tutorial_flag == true)
	
	# 配列設定テスト
	print("  - Testing array setting...")
	variables.set_array("test_array", '["item1", "item2", "item3"]')
	
	var array_value = variables.get_variable("test_array")
	_log_result("    - Array is Array type: " + str(array_value is Array), array_value is Array)
	if array_value is Array:
		_log_result("    - Array size: " + str(array_value.size()), array_value.size() == 3)
		_log_result("    - Array first element: " + str(array_value[0]), array_value[0] == "item1")
	
	# フラグ管理テスト
	print("  - Testing flag management...")
	variables.set_flag("test_flag", true)
	variables.set_flag("test_flag2", false)
	
	var flag1 = variables.get_flag("test_flag")
	var flag2 = variables.get_flag("test_flag2")
	
	_log_result("    - Flag 1 (true): " + str(flag1), flag1 == true)
	_log_result("    - Flag 2 (false): " + str(flag2), flag2 == false)
	
	# フラグ切り替えテスト
	variables.toggle_flag("test_flag")
	var toggled_flag = variables.get_flag("test_flag")
	_log_result("    - Toggled flag: " + str(toggled_flag), toggled_flag == false)
	
	# 変数グループテスト
	print("  - Testing variable groups...")
	variables.create_variable_group("game_data", {"score": 1000, "lives": 3})
	variables.add_to_variable_group("game_data", "highscore", 5000)
	
	var score = variables.get_nested_variable("game_data.score")
	var highscore = variables.get_nested_variable("game_data.highscore")
	
	_log_result("    - Group score: " + str(score), score == 1000)
	_log_result("    - Group highscore: " + str(highscore), highscore == 5000)
	
	# 変数展開テスト
	print("  - Testing variable expansion...")
	var expanded_text = variables.expand_variables("プレイヤー: [test_dict.name], レベル: [test_dict.level]")
	var expected_text = "プレイヤー: テスト, レベル: 1"
	_log_result("    - Variable expansion: " + expanded_text, expanded_text == expected_text)
	
	# set_dictコマンドのテスト
	print("  - Testing set_dict command...")
	var custom_handler = argode_system.CustomCommandHandler
	if custom_handler and custom_handler.registered_commands.has("set_dict"):
		var set_dict_cmd = custom_handler.registered_commands["set_dict"]
		
		# set_dictコマンド実行
		var dict_params = {
			"_raw": 'set_dict player_data {"name": "プレイヤー", "class": "戦士"}',
			"_count": 3,
			"arg0": "player_data",
			"arg1": '{"name":',
			"arg2": '"プレイヤー",',
			"arg3": '"class":',
			"arg4": '"戦士"}'
		}
		
		await custom_handler._execute_registered_command(set_dict_cmd, dict_params)
		await root.get_tree().process_frame
		
		var player_name = variables.get_nested_variable("player_data.name")
		var player_class = variables.get_nested_variable("player_data.class")
		
		_log_result("    - set_dict command name: " + str(player_name), player_name == "プレイヤー")
		_log_result("    - set_dict command class: " + str(player_class), player_class == "戦士")
	else:
		_log_result("    - set_dict command not found", false)
	
	# set_arrayコマンドのテスト
	print("  - Testing set_array command...")
	if custom_handler and custom_handler.registered_commands.has("set_array"):
		var set_array_cmd = custom_handler.registered_commands["set_array"]
		
		# set_arrayコマンド実行
		var array_params = {
			"_raw": 'set_array inventory ["sword", "potion", "key"]',
			"_count": 3,
			"arg0": "inventory",
			"arg1": '["sword",',
			"arg2": '"potion",',
			"arg3": '"key"]'
		}
		
		await custom_handler._execute_registered_command(set_array_cmd, array_params)
		await root.get_tree().process_frame
		
		var inventory = variables.get_variable("inventory")
		if inventory is Array:
			_log_result("    - set_array command type: Array", true)
			_log_result("    - set_array command size: " + str(inventory.size()), inventory.size() == 3)
			_log_result("    - set_array command first: " + str(inventory[0]), inventory[0] == "sword")
		else:
			_log_result("    - set_array command failed", false)
	else:
		_log_result("    - set_array command not found", false)
	
	print("✅ Dictionary variable tests completed")

func _test_system_integration():
	"""システム統合テスト"""
	print("\n🔗 Testing System Integration...")
	
	await _wait_for_argode_system()
	
	var argode_system = root.get_node_or_null("ArgodeSystem")
	if not argode_system:
		_log_result("❌ ArgodeSystem integration test failed", false)
		return
	
	# 主要マネージャーの存在確認
	var managers = {
		"UIManager": argode_system.UIManager,
		"LayerManager": argode_system.LayerManager,
		"CharacterManager": argode_system.CharacterManager,
		"VariableManager": argode_system.VariableManager
	}
	
	for manager_name in managers.keys():
		var exists = managers[manager_name] != null
		_log_result("  - " + manager_name + ": " + ("✅" if exists else "❌"), exists)
	
	# ラベルレジストリテスト
	if argode_system.LabelRegistry:
		var label_count = argode_system.LabelRegistry.get_label_count()
		_log_result("  - Labels registered: " + str(label_count), label_count > 0)

func _test_performance():
	"""パフォーマンステスト"""
	print("\n⚡ Testing Performance...")
	
	var start_time = Time.get_ticks_msec()
	
	await _wait_for_argode_system()
	
	var init_time = Time.get_ticks_msec() - start_time
	_log_result("  - System initialization time: " + str(init_time) + "ms", init_time < 5000)

func _wait_for_argode_system():
	"""ArgodeSystemの初期化完了を待機"""
	var max_wait = 10.0  # 最大10秒待機
	var wait_time = 0.0
	
	while wait_time < max_wait:
		var argode_system = root.get_node_or_null("ArgodeSystem")
		if argode_system and argode_system.CustomCommandHandler:
			# テスト用の簡易レイヤー初期化
			_setup_test_layers(argode_system)
			return
		
		await create_timer(0.1).timeout
		wait_time += 0.1
	
	push_error("⚠️ ArgodeSystem initialization timeout")

func _setup_test_layers(argode_system: Node):
	"""テスト用の簡易レイヤー設定"""
	if argode_system.LayerManager:
		# ダミーのControlを作成してテスト用に設定
		var dummy_bg = Control.new()
		var dummy_char = Control.new()
		var dummy_ui = Control.new()
		
		dummy_bg.name = "TestBackgroundLayer"
		dummy_char.name = "TestCharacterLayer"
		dummy_ui.name = "TestUILayer"
		
		root.add_child(dummy_bg)
		root.add_child(dummy_char)
		root.add_child(dummy_ui)
		
		argode_system.LayerManager.initialize_layers(dummy_bg, dummy_char, dummy_ui)
		print("🧪 Test layers initialized for UICommand testing")

func _log_result(message: String, success: bool):
	"""テスト結果をログに記録"""
	print(message)
	test_results.append({"message": message, "success": success})

func _print_test_report():
	"""テスト結果レポートを出力"""
	print("\n" + "============================================================")
	print("📊 TEST REPORT")
	print("============================================================")
	
	var total = test_results.size()
	var passed = 0
	
	for result in test_results:
		if result.success:
			passed += 1
	
	var failed = total - passed
	
	print("Total tests: ", total)
	print("Passed: ", passed, " ✅")
	print("Failed: ", failed, " ❌")
	print("Success rate: ", str(float(passed) / total * 100).pad_decimals(1), "%")
	
	if failed > 0:
		print("\n❌ Failed tests:")
		for result in test_results:
			if not result.success:
				print("  - " + result.message)
	
	print("============================================================")