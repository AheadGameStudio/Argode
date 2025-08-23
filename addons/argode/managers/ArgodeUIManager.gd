extends RefCounted
class_name ArgodeUIManager

# ===========================
# Service Layer Pattern Integration
# ===========================
var ui_service: RefCounted
var transition_service: RefCounted
var layer_service: RefCounted

# ===========================
# Core Properties
# ===========================
var ui_elements: Dictionary = {}
var layer_manager: ArgodeLayerManager
var gui_layer: Control
var active_ui_alias: String = ""

# Service Layer Pattern: UI state tracking
var ui_states: Dictionary = {}
var ui_animations: Dictionary = {}
var ui_transition_queue: Array = []

# ===========================
# Signals
# ===========================
signal is_shown_ui(instance: Control)
signal is_hidden_ui(instance: Control)
signal ui_transition_started(alias: String, transition_type: String)
signal ui_transition_completed(alias: String, transition_type: String)

func _init() -> void:
	_initialize_services()
	layer_manager = ArgodeSystem.LayerManager
	gui_layer = layer_manager.get_gui_layer()
	ArgodeSystem.log("📚ArgodeUIManager is ready", ArgodeSystem.LOG_LEVEL.WORKFLOW)

# ===========================
# Service Layer Pattern: Service Management
# ===========================
func _initialize_services() -> void:
	"""Initialize service layer connections."""
	if ArgodeSystem.is_system_ready:
		_connect_services()
	else:
		await ArgodeSystem.system_ready
		_connect_services()

func _connect_services() -> void:
	"""Connect to service layer instances."""
	ui_service = ArgodeSystem.get_service("UIService")
	transition_service = ArgodeSystem.get_service("TransitionService")
	layer_service = ArgodeSystem.get_service("LayerService")
	
	if ui_service:
		ui_service.ui_state_changed.connect(_on_ui_state_changed)
		ArgodeSystem.log("Connected to UIService", ArgodeSystem.LOG_LEVEL.DEBUG)
	
	if transition_service:
		transition_service.transition_completed.connect(_on_transition_completed)
		ArgodeSystem.log("Connected to TransitionService", ArgodeSystem.LOG_LEVEL.DEBUG)

func _on_ui_state_changed(ui_alias: String, state: Dictionary) -> void:
	"""Handle UI state changes from service layer."""
	ui_states[ui_alias] = state
	ArgodeSystem.log("UI state updated: %s" % ui_alias, ArgodeSystem.LOG_LEVEL.DEBUG)

func _on_transition_completed(transition_id: String, result: Dictionary) -> void:
	"""Handle transition completion from service layer."""
	_process_transition_queue()
	ArgodeSystem.log("UI transition completed: %s" % transition_id, ArgodeSystem.LOG_LEVEL.DEBUG)

# ===========================
# Enhanced UI Management
# ===========================
func add_ui(path: String, alias: String = "", z_index: int = 0, properties: Dictionary = {}) -> bool:
	"""
	Enhanced UI addition with service layer integration.
	
	Args:
		path: Path to the UI scene file
		alias: Optional alias for the UI (auto-generated if empty)
		z_index: Z-index for layering
		properties: Additional properties for UI configuration
	
	Returns:
		bool: True if UI was successfully added
	"""
	var ui_scene: PackedScene = load(path)
	if not ui_scene:
		ArgodeSystem.log("❌ Failed to load UI scene: " + path, ArgodeSystem.LOG_LEVEL.CRITICAL)
		return false
	
	var ui_instance = ui_scene.instantiate()
	if not ui_instance:
		ArgodeSystem.log("❌ Failed to instantiate UI: " + path, ArgodeSystem.LOG_LEVEL.CRITICAL)
		return false
	
	if alias.is_empty():
		alias = _generate_ui_alias(ui_instance)
	
	if ui_instance is not Control:
		ArgodeSystem.log("❌ UI is not a Control: " + path, ArgodeSystem.LOG_LEVEL.CRITICAL)
		ui_instance.queue_free()
		return false
	
	# Service Layer Pattern: Register UI with service
	if ui_service:
		var ui_config = {
			"path": path,
			"alias": alias,
			"z_index": z_index,
			"properties": properties
		}
		ui_service.register_ui(alias, ui_config)
	
	# Configure UI instance
	ui_elements[alias] = ui_instance
	ui_instance.z_index = z_index
	
	# Apply additional properties
	_apply_ui_properties(ui_instance, properties)
	
	# Add to GUI layer
	gui_layer.add_child(ui_instance)
	
	# Initialize UI state tracking
	ui_states[alias] = {
		"visible": ui_instance.visible,
		"z_index": z_index,
		"position": ui_instance.position,
		"size": ui_instance.size
	}
	
	ArgodeSystem.log("📥 Added UI: %s as %s" % [path, alias], ArgodeSystem.LOG_LEVEL.WORKFLOW)
	return true

