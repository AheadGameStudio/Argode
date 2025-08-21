extends SceneTree

func _init():
	print("🎮 Starting JumpCommand test...")
	await _test_jump_command()
	print("✅ JumpCommand test completed")
	quit()

func _test_jump_command():
	# ArgodeSystemの初期化
	await ArgodeSystem._ready()
	
	# 好感度を低い値に設定
	ArgodeSystem.VariableManager.set_variable("player.affection", 1)
	
	# テストシナリオを読み込み実行
	var scenario_path = "res://examples/scenarios/debug_scenario/test_all_command.rgd"
	print("📄 Loading scenario: " + scenario_path)
	
	var success = await ArgodeSystem.StatementManager.play_from_label("test_all_command")
	if success:
		print("✅ Scenario execution started successfully")
	else:
		print("❌ Failed to start scenario execution")
