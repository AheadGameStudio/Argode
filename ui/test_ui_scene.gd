extends "res://addons/argode/ui/ArgodeUIScene.gd"

# UI統合テスト用スクリプト

func _ready():
	super._ready()
	print("TestUIScene: 初期化完了")

# ジャンプテスト
func _on_jump_button_pressed():
	print("TestUIScene: ジャンプボタンが押されました")
	# メインメニューのラベルにジャンプ
	execute_argode_command("jump", {"label": "main_menu"})
	close_self()

# コール呼び出しテスト
func _on_call_button_pressed():
	print("TestUIScene: コールボタンが押されました")
	# サンプルファイルを呼び出し
	execute_argode_command("call", {
		"label": "sample_start",
		"file": "res://scenarios/sample.rgd"
	})
	close_self()

# メッセージ表示テスト
func _on_message_button_pressed():
	print("TestUIScene: メッセージボタンが押されました")
	# メッセージウィンドウを表示して閉じる
	show_message_window()
	show_message("システム", "ArgodeUISceneからのメッセージテストです！")

# 選択肢表示テスト
func _on_choices_button_pressed():
	print("TestUIScene: 選択肢ボタンが押されました")
	var choices = ["選択肢A", "選択肢B", "選択肢C", "キャンセル"]
	var result = await show_choices(choices)
	
	match result:
		0:
			show_message("システム", "Aが選択されました")
		1:
			show_message("システム", "Bが選択されました")
		2:
			show_message("システム", "Cが選択されました")
		3:
			show_message("システム", "キャンセルされました")

# 変数操作テスト
func _on_variable_button_pressed():
	print("TestUIScene: 変数ボタンが押されました")
	
	# 変数を設定
	set_variable("test_var", "Hello from UI!")
	set_flag("ui_test_flag", true)
	
	# 変数を取得して表示
	var test_value = get_variable("test_var")
	var flag_value = is_flag_set("ui_test_flag")
	
	var message = "変数 test_var: " + str(test_value) + "\n"
	message += "フラグ ui_test_flag: " + str(flag_value)
	
	show_message("変数テスト", message)

# 閉じる
func _on_close_button_pressed():
	print("TestUIScene: 閉じるボタンが押されました")
	close_self()

# call_screenとしての使用例
func get_test_result():
	# 何らかの結果を返す
	var result = {
		"test_completed": true,
		"timestamp": Time.get_unix_time_from_system(),
		"message": "テスト完了！"
	}
	return_result(result)
