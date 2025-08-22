extends Node

func _ready():
	print("🧪 InputMap Test Starting...")
	
	# ArgodeSystem準備完了を待つ
	if not ArgodeSystem.is_system_ready:
		await ArgodeSystem.system_ready
	
	# Controller取得
	var controller = ArgodeSystem.Controller
	if not controller:
		print("❌ Controller not found")
		return
	
	print("✅ Controller found")
	
	# InputMapの状態をチェック
	controller.debug_print_input_map()
	
	# 簡単なメッセージを表示して入力をテスト
	print("🎮 Input Test: Click or press Space/Enter to test input")
	ArgodeSystem.play("test_all_command")

func _input(event):
	if event is InputEventMouseButton:
		print("�️ Mouse event detected: ", event.button_index, " pressed=", event.pressed)
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			print("✅ LEFT CLICK detected by main scene!")
	elif event is InputEventKey:
		if event.pressed:
			print("⌨️ Key event detected: ", event.keycode, " (", OS.get_keycode_string(event.keycode), ")")