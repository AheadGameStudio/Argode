#!/usr/bin/env -S godot --headless --script
# 辞書型変数機能専用テストランナー
# 使用方法: godot --headless --script tools/dict_test.gd --quit

extends SceneTree

var test_results: Array = []

func _init():
	print("📚 Dictionary Variable Feature Test")
	print("============================================================")
	
	# テスト実行
	await _test_dictionary_variables()
	
	# 結果レポート
	_print_test_report()
	
	quit()

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
		
		# set_dictコマンド実行用のパラメータを準備
		var dict_literal = '{"name": "プレイヤー", "class": "戦士"}'
		var dict_params = {
			"_raw": "set_dict player_data " + dict_literal,
			"_count": 2,
			"arg0": "player_data",
			"arg1": dict_literal
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
		
		# set_arrayコマンド実行用のパラメータを準備
		var array_literal = '["sword", "potion", "key"]'
		var array_params = {
			"_raw": "set_array inventory " + array_literal,
			"_count": 2,
			"arg0": "inventory",
			"arg1": array_literal
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

func _wait_for_argode_system():
	"""ArgodeSystemの初期化完了を待機"""
	var max_wait = 10.0  # 最大10秒待機
	var wait_time = 0.0
	
	while wait_time < max_wait:
		var argode_system = root.get_node_or_null("ArgodeSystem")
		if argode_system and argode_system.CustomCommandHandler:
			return
		
		await create_timer(0.1).timeout
		wait_time += 0.1
	
	push_error("⚠️ ArgodeSystem initialization timeout")

func _log_result(message: String, success: bool):
	"""テスト結果をログに記録"""
	print(message)
	test_results.append({"message": message, "success": success})

func _print_test_report():
	"""テスト結果レポートを出力"""
	print("\n" + "============================================================")
	print("📊 DICTIONARY TEST REPORT")
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
