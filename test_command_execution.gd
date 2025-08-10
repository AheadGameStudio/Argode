extends SceneTree

func _init():
	print("🔧 Testing custom command execution...")
	
	# Wait for autoload initialization
	await create_timer(0.5).timeout
	
	# Get ArgodeSystem 
	var argode_system = root.get_node_or_null("ArgodeSystem")
	if not argode_system:
		print("❌ ArgodeSystem not found")
		quit()
		return
	
	print("✅ ArgodeSystem found")
	
	# Test 1: Get the text_animate command
	var custom_handler = argode_system.CustomCommandHandler
	if not custom_handler:
		print("❌ CustomCommandHandler not found") 
		quit()
		return
	
	print("✅ CustomCommandHandler found")
	print("📋 Available commands:", custom_handler.registered_commands.keys())
	
	# Test 2: Execute text_animate command directly
	if custom_handler.registered_commands.has("text_animate"):
		print("🎯 Testing text_animate command...")
		var text_animate_cmd = custom_handler.registered_commands["text_animate"]
		
		# Create test parameters
		var params = {"effect": "shake", "intensity": 2.0, "duration": 1.0}
		
		# Validate parameters
		if text_animate_cmd.validate_parameters(params):
			print("✅ Parameters validated")
			
			# Test visual effect execution with null UI (to see debug output)
			print("🔍 Testing visual effect execution...")
			text_animate_cmd.execute_visual_effect(params, null)
			
		else:
			print("❌ Parameter validation failed")
	else:
		print("❌ text_animate command not found")
	
	# Test 3: Test ui_slide command 
	if custom_handler.registered_commands.has("ui_slide"):
		print("🎯 Testing ui_slide command...")
		var ui_slide_cmd = custom_handler.registered_commands["ui_slide"]
		var params = {"action": "in", "direction": "up", "duration": 0.7}
		
		if ui_slide_cmd.validate_parameters(params):
			print("✅ ui_slide parameters validated")
		else:
			print("❌ ui_slide parameter validation failed")
	
	# Test 4: Test tint command
	if custom_handler.registered_commands.has("tint"):
		print("🎯 Testing tint command...")  
		var tint_cmd = custom_handler.registered_commands["tint"]
		var params = {"color": "red", "intensity": 0.5, "duration": 1.0}
		
		if tint_cmd.validate_parameters(params):
			print("✅ tint parameters validated")
			# Execute the effect
			tint_cmd.execute(params, argode_system)
		else:
			print("❌ tint parameter validation failed")
	
	print("🏁 Command execution test completed")
	
	# Wait a bit to see any async output
	await create_timer(2.0).timeout
	quit()