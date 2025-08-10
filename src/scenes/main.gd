extends Control

@onready var adv_ui = $AdvGameUI  # AdvGameUI instance (v2 AdvScreen-based)

func _ready():
	print("🎮 MainScene started with v2 AdvGameUI (AdvScreen-based)")
	print("💡 AdvGameUI will automatically start 'v2_test.rgd' from 'v2_test_start' label")
	
	# AdvGameUIが自動でスクリプトを開始するので、手動処理は不要
	# 必要に応じてスクリプトパスを変更可能：
	# adv_ui.set_script_path("res://scenarios/custom.rgd", "custom_start")

func _unhandled_input(event):
	# AdvGameUI (v2) が入力処理を自動で行うため、main.gdでは特別な処理は不要
	# ADVエンジンとUIの連携はAdvGameUIが自動で処理します
	
	# 必要に応じてカスタム入力処理を追加可能
	if event.is_action_pressed("ui_cancel"):
		print("🚪 Escape pressed - could implement game menu here")
	
	# デバッグ用：Rキーでスクリプトを再開始
	if event.is_action_pressed("ui_select") and Input.is_action_pressed("ui_cancel"):
		print("🔄 Restarting script from beginning")
		var adv_system = get_node("/root/ArgodeSystem")
		if not adv_system or not adv_system.Player:
			push_error("❌ ArgodeSystem.Player not available for restart")
			return
		
		adv_system.Player.play_from_label("v2_test_start")
