# GDScript Custom Command Integration

Learn how to execute Argode custom commands (ui call, audio commands, etc.) directly from GDScript code.

## 🚀 Basic Execution Method

### 1. Getting ArgodeSystem and CustomCommandHandler

```gdscript
extends Node

func _ready():
    # Get ArgodeSystem
    var argode_system = get_node("/root/ArgodeSystem")
    if not argode_system:
        push_error("ArgodeSystem not found")
        return
    
    # Get CustomCommandHandler
    var custom_handler = argode_system.get_custom_command_handler()
    if not custom_handler:
        push_error("CustomCommandHandler not found")
        return
    
    # Execute commands
    execute_ui_command(custom_handler)
```

### 2. Building Parameter Dictionary

Custom commands use the same parameter dictionary format as RGD scripts:

```gdscript
func build_command_params(command_line: String) -> Dictionary:
    # Example: "call res://ui/menu.tscn at center with fade"
    var args = command_line.split(" ")
    var params = {
        "_raw": command_line,
        "_count": args.size()
    }
    
    # Store each argument as arg0, arg1, ...
    for i in range(args.size()):
        params["arg" + str(i)] = args[i]
    
    return params
```

### 3. Command Execution

```gdscript
func execute_ui_command_example(custom_handler: CustomCommandHandler):
    # Execute ui call command
    var ui_params = {
        "_raw": "call res://ui/choice_menu.tscn at center with fade",
        "_count": 6,
        "arg0": "call",
        "arg1": "res://ui/choice_menu.tscn",
        "arg2": "at",
        "arg3": "center", 
        "arg4": "with",
        "arg5": "fade"
    }
    
    print("🎯 Executing ui call command from GDScript")
    
    # Get registered UICommand and execute directly
    var ui_command = custom_handler.registered_commands.get("ui")
    if ui_command:
        await custom_handler._execute_registered_command(ui_command, ui_params)
    else:
        push_error("UI command not found in registered commands")
```

## 🎯 UI Command Convenience Methods

### ui call Command (Modal Display)

```gdscript
func call_ui_scene(scene_path: String, position: String = "center", transition: String = "fade"):
    """Easy ui call command execution - script waits until scene closes"""
    var argode_system = get_node("/root/ArgodeSystem")
    var custom_handler = argode_system.get_custom_command_handler()
    
    var params = {
        "_raw": "call " + scene_path + " at " + position + " with " + transition,
        "_count": 6,
        "arg0": "call",
        "arg1": scene_path,
        "arg2": "at",
        "arg3": position,
        "arg4": "with",
        "arg5": transition
    }
    
    custom_handler.execute_custom_command("ui", params, "")

# Usage example
func _on_choice_button_pressed():
    call_ui_scene("res://ui/player_choice.tscn", "center", "fade")
    print("Player completed their choice")  # Executes after choice
```

### ui show Command (Normal Display)

```gdscript
func show_ui_scene(scene_path: String, position: String = "center", transition: String = "none"):
    """Easy ui show command execution - script continues execution"""
    var argode_system = get_node("/root/ArgodeSystem")
    var custom_handler = argode_system.get_custom_command_handler()
    
    var params = {
        "_raw": "show " + scene_path + " at " + position + " with " + transition,
        "_count": 6,
        "arg0": "show",
        "arg1": scene_path,
        "arg2": "at",
        "arg3": position,
        "arg4": "with",
        "arg5": transition
    }
    
    custom_handler.execute_custom_command("ui", params, "")

# Usage example
func _on_status_button_pressed():
    show_ui_scene("res://ui/status_panel.tscn", "right", "slide")
    print("Status screen displayed")  # Executes immediately
```

### ui close Command (Close call_screen)

```gdscript
func close_ui_call_screen(scene_path: String = ""):
    """Easy ui close command execution"""
    var argode_system = get_node("/root/ArgodeSystem")
    var custom_handler = argode_system.get_custom_command_handler()
    
    var params = {}
    if scene_path.is_empty():
        # Close last call_screen
        params = {
            "_raw": "close",
            "_count": 1,
            "arg0": "close"
        }
    else:
        # Close specific scene
        params = {
            "_raw": "close " + scene_path,
            "_count": 2,
            "arg0": "close",
            "arg1": scene_path
        }
    
    custom_handler.execute_custom_command("ui", params, "")

# Usage example
func _on_cancel_button_pressed():
    close_ui_call_screen()  # Close last call_screen
    close_ui_call_screen("res://ui/specific_menu.tscn")  # Close specific scene
```

