# TestControlScene.gd
extends Control

func _ready():
	print("🎬 Test Control Scene loaded")
	
	# Closeボタンの処理
	var close_button = $Panel/VBoxContainer/CloseButton
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

func _on_close_pressed():
	print("🎬 Closing Test Control Scene")
	queue_free()
