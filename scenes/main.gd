extends Node

func _ready():
	print("🧪 Call/Return Simple Design Test Starting...")
	
	# ArgodeSystem準備完了を待つ
	if not ArgodeSystem.is_system_ready:
		print("⏳ Waiting for ArgodeSystem...")
		await ArgodeSystem.system_ready
	
	print("✅ ArgodeSystem ready")
	
	# デバッグ情報を出力
	print("🔍 Debug: ArgodeSystem.StatementManager = ", ArgodeSystem.StatementManager)
	print("🔍 Debug: ArgodeSystem.CommandRegistry = ", ArgodeSystem.get_service("CommandRegistry"))
	
	# Call/Returnテスト用シナリオを実行
	print("🎯 Starting scenario: test_simple_call")
	
	# ArgodeSystem.play()でシナリオを開始（ラベル名を指定）
	ArgodeSystem.play("start")
	print("✅ Scenario started successfully")
	
	# テスト完了まで少し待つ
	await get_tree().create_timer(10.0).timeout
	print("🎉 Call/Return test completed")
	get_tree().quit()