## 🔍 UI State Check Methods

### Check call_screen Display Status

```gdscript
func is_call_screen_active(scene_path: String = "") -> bool:
    """Check if specified call_screen is currently displayed"""
    var argode_system = get_node("/root/ArgodeSystem")
    var custom_handler = argode_system.get_custom_command_handler()
    var ui_command = custom_handler.registered_commands.get("ui")
    
    if not ui_command:
        push_error("UI command not found")
        return false
    
    if scene_path.is_empty():
        # Check if any call_screen is currently displayed
        return not ui_command.call_screen_stack.is_empty()
    else:
        # Check if specified scene is in call_screen_stack
        return scene_path in ui_command.call_screen_stack

func get_active_call_screens() -> Array[String]:
    """Get list of currently displayed call_screens"""
    var argode_system = get_node("/root/ArgodeSystem")
    var custom_handler = argode_system.get_custom_command_handler()
    var ui_command = custom_handler.registered_commands.get("ui")
    
    if not ui_command:
        push_error("UI command not found")
        return []
    
    return ui_command.call_screen_stack.duplicate()

func get_current_call_screen() -> String:
    """Get currently displayed top-level call_screen"""
    var argode_system = get_node("/root/ArgodeSystem")
    var custom_handler = argode_system.get_custom_command_handler()
    var ui_command = custom_handler.registered_commands.get("ui")
    
    if not ui_command:
        push_error("UI command not found")
        return ""
    
    if ui_command.call_screen_stack.is_empty():
        return ""
    
    return ui_command.call_screen_stack[-1]  # Last element (top-level)

func is_ui_scene_active(scene_path: String) -> bool:
    """Check if specified UI scene is currently displayed (call/show regardless)"""
    var argode_system = get_node("/root/ArgodeSystem")
    var custom_handler = argode_system.get_custom_command_handler()
    var ui_command = custom_handler.registered_commands.get("ui")
    
    if not ui_command:
        push_error("UI command not found")
        return false
    
    return scene_path in ui_command.active_ui_scenes

func get_all_active_ui_scenes() -> Array[String]:
    """Get list of all currently displayed UI scenes"""
    var argode_system = get_node("/root/ArgodeSystem")
    var custom_handler = argode_system.get_custom_command_handler()
    var ui_command = custom_handler.registered_commands.get("ui")
    
    if not ui_command:
        push_error("UI command not found")
        return []
    
    return ui_command.active_ui_scenes.keys()
```

### Usage Examples

```gdscript
# Check if specific menu is currently displayed
func _on_pause_button_pressed():
    if is_call_screen_active("res://ui/pause_menu.tscn"):
        print("Pause menu is already displayed")
        return
    
    # Display pause menu
    await call_ui_scene("res://ui/pause_menu.tscn")

# Check current call_screen
func _on_check_current_menu():
    var current_menu = get_current_call_screen()
    if current_menu.is_empty():
        print("No call_screen currently displayed")
    else:
        print("Current menu: " + current_menu)

# Handle multiple layered call_screens
func _on_back_button_pressed():
    var call_screens = get_active_call_screens()
    if call_screens.size() > 1:
        print("Menus are " + str(call_screens.size()) + " layers deep")
        # Close only top-level menu
        close_ui_call_screen()
    elif call_screens.size() == 1:
        print("Closing menu: " + call_screens[0])
        close_ui_call_screen()
    else:
        print("No menu to close")

# Debug all UI states
func _on_debug_ui_status():
    var call_screens = get_active_call_screens()
    var all_ui_scenes = get_all_active_ui_scenes()
    
    print("=== UI Status Debug ===")
    print("Call Screens: " + str(call_screens.size()) + " active")
    for i in range(call_screens.size()):
        print("  " + str(i + 1) + ". " + call_screens[i])
    
    print("All UI Scenes: " + str(all_ui_scenes.size()) + " active")
    for scene_path in all_ui_scenes:
        var is_call = scene_path in call_screens
        var type_str = " [call]" if is_call else " [show]"
        print("  - " + scene_path + type_str)
```

## 🎯 UI Callback System

UICommand provides a comprehensive callback system for receiving results from UI scenes displayed with call_screen.

### Available Signals in call_screen

UI scenes displayed with call_screen can define the following signals:

