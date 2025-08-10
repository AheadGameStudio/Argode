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
	# --script引数より後の引数のみ処理
	var script_index = -1
	for i in range(args.size()):
		if args[i] == "--script":
			script_index = i
			break
	
	if script_index >= 0 and script_index + 2 < args.size():
		# --script の後の次の引数（スクリプトパス）をスキップして、その後の引数を処理
		for i in range(script_index + 2, args.size()):
			if not args[i].begins_with("-"):
				test_name = args[i].to_lower()
				print("📋 Selected test: ", test_name)
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
		"performance", "perf":
			await _test_performance()
		"all":
			await _test_custom_commands()
			await _test_system_integration()
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