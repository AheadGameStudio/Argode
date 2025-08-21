extends SceneTree

func _init():
	print("📞 Starting Call/Return command test...")
	await _test_call_return_command()
	print("✅ Call/Return command test completed")
	quit()

func _test_call_return_command():
	# ArgodeSystemの初期化
	await ArgodeSystem._ready()
	
	# テストシナリオを読み込み実行
	var scenario_path = "res://examples/scenarios/debug_scenario/test_call_return.rgd"
	print("📄 Loading scenario: " + scenario_path)
	
	var success = await ArgodeSystem.StatementManager.play_from_file(scenario_path)
	if success:
		print("✅ Scenario execution started successfully")
	else:
		print("❌ Failed to start scenario execution")