```gdscript
# UI Scene side (e.g., choice_menu.gd)
extends Control
class_name ChoiceMenu

# Signal to return results
signal screen_result(result: Variant)
# Signal to close itself  
signal close_screen()

func _ready():
    # Button setup etc.
    $YesButton.pressed.connect(_on_yes_pressed)
    $NoButton.pressed.connect(_on_no_pressed)
    $CancelButton.pressed.connect(_on_cancel_pressed)

func _on_yes_pressed():
    # Return choice result and auto-close
    screen_result.emit("yes")

func _on_no_pressed():
    # Return choice result and auto-close
    screen_result.emit("no")

func _on_cancel_pressed():
    # Close without result
    close_screen.emit()
```

### Receiving UI Callbacks

#### 1. Using Dynamic Signals (Recommended)

```gdscript
func setup_ui_callbacks():
    """Setup UI callbacks"""
    var argode_system = get_node("/root/ArgodeSystem")
    var custom_handler = argode_system.get_custom_command_handler()
    
    # Connect to UI-related signals
    custom_handler.connect_to_dynamic_signal("ui_call_screen_result", _on_ui_call_screen_result)
    custom_handler.connect_to_dynamic_signal("ui_call_screen_shown", _on_ui_call_screen_shown)
    custom_handler.connect_to_dynamic_signal("ui_call_screen_closed", _on_ui_call_screen_closed)

func _on_ui_call_screen_result(args: Array):
    """Handle results from call_screen"""
    var scene_path = args[0] as String
    var result = args[1]
    
    print("UI Callback Result:", scene_path, "->", result)
    
    # Handle results by scene
    match scene_path:
        "res://ui/choice_menu.tscn":
            _handle_choice_result(result)
        "res://ui/save_dialog.tscn":
            _handle_save_result(result)
        _:
            print("Unhandled UI result:", scene_path, result)

func _on_ui_call_screen_shown(args: Array):
    """Handle call_screen display"""
    var scene_path = args[0] as String
    var position = args[1] as String
    var transition = args[2] as String
    print("UI displayed:", scene_path)

func _on_ui_call_screen_closed(args: Array):
    """Handle call_screen closure"""
    var scene_path = args[0] as String
    print("UI closed:", scene_path)

func _handle_choice_result(result: Variant):
    """Handle choice menu results"""
    match result:
        "yes":
            print("Player selected 'Yes'")
            continue_yes_path()
        "no":
            print("Player selected 'No'")
            continue_no_path()
        _:
            print("Unknown choice:", result)
```

#### 2. Direct Access from call_screen_results

```gdscript
func show_choice_and_get_result() -> Variant:
    """Display choice menu and get result"""
    var scene_path = "res://ui/choice_menu.tscn"
    
    # Display menu (await for completion)
    await call_ui_scene(scene_path)
    
    # Get result
    var argode_system = get_node("/root/ArgodeSystem")
    var custom_handler = argode_system.get_custom_command_handler()
    var ui_command = custom_handler.registered_commands.get("ui")
    
    if ui_command and scene_path in ui_command.call_screen_results:
        var result = ui_command.call_screen_results[scene_path]
        print("Retrieved result:", result)
        return result
    else:
        print("No result")
        return null

# Usage example
func _on_show_choice_button_pressed():
    var choice_result = await show_choice_and_get_result()
    
    if choice_result == "yes":
        print("Yes was selected")
    elif choice_result == "no":
        print("No was selected")
    else:
        print("Cancel or no result")
```

### Available Dynamic Signals

Major signals emitted by UICommand:

- `ui_call_screen_shown` - When call_screen is displayed
- `ui_call_screen_closed` - When call_screen is closed  
- `ui_call_screen_result` - When result is returned from call_screen
- `ui_scene_shown` - When UI scene is displayed (including show)
- `ui_scene_freed` - When UI scene is freed

### UI Scene Best Practices

```gdscript
# Generic call_screen base class
extends Control
class_name BaseCallScreen

signal screen_result(result: Variant)
signal close_screen()

var _result_sent: bool = false

func send_result(result: Variant):
    """Send result (prevent duplicate sending)"""
    if not _result_sent:
        _result_sent = true
        screen_result.emit(result)

func close_without_result():
    """Close without result"""
    if not _result_sent:
        _result_sent = true
        close_screen.emit()

func _on_tree_exiting():
    """Auto-close if result not sent before scene destruction"""
    if not _result_sent:
        close_without_result()
```

## 🎵 Combining with AudioManager

