# Simple test script to verify BaseAdvGameUI functionality
extends Node

func _ready():
	print("Testing BaseAdvGameUI availability...")
	
	# Try to instantiate BaseAdvGameUI
	var base_ui_scene = load("res://addons/adv_engine/ui/BaseAdvGameUI.tscn")
	if base_ui_scene:
		print("✅ BaseAdvGameUI.tscn loaded successfully")
		var base_ui_instance = base_ui_scene.instantiate()
		if base_ui_instance:
			print("✅ BaseAdvGameUI instantiated successfully")
			print("  Class name: ", base_ui_instance.get_class())
			if base_ui_instance.get_script():
				print("  Script global name: ", base_ui_instance.get_script().get_global_name())
		else:
			print("❌ Failed to instantiate BaseAdvGameUI")
	else:
		print("❌ Failed to load BaseAdvGameUI.tscn")