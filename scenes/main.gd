extends Node

func _ready():
	print("🎨 Stage 6: Rich Text System Test Starting...")
	
	# ArgodeSystem準備完了を待つ
	if not ArgodeSystem.is_system_ready:
		print("⏳ Waiting for ArgodeSystem...")
		await ArgodeSystem.system_ready
	
	print("✅ ArgodeSystem ready - starting Stage 6 Rich Text test")
	
	# Stage 6: リッチテキストテストを実行
	ArgodeSystem.play("start")
	print("✅ Stage 6 Rich Text test started successfully")
	
	# # テスト完了まで少し待つ
	# await get_tree().create_timer(10.0).timeout
	# print("🎉 Call/Return test completed")
	# get_tree().quit()