func _generate_ui_alias(ui_instance: Control) -> String:
	"""Generate a unique alias for UI instance."""
	var rnd_seed: int = rand_from_seed(Time.get_ticks_msec())[0]
	return "ui_%s_%s" % [ui_instance.name, str(rnd_seed)]

func _apply_ui_properties(ui_instance: Control, properties: Dictionary) -> void:
	"""Apply custom properties to UI instance."""
	for property in properties:
		if ui_instance.has_method("set_" + property):
			ui_instance.call("set_" + property, properties[property])
		elif property in ui_instance:
			ui_instance.set(property, properties[property])

# ===========================
# Enhanced UI Retrieval and Management
# ===========================
func get_ui(alias: String) -> Control:
	"""
	Returns the UI instance with the given alias.
	
	Args:
		alias: The alias of the UI to retrieve
		
	Returns:
		Control: The UI instance or null if not found
	"""
	if not ui_elements.has(alias):
		ArgodeSystem.log("❌ UI not found: " + alias, ArgodeSystem.LOG_LEVEL.CRITICAL)
		return null
	return ui_elements[alias]

func get_message_window() -> Control:
	"""
	Returns the message window UI instance.
	
	Returns:
		Control: The message window instance or null if not found
	"""
	# Try common message window aliases
	var message_aliases = ["message", "message_window", "messageWindow"]
	
	for alias in message_aliases:
		if ui_elements.has(alias):
			return ui_elements[alias]
	
	# If no standard message window found, log debug info
	ArgodeSystem.log("❌ Message window not found. Available UIs: %s" % str(ui_elements.keys()), ArgodeSystem.LOG_LEVEL.DEBUG)
	return null

func get_message_renderer():
	"""
	Returns the message renderer instance.
	
	Returns:
		The message renderer instance or null if not found
	"""
	# Try to get from ArgodeSystem if available
	if ArgodeSystem.has_method("get_renderer"):
		var renderer = ArgodeSystem.get_renderer("message")
		if renderer:
			return renderer
	
	# Try direct property access
	if ArgodeSystem.has_method("MessageRenderer"):
		return ArgodeSystem.MessageRenderer
	
	# Check if there's a renderer property in ArgodeSystem
	if "MessageRenderer" in ArgodeSystem:
		return ArgodeSystem.MessageRenderer
	
	# If not found, log debug info
	ArgodeSystem.log("❌ Message renderer not found - メッセージレンダラーが見つかりません", ArgodeSystem.LOG_LEVEL.DEBUG)
	return null

func get_ui_state(alias: String) -> Dictionary:
	"""
	Get the current state of a UI instance.
	
	Args:
		alias: The alias of the UI
		
	Returns:
		Dictionary: Current UI state or empty dict if not found
	"""
	if not ui_states.has(alias):
		ArgodeSystem.log("❌ UI state not found: " + alias, ArgodeSystem.LOG_LEVEL.CRITICAL)
		return {}
	return ui_states[alias]

