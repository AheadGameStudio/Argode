extends SceneTree

func _init():
	print("🎵 Testing Audio Commands...")
	
	# ArgodeSystemを直接作成してテスト
	var argode_scene = preload("res://addons/argode/core/ArgodeSystem.gd").new()
	root.add_child(argode_scene)
	
	# 少し待ってから初期化完了を確認
	await process_frame
	await process_frame
	
	print("🔊 Testing audio definitions...")
	# AudioDefinitionManagerを取得してテスト
	var audio_defs = argode_scene.get_node("AudioDefinitionManager")
	if audio_defs:
		print("✅ AudioDefinitionManager found")
		print("🎵 yoru_no_zattou path:", audio_defs.get_audio_path("yoru_no_zattou"))
		print("🔊 keyword_ping path:", audio_defs.get_audio_path("keyword_ping"))
	else:
		print("❌ AudioDefinitionManager not found")
	
	print("🔊 Testing BGM command...")
	# AudioManagerを取得してBGMコマンドをテスト
	var audio_manager = argode_scene.get_node("AudioManager")
	if audio_manager:
		print("✅ AudioManager found")
		
		# BGMを再生
		var result = audio_manager.play_bgm("yoru_no_zattou", true, 0.8)
		print("🎵 BGM play result: ", result)
		
		# SEを再生
		var se_result = audio_manager.play_se("keyword_ping", 1.0)
		print("🔊 SE play result: ", se_result)
		
	else:
		print("❌ AudioManager not found")
	
	# 終了
	print("🎯 Audio test completed")
	quit()
