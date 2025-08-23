extends Node

func _ready():
	print("🧪 Call/Return Simple Design Test Starting...")
	
	# ArgodeSystem準備完了を待つ
	if not ArgodeSystem.is_system_ready:
		print("⏳ Waiting for ArgodeSystem...")
		await ArgodeSystem.system_ready
	
	
	# ArgodeSystem.play()でシナリオを開始（ラベル名を指定）
	ArgodeSystem.play("test_start")
	# print("✅ Scenario started successfully")
	
	# # テスト完了まで少し待つ
	# await get_tree().create_timer(10.0).timeout
	# print("🎉 Call/Return test completed")
	# get_tree().quit()