func update_ui_state(alias: String, state_updates: Dictionary) -> bool:
	"""
	Update the state of a UI instance.
	
	Args:
		alias: The alias of the UI
		state_updates: Dictionary of state updates to apply
		
	Returns:
		bool: True if state was updated successfully
	"""
	if not ui_elements.has(alias):
		ArgodeSystem.log("❌ UI not found for state update: " + alias, ArgodeSystem.LOG_LEVEL.CRITICAL)
		return false
	
	var ui_instance = ui_elements[alias]
	var current_state = ui_states.get(alias, {})
	
	for key in state_updates:
		current_state[key] = state_updates[key]
		
		# Apply state changes to UI instance
		match key:
			"visible":
				ui_instance.visible = state_updates[key]
			"z_index":
				ui_instance.z_index = state_updates[key]
			"position":
				ui_instance.position = state_updates[key]
			"size":
				ui_instance.size = state_updates[key]
	
	ui_states[alias] = current_state
	
	# Service Layer Pattern: Sync with service
	if ui_service:
		ui_service.update_ui_state(alias, current_state)
	
	ArgodeSystem.log("Updated UI state: %s" % alias, ArgodeSystem.LOG_LEVEL.DEBUG)
	return true

# ===========================
# Enhanced UI Display Control
# ===========================
func show_ui(alias: String, transition_type: String = "none", transition_duration: float = 0.0) -> bool:
	"""
	Enhanced UI show with transition support.
	
	Args:
		alias: The alias of the UI to show
		transition_type: Type of transition ("none", "fade", "slide", etc.)
		transition_duration: Duration of the transition in seconds
		
	Returns:
		bool: True if UI was shown successfully
	"""
	if not ui_elements.has(alias):
		ArgodeSystem.log("❌ UI not found: " + alias, ArgodeSystem.LOG_LEVEL.CRITICAL)
		return false
	
	var ui_instance = ui_elements[alias]
	
	# Service Layer Pattern: Notify service of show operation
	if ui_service:
		ui_service.prepare_ui_show(alias, transition_type, transition_duration)
	
	if transition_type == "none" or transition_duration <= 0.0:
		ui_instance.show()
		_update_ui_visibility_state(alias, true)
		is_shown_ui.emit(ui_instance)
	else:
		_show_ui_with_transition(alias, transition_type, transition_duration)
	
	ArgodeSystem.log("Showing UI: %s" % alias, ArgodeSystem.LOG_LEVEL.WORKFLOW)
	return true

func hide_ui(alias: String, transition_type: String = "none", transition_duration: float = 0.0) -> bool:
	"""
	Enhanced UI hide with transition support.
	
	Args:
		alias: The alias of the UI to hide
		transition_type: Type of transition ("none", "fade", "slide", etc.)
		transition_duration: Duration of the transition in seconds
		
	Returns:
		bool: True if UI was hidden successfully
	"""
	if not ui_elements.has(alias):
		ArgodeSystem.log("❌ UI not found: " + alias, ArgodeSystem.LOG_LEVEL.CRITICAL)
		return false
	
	var ui_instance = ui_elements[alias]
	
	# Service Layer Pattern: Notify service of hide operation
	if ui_service:
		ui_service.prepare_ui_hide(alias, transition_type, transition_duration)
	
	if transition_type == "none" or transition_duration <= 0.0:
		ui_instance.hide()
		_update_ui_visibility_state(alias, false)
		is_hidden_ui.emit(ui_instance)
	else:
		_hide_ui_with_transition(alias, transition_type, transition_duration)
	
	ArgodeSystem.log("Hiding UI: %s" % alias, ArgodeSystem.LOG_LEVEL.WORKFLOW)
	return true

func _show_ui_with_transition(alias: String, transition_type: String, duration: float) -> void:
	"""Handle UI show with transition effects."""
	ui_transition_started.emit(alias, "show_" + transition_type)
	
	if transition_service:
		var transition_config = {
			"type": transition_type,
			"duration": duration,
			"target": ui_elements[alias],
			"operation": "show"
		}
		transition_service.start_ui_transition(alias, transition_config)
	else:
		# Fallback: Simple show without transition
		ui_elements[alias].show()
		_update_ui_visibility_state(alias, true)
		is_shown_ui.emit(ui_elements[alias])

func _hide_ui_with_transition(alias: String, transition_type: String, duration: float) -> void:
	"""Handle UI hide with transition effects."""
	ui_transition_started.emit(alias, "hide_" + transition_type)
	
	if transition_service:
		var transition_config = {
			"type": transition_type,
			"duration": duration,
			"target": ui_elements[alias],
			"operation": "hide"
		}
		transition_service.start_ui_transition(alias, transition_config)
	else:
		# Fallback: Simple hide without transition
		ui_elements[alias].hide()
		_update_ui_visibility_state(alias, false)
		is_hidden_ui.emit(ui_elements[alias])

