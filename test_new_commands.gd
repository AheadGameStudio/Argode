extends SceneTree

func _init():
	print("🔧 Testing new custom commands with debug output...")
	
	# Wait for initialization
	await create_timer(1.0).timeout
	
	# Load main scene to have proper UI
	var main_scene = preload("res://src/scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	
	await create_timer(0.5).timeout  
	
	# Get ArgodeSystem
	var argode_system = root.get_node_or_null("ArgodeSystem")
	
	if argode_system and argode_system.has_method("play_script"):
		print("✅ Found ArgodeSystem with UI")
		
		# Directly execute text_animate_test 
		argode_system.play_script("res://scenarios/text_animate_test.rgd", "text_animate_test_start")
		
		# Wait for execution to complete
		await create_timer(15.0).timeout
		
	else:
		print("❌ ArgodeSystem not found")
	
	quit()