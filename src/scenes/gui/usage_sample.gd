extends Node2D

@onready var ui = $AdvGameUI  # AdvGameUI (v2 AdvScreen-based)

func _ready():
	print("🎮 Usage Sample Scene started (v2 AdvScreen)")
	
	# v2では自動でUIManagerとの連携が設定されます
	# 手動での setup_ui_manager_integration() 呼び出しは不要
	
	# Wait a bit for initialization
	await get_tree().process_frame
	
	# デモメッセージを表示
	show_demo_sequence()

func show_demo_sequence():
	"""デモ用のメッセージシーケンスを表示"""
	print("🎮 Demo sequence disabled - AdvGameUI auto-script will run instead")
	
	# デモメッセージを無効化 - AdvGameUIの自動スクリプト機能に任せる
	# ui.show_message("システム", "UIサンプルデモです。\\n• EnterキーまたはSpaceキー: タイプライター中=スキップ、完了後=新しいメッセージを表示", Color.CYAN)

func show_demo_choices():
	"""デモ用の選択肢を表示"""
	var choices = [
		"UIの色を変える",
		"メッセージを再表示",
		"ADVエンジンをテスト"
	]
	ui.show_choices(choices)
	
	# 選択肢が選ばれるまで待機（実際は自動処理）
	print("📝 Demo choices displayed. Press number keys 1-3 to select.")

func _unhandled_input(event):
	"""デモ用の入力処理"""
	# AdvGameUIの入力処理を呼び出し
	ui._unhandled_input(event)
	
	# AdvGameUIでイベントが処理されたかチェック
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		# タイプライター中の場合はAdvGameUIで処理済みなのでここでは何もしない
		if ui.typewriter and ui.typewriter.is_typing_active():
			print("⚠️ Usage Sample: Typewriter is active - handled by AdvGameUI")
			return
		
		# メッセージ完了後のみ新しいメッセージを表示
		if ui.is_message_complete:
			var key_name = "Enter" if event.is_action_pressed("ui_accept") else "Space"
			print("✅ Usage Sample: Starting new message with ", key_name)
			ui.show_message("システム", "[color=cyan]" + key_name + "キーが押されました！[/color]\\nEnterとSpaceキーが同じ動作になりました。\\n改行も正常に動作します。", Color.CYAN)
	
	# 選択肢のテスト
	if ui.choice_container.visible and event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: 
				handle_demo_choice(0)
			KEY_2: 
				handle_demo_choice(1)
			KEY_3: 
				handle_demo_choice(2)

func handle_demo_choice(choice_index: int):
	"""デモ選択肢の処理"""
	ui.choice_container.visible = false
	
	match choice_index:
		0:  # UIの色を変える
			change_ui_style()
		1:  # メッセージを再表示
			ui.show_message("システム", "メッセージが再表示されました！", Color.GREEN)
		2:  # ADVエンジンをテスト
			start_adv_engine_test()

func change_ui_style():
	"""UIスタイルを動的に変更するデモ"""
	ui.show_message("システム", "UIの背景色を変更します...", Color.YELLOW)
	
	# 背景色を変更
	var panel = ui.message_box.get_node("MessagePanel")
	if panel:
		var style = panel.get_theme_stylebox("panel").duplicate()
		style.bg_color = Color(0.2, 0.4, 0.6, 0.8)  # 青っぽい色に変更
		panel.add_theme_stylebox_override("panel", style)
	
	await get_tree().create_timer(2.0).timeout
	ui.show_message("システム", "[color=lightblue]背景色が変更されました！[/color]\\nこのようにUIは動的にカスタマイズできます。\\n複数行のテストも行えます。", Color.CYAN)

func start_adv_engine_test():
	"""実際のADVエンジンテスト"""
	ui.show_message("システム", "ADVエンジンのテストシナリオを開始します...", Color.ORANGE)
	
	await get_tree().create_timer(2.0).timeout
	
	# 実際のシナリオを実行 (v2)
	var adv_system = get_node("/root/AdvSystem")
	if adv_system and adv_system.Player:
		adv_system.start_script("res://scenarios/v2_test.rgd", "v2_test_start")
	else:
		ui.show_message("エラー", "AdvSystemが見つかりません", Color.RED)
