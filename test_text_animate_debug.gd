extends SceneTree

func _init():
	print("🔧 Starting text_animate debug test...")
	
	# ArgodeSystemを取得
	var argode_system = get_first_node_in_group("argode_system")
	if not argode_system:
		argode_system = get_node_or_null("/root/ArgodeSystem")
	
	if argode_system:
		print("✅ Found ArgodeSystem:", argode_system.name)
		
		# ベースUIファイルでテスト用シナリオを実行
		var ui_scene = preload("res://src/scenes/gui/usage_sample.tscn").instantiate()
		current_scene.add_child(ui_scene)
		
		# スクリプト実行
		argode_system.play_script("res://scenarios/tests/simple_custom_test.rgd", "simple_custom_test_start")
		
		# 1秒待機してからtext_animateコマンドをテスト
		await create_timer(1.0).timeout
		
		print("🎭 Testing text_animate command...")
		var params = {"effect": "shake", "intensity": 2.0, "duration": 1.0}
		
		# TextAnimateCommandのインスタンスを作成してテスト
		var text_animate_cmd = preload("res://custom/commands/TextAnimateCommand.gd").new()
		text_animate_cmd.execute_visual_effect(params, ui_scene)
		
	else:
		print("❌ ArgodeSystem not found")
	
	# テスト完了
	await create_timer(2.0).timeout
	quit()