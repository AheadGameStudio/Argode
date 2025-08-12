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
func execute_custom_command_example(custom_handler: CustomCommandHandler):
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
    
    custom_handler.execute_custom_command("ui", ui_params, "")
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
