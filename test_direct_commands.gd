extends SceneTree

var test_complete = false

func _init():
	print("🔧 Direct command test starting...")
	
	# Connect to tree ready to ensure autoloads are available
	await process_frame
	await process_frame  # Extra frame to ensure initialization
	
	_run_tests()

func _run_tests():
	print("🚀 Running direct tests...")
	
	# Get ArgodeSystem directly from autoload
	var argode_system = root.get_node_or_null("ArgodeSystem")
	if not argode_system:
		print("❌ ArgodeSystem autoload not found")
		quit()
		return
	
	print("✅ ArgodeSystem found:", argode_system.name)
	
	# Check if CustomCommandHandler exists
	if not argode_system.CustomCommandHandler:
		print("❌ CustomCommandHandler not found")
		quit()
		return
	
	var handler = argode_system.CustomCommandHandler
	print("✅ CustomCommandHandler found")
	print("📋 Registered commands:", handler.registered_commands.keys())
	
	# Test text_animate command
	if handler.registered_commands.has("text_animate"):
		print("\n🎯 Testing text_animate command...")
		var cmd = handler.registered_commands["text_animate"]
		
		print("  - Command name:", cmd.command_name)
		print("  - Has visual effect:", cmd.has_visual_effect())
		print("  - Description:", cmd.description)
		
		# Test parameter validation  
		var params = {"effect": "shake", "intensity": 2.0, "duration": 1.0}
		var valid = cmd.validate_parameters(params)
		print("  - Parameters valid:", valid)
		
		if valid:
			print("  - Testing execute_visual_effect with null UI...")
			# This should trigger the debug output we added
			cmd.execute_visual_effect(params, null)
	else:
		print("❌ text_animate command not registered")
	
	# Test ui_slide command
	if handler.registered_commands.has("ui_slide"):
		print("\n🎯 Testing ui_slide command...")  
		var cmd = handler.registered_commands["ui_slide"]
		var params = {"action": "in", "direction": "up", "duration": 0.7}
		print("  - Parameters valid:", cmd.validate_parameters(params))
	else:
		print("❌ ui_slide command not registered")
	
	# Test tint command
	if handler.registered_commands.has("tint"):
		print("\n🎯 Testing tint command...")
		var cmd = handler.registered_commands["tint"]
		var params = {"color": "red", "intensity": 0.5, "duration": 1.0}
		print("  - Parameters valid:", cmd.validate_parameters(params))
	else:
		print("❌ tint command not registered")
	
	print("\n🏁 Direct command tests completed")
	test_complete = true
	
	# Wait a moment then quit
	await create_timer(1.0).timeout
	quit()