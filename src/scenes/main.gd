extends Node2D

@onready var adv_ui = $BaseAdvGameUI  # BaseAdvGameUI instance

func _ready():
	print("🎮 MainScene started with integrated BaseAdvGameUI")
	print("💡 BaseAdvGameUI will automatically start 'scene_test.rgd' from 'start' label")
	
	# BaseAdvGameUIが自動でスクリプトを開始するので、手動処理は不要
	# 必要に応じてスクリプトパスを変更可能：
	# adv_ui.set_script_path("res://scenarios/custom.rgd", "custom_start")

func _unhandled_input(event):
	# BaseAdvGameUIが入力処理を自動で行うため、main.gdでは特別な処理は不要
	# ADVエンジンとUIの連携はBaseAdvGameUIが自動で処理します
	
	# 必要に応じてカスタム入力処理を追加可能
	if event.is_action_pressed("ui_cancel"):
		print("🚪 Escape pressed - could implement game menu here")
	
	# デバッグ用：Rキーでスクリプトを再開始
	if event.is_action_pressed("ui_select") and Input.is_action_pressed("ui_cancel"):
		print("🔄 Restarting script from beginning")
		var script_player = get_node("/root/AdvScriptPlayer")
		if script_player:
			script_player.play_from_label("scene_test_start")