```gdscript
func _on_menu_button_pressed():
    """Example combining audio and UI controls"""
    var argode_system = get_node("/root/ArgodeSystem")
    
    # Play SE
    argode_system.AudioManager.play_se("menu_open", 0.8)
    
    # Show menu modally (wait for player choice)
    call_ui_scene("res://ui/game_menu.tscn", "center", "fade")
    
    # Executes after menu closes
    argode_system.AudioManager.play_se("menu_close", 0.8)
    print("Menu operation completed")

func _on_notification_needed():
    """Asynchronous notification example"""
    var argode_system = get_node("/root/ArgodeSystem")
    
    # Notification sound
    argode_system.AudioManager.play_se("notification", 0.6)
    
    # Show notification panel (script continues)
    show_ui_scene("res://ui/notification_panel.tscn", "top", "slide")
    
    # Immediately proceed to next process
    continue_game_logic()
```

## 🔧 Advanced Usage Examples

### Custom UI Manager Class

```gdscript
# UIManager.gd - Project-specific UI Manager
extends Node
class_name UIManager

var argode_system: Node
var custom_handler: CustomCommandHandler
var audio_manager: Node

func _ready():
    argode_system = get_node("/root/ArgodeSystem")
    custom_handler = argode_system.get_custom_command_handler()
    audio_manager = argode_system.AudioManager

func show_main_menu():
    """Show main menu"""
    audio_manager.play_bgm("menu_theme", true, 0.8)
    call_ui_scene("res://ui/main_menu.tscn")

func show_pause_menu():
    """Show pause menu"""
    audio_manager.set_bgm_volume(0.3)  # Lower BGM volume
    audio_manager.play_se("pause", 0.7)
    call_ui_scene("res://ui/pause_menu.tscn")

func close_pause_menu():
    """Close pause menu"""
    close_ui_call_screen()
    audio_manager.set_bgm_volume(1.0)  # Restore BGM volume
    audio_manager.play_se("resume", 0.7)

func show_inventory():
    """Show inventory (non-modal)"""
    audio_manager.play_se("inventory_open", 0.6)
    show_ui_scene("res://ui/inventory.tscn", "left", "slide")

# Convenience methods
func call_ui_scene(scene_path: String, position: String = "center", transition: String = "fade"):
    var params = {
        "_raw": "call " + scene_path + " at " + position + " with " + transition,
        "_count": 6,
        "arg0": "call",
        "arg1": scene_path,
        "arg2": "at",
        "arg3": position,
        "arg4": "with",
        "arg5": transition
    }
    custom_handler.execute_custom_command("ui", params, "")

func show_ui_scene(scene_path: String, position: String = "center", transition: String = "none"):
    var params = {
        "_raw": "show " + scene_path + " at " + position + " with " + transition,
        "_count": 6,
        "arg0": "show",
        "arg1": scene_path,
        "arg2": "at",
        "arg3": position,
        "arg4": "with",
        "arg5": transition
    }
    custom_handler.execute_custom_command("ui", params, "")

func close_ui_call_screen(scene_path: String = ""):
    var params = {}
    if scene_path.is_empty():
        params = {
            "_raw": "close",
            "_count": 1,
            "arg0": "close"
        }
    else:
        params = {
            "_raw": "close " + scene_path,
            "_count": 2,
            "arg0": "close",
            "arg1": scene_path
        }
    custom_handler.execute_custom_command("ui", params, "")
```

## 📚 Important Points

### Choosing between call vs show

- **`ui call`**: Modal dialogs, choice menus, pause screens - when you need to wait for user interaction
- **`ui show`**: Status displays, inventory, mini-maps - when you want to show alongside gameplay

### Performance Considerations

- Adjust BGM volume when showing UI as needed
- Pre-load frequently shown/hidden UI elements
- Properly free UI scenes when no longer needed

### Error Handling

```gdscript
func safe_call_ui_scene(scene_path: String, position: String = "center", transition: String = "fade") -> bool:
    """UI display with error handling"""
    var argode_system = get_node("/root/ArgodeSystem")
    if not argode_system:
        push_error("ArgodeSystem not found")
        return false
    
    var custom_handler = argode_system.get_custom_command_handler()
    if not custom_handler:
        push_error("CustomCommandHandler not found") 
        return false
    
    # Check if scene file exists
    if not ResourceLoader.exists(scene_path):
        push_error("UI scene not found: " + scene_path)
        return false
    
    call_ui_scene(scene_path, position, transition)
    return true
```

This implementation allows you to fully utilize Argode's custom command system from GDScript side.