func _update_ui_visibility_state(alias: String, visible: bool) -> void:
	"""Update UI visibility state tracking."""
	if alias in ui_states:
		ui_states[alias]["visible"] = visible

# ===========================
# Enhanced UI Removal
# ===========================
func delete_ui(alias: String) -> bool:
	"""
	Enhanced UI deletion with service layer cleanup.
	
	Args:
		alias: The alias of the UI to delete
		
	Returns:
		bool: True if UI was deleted successfully
	"""
	if not ui_elements.has(alias):
		ArgodeSystem.log("❌ UI not found: " + alias, ArgodeSystem.LOG_LEVEL.CRITICAL)
		return false
	
	var ui_instance = ui_elements[alias]
	
	# Service Layer Pattern: Unregister from service
	if ui_service:
		ui_service.unregister_ui(alias)
	
	# Clean up state tracking
	ui_states.erase(alias)
	if alias in ui_animations:
		ui_animations.erase(alias)
	
	# Remove from elements and queue for deletion
	ui_elements.erase(alias)
	ui_instance.queue_free()
	
	ArgodeSystem.log("Deleted UI: %s" % alias, ArgodeSystem.LOG_LEVEL.WORKFLOW)
	return true

# ===========================
# Enhanced Z-Index Management
# ===========================
func change_z_index(alias: String, z_index: int) -> bool:
	"""
	Enhanced z-index management with state tracking.
	
	Args:
		alias: The alias of the UI
		z_index: New z-index value
		
	Returns:
		bool: True if z-index was changed successfully
	"""
	if not ui_elements.has(alias):
		ArgodeSystem.log("❌ UI not found: " + alias, ArgodeSystem.LOG_LEVEL.CRITICAL)
		return false
	
	var ui_instance = ui_elements[alias]
	ui_instance.z_index = z_index
	
	# Update state tracking
	update_ui_state(alias, {"z_index": z_index})
	
	ArgodeSystem.log("Changed z-index for %s to %d" % [alias, z_index], ArgodeSystem.LOG_LEVEL.DEBUG)
	return true

func set_front(alias: String) -> bool:
	"""
	Enhanced front positioning with sticky front support.
	
	Args:
		alias: The alias of the UI to bring to front
		
	Returns:
		bool: True if UI was moved to front successfully
	"""
	if not ui_elements.has(alias):
		ArgodeSystem.log("❌ UI not found: " + alias, ArgodeSystem.LOG_LEVEL.CRITICAL)
		return false
	
	var ui_instance = ui_elements[alias]
	
	if ui_instance.get("is_sticky_front") and ui_instance.is_sticky_front:
		ArgodeSystem.log("ℹ️ UI '%s' is sticky front, skipping z-index adjustment." % alias, ArgodeSystem.LOG_LEVEL.DEBUG)
		return false
	
	# Calculate new z-index position
	var max_z_index = _get_max_z_index()
	change_z_index(alias, max_z_index + 1)
	
	# Service Layer Pattern: Notify layer service
	if layer_service:
		layer_service.ui_moved_to_front(alias, max_z_index + 1)
	
	ArgodeSystem.log("Moved UI to front: %s" % alias, ArgodeSystem.LOG_LEVEL.DEBUG)
	return true

func set_back(alias: String) -> bool:
	"""
	Enhanced back positioning with sticky back support.
	
	Args:
		alias: The alias of the UI to send to back
		
	Returns:
		bool: True if UI was moved to back successfully
	"""
	if not ui_elements.has(alias):
		ArgodeSystem.log("❌ UI not found: " + alias, ArgodeSystem.LOG_LEVEL.CRITICAL)
		return false
	
	var ui_instance = ui_elements[alias]
	
	if ui_instance.get("is_sticky_back") and ui_instance.is_sticky_back:
		ArgodeSystem.log("ℹ️ UI '%s' is sticky back, skipping z-index adjustment." % alias, ArgodeSystem.LOG_LEVEL.DEBUG)
		return false
	
	# Calculate new z-index position
	var min_z_index = _get_min_z_index()
	change_z_index(alias, min_z_index - 1)
	
	# Service Layer Pattern: Notify layer service
	if layer_service:
		layer_service.ui_moved_to_back(alias, min_z_index - 1)
	
	ArgodeSystem.log("Moved UI to back: %s" % alias, ArgodeSystem.LOG_LEVEL.DEBUG)
	return true

