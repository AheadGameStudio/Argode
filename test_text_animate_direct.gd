extends SceneTree

func _init():
	print("🔧 Direct text_animate test...")
	
	# Wait for initialization
	await create_timer(0.5).timeout
	
	# Get ArgodeSystem
	var argode_system = get_nodes_in_group("argode_system")
	if argode_system.is_empty():
		argode_system = [root.get_node_or_null("ArgodeSystem")]
	
	if argode_system[0] and argode_system[0].has_method("play_script"):
		print("✅ Found ArgodeSystem")
		
		# Start text_animate test scenario
		argode_system[0].play_script("res://scenarios/text_animate_test.rgd", "text_animate_test_start")
		
		# Wait for execution
		await create_timer(5.0).timeout
		
	else:
		print("❌ ArgodeSystem not found")
	
	quit()