func _get_max_z_index() -> int:
	"""Get the maximum z-index among all UI elements."""
	var max_z = -1
	for child in gui_layer.get_children():
		if child.z_index > max_z:
			max_z = child.z_index
	return max_z

func _get_min_z_index() -> int:
	"""Get the minimum z-index among all UI elements."""
	var min_z = 1
	for child in gui_layer.get_children():
		if child.z_index < min_z:
			min_z = child.z_index
	return min_z

# ===========================
# Enhanced Layer Swapping
# ===========================
func bring_to_front(alias: String) -> bool:
	"""
	Enhanced front movement with state validation.
	
	Args:
		alias: The alias of the UI to bring forward
		
	Returns:
		bool: True if UI was moved forward successfully
	"""
	if not ui_elements.has(alias):
		ArgodeSystem.log("❌ UI not found: " + alias, ArgodeSystem.LOG_LEVEL.CRITICAL)
		return false
	
	var ui_instance = ui_elements[alias]
	
	if ui_instance.get("is_sticky_front") and ui_instance.is_sticky_front:
		ArgodeSystem.log("ℹ️ UI '%s' is sticky front, skipping z-index adjustment." % alias, ArgodeSystem.LOG_LEVEL.DEBUG)
		return false
	
	# Find the UI element directly in front
	var current_z = ui_instance.z_index
	var target_z = current_z + 1
	
	for child in gui_layer.get_children():
		if child.z_index == target_z:
			child.z_index = current_z
			break
	
	ui_instance.z_index = target_z
	update_ui_state(alias, {"z_index": target_z})
	
	ArgodeSystem.log("Brought UI forward: %s" % alias, ArgodeSystem.LOG_LEVEL.DEBUG)
	return true

func bring_to_back(alias: String) -> bool:
	"""
	Enhanced back movement with state validation.
	
	Args:
		alias: The alias of the UI to bring backward
		
	Returns:
		bool: True if UI was moved backward successfully
	"""
	if not ui_elements.has(alias):
		ArgodeSystem.log("❌ UI not found: " + alias, ArgodeSystem.LOG_LEVEL.CRITICAL)
		return false
	
	var ui_instance = ui_elements[alias]
	
	if ui_instance.get("is_sticky_back") and ui_instance.is_sticky_back:
		ArgodeSystem.log("ℹ️ UI '%s' is sticky back, skipping z-index adjustment." % alias, ArgodeSystem.LOG_LEVEL.DEBUG)
		return false
	
	# Find the UI element directly behind
	var current_z = ui_instance.z_index
	var target_z = current_z - 1
	
	for child in gui_layer.get_children():
		if child.z_index == target_z:
			child.z_index = current_z
			break
	
	ui_instance.z_index = target_z
	update_ui_state(alias, {"z_index": target_z})
	
	ArgodeSystem.log("Brought UI backward: %s" % alias, ArgodeSystem.LOG_LEVEL.DEBUG)
	return true

# ===========================
# Enhanced Utility Functions
# ===========================
func get_all_ui() -> Dictionary:
	"""
	Returns all UI elements managed by the UI manager.
	
	Returns:
		Dictionary: All managed UI elements
	"""
	return ui_elements

func has_ui(alias: String) -> bool:
	"""
	Enhanced UI existence check with state validation.
	
	Args:
		alias: The alias to check
		
	Returns:
		bool: True if UI exists and is properly managed
	"""
	return ui_elements.has(alias) and ui_states.has(alias)

func get_ui_count() -> int:
	"""
	Get the total number of managed UI elements.
	
	Returns:
		int: Number of UI elements
	"""
	return ui_elements.size()

func get_visible_ui_count() -> int:
	"""
	Get the number of currently visible UI elements.
	
	Returns:
		int: Number of visible UI elements
	"""
	var count = 0
	for alias in ui_states:
		if ui_states[alias].get("visible", false):
			count += 1
	return count

# ===========================
# Service Layer Pattern: Transition Queue Management
# ===========================
func queue_ui_transition(alias: String, transition_config: Dictionary) -> bool:
	"""
	Queue a UI transition for sequential execution.
	
	Args:
		alias: The alias of the UI
		transition_config: Configuration for the transition
		
	Returns:
		bool: True if transition was queued successfully
	"""
	if not ui_elements.has(alias):
		ArgodeSystem.log("❌ Cannot queue transition for unknown UI: " + alias, ArgodeSystem.LOG_LEVEL.CRITICAL)
		return false
	
	var transition_entry = {
		"alias": alias,
		"config": transition_config,
		"timestamp": Time.get_ticks_msec()
	}
	
	ui_transition_queue.append(transition_entry)
	
	if ui_transition_queue.size() == 1:
		_process_transition_queue()
	
	ArgodeSystem.log("Queued UI transition: %s" % alias, ArgodeSystem.LOG_LEVEL.DEBUG)
	return true

func _process_transition_queue() -> void:
	"""Process the next transition in the queue."""
	if ui_transition_queue.is_empty():
		return
	
	var next_transition = ui_transition_queue[0]
	ui_transition_queue.remove_at(0)
	
	var alias = next_transition["alias"]
	var config = next_transition["config"]
	
	# Execute the transition based on config
	var operation = config.get("operation", "show")
	var transition_type = config.get("type", "none")
	var duration = config.get("duration", 0.0)
	
	match operation:
		"show":
			show_ui(alias, transition_type, duration)
		"hide":
			hide_ui(alias, transition_type, duration)
		_:
			ArgodeSystem.log("❌ Unknown transition operation: %s" % operation, ArgodeSystem.LOG_LEVEL.CRITICAL)

# ===========================
# Service Layer Pattern: Public API Compatibility
# ===========================
func get_active_ui_alias() -> String:
	"""Get the currently active UI alias."""
	return active_ui_alias

func set_active_ui_alias(alias: String) -> bool:
	"""
	Set the active UI alias.
	
	Args:
		alias: The alias to set as active
		
	Returns:
		bool: True if alias was set successfully
	"""
	if not ui_elements.has(alias):
		ArgodeSystem.log("❌ Cannot set unknown UI as active: " + alias, ArgodeSystem.LOG_LEVEL.CRITICAL)
		return false
	
	active_ui_alias = alias
	
	# Service Layer Pattern: Notify service of active UI change
	if ui_service:
		ui_service.set_active_ui(alias)
	
	ArgodeSystem.log("Set active UI: %s" % alias, ArgodeSystem.LOG_LEVEL.DEBUG)
	return true

func clear_all_ui() -> void:
	"""Clear all managed UI elements."""
	for alias in ui_elements.keys():
		delete_ui(alias)
	
	ui_transition_queue.clear()
	active_ui_alias = ""
	
	ArgodeSystem.log("Cleared all UI elements", ArgodeSystem.LOG_LEVEL.WORKFLOW)

# ===========================
# Service Layer Pattern: Batch Operations
# ===========================
func show_multiple_ui(aliases: Array, transition_type: String = "none", stagger_delay: float = 0.0) -> bool:
	"""
	Show multiple UI elements with optional staggered timing.
	
	Args:
		aliases: Array of UI aliases to show
		transition_type: Type of transition to apply
		stagger_delay: Delay between each UI show in seconds
		
	Returns:
		bool: True if all UIs were processed successfully
	"""
	var success = true
	
	for i in range(aliases.size()):
		var alias = aliases[i]
		var delay = stagger_delay * i
		
		if delay > 0.0:
			if ArgodeSystem.tree:
				await ArgodeSystem.tree.create_timer(delay).timeout
		
		if not show_ui(alias, transition_type):
			success = false
	
	return success

func hide_multiple_ui(aliases: Array, transition_type: String = "none", stagger_delay: float = 0.0) -> bool:
	"""
	Hide multiple UI elements with optional staggered timing.
	
	Args:
		aliases: Array of UI aliases to hide
		transition_type: Type of transition to apply
		stagger_delay: Delay between each UI hide in seconds
		
	Returns:
		bool: True if all UIs were processed successfully
	"""
	var success = true
	
	for i in range(aliases.size()):
		var alias = aliases[i]
		var delay = stagger_delay * i
		
		if delay > 0.0:
			if ArgodeSystem.tree:
				await ArgodeSystem.tree.create_timer(delay).timeout
		
		if not hide_ui(alias, transition_type):
			success = false
	
	return success

# ===========================
# Message Display Functions (for SayCommand compatibility)
# ===========================
func show_message(text: String, character_name: String = "", properties: Dictionary = {}) -> void:
	"""
	Display a message in the message window.
	Compatible with SayCommand requirements.
	
	Args:
		text: The message text to display
		character_name: Optional character name
		properties: Additional display properties
	"""
	var message_window = get_message_window()
	if not message_window:
		ArgodeSystem.log("❌ Cannot show message: Message window not found", ArgodeSystem.LOG_LEVEL.CRITICAL)
		return
	
	var message_renderer = get_message_renderer()
	if message_renderer and message_renderer.has_method("display_message"):
		message_renderer.display_message(text, character_name, properties)
	elif message_window.has_method("display_message"):
		message_window.display_message(text, character_name, properties)
	elif message_window.has_method("set_text"):
		# Basic text display fallback
		message_window.set_text(text)
	else:
		ArgodeSystem.log("❌ Message window lacks display capabilities", ArgodeSystem.LOG_LEVEL.CRITICAL)
	
	# Ensure message window is visible
	show_ui("message")
	
	ArgodeSystem.log("📝 Message displayed: %s" % text, ArgodeSystem.LOG_LEVEL.DEBUG)

func wait_for_input() -> void:
	"""
	Wait for user input to continue.
	Compatible with SayCommand requirements.
	Uses ArgodeController for unified input management.
	"""
	# Check if ArgodeController is available for unified input management
	var controller = ArgodeSystem.Controller if ArgodeSystem.has_method("get_property") and "Controller" in ArgodeSystem else null
	
	if controller and controller.has_signal("input_received"):
		# Use unified input management through ArgodeController
		ArgodeSystem.log("🎮 Waiting for input via ArgodeController...", ArgodeSystem.LOG_LEVEL.DEBUG)
		await controller.input_received
		ArgodeSystem.log("🎮 Input received via ArgodeController - continuing", ArgodeSystem.LOG_LEVEL.DEBUG)
		return
	
	# Fallback: Try message-specific input methods
	var message_window = get_message_window()
	if not message_window:
		ArgodeSystem.log("❌ Cannot wait for input: No message window or controller found", ArgodeSystem.LOG_LEVEL.CRITICAL)
		return
	
	var message_renderer = get_message_renderer()
	
	# Try to use renderer's input waiting method
	if message_renderer and message_renderer.has_method("wait_for_input"):
		ArgodeSystem.log("🎮 Waiting for input via message renderer...", ArgodeSystem.LOG_LEVEL.DEBUG)
		await message_renderer.wait_for_input()
		return
	
	# Try message window's input waiting method
	if message_window.has_method("wait_for_input"):
		ArgodeSystem.log("🎮 Waiting for input via message window...", ArgodeSystem.LOG_LEVEL.DEBUG)
		await message_window.wait_for_input()
		return
	
	# Last resort: Generic input waiting
	ArgodeSystem.log("🎮 Using fallback input waiting...", ArgodeSystem.LOG_LEVEL.DEBUG)
	if ArgodeSystem.tree:
		await ArgodeSystem.tree.process_frame
		var input_received = false
		while not input_received:
			if Input.is_action_just_pressed("argode_advance") or Input.is_action_just_pressed("ui_accept"):
				input_received = true
			await ArgodeSystem.tree.process_frame
	
	ArgodeSystem.log("🎮 Input received - continuing", ArgodeSystem.LOG_LEVEL.DEBUG)
