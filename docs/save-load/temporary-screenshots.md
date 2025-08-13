# Temporary Screenshots

The temporary screenshot feature allows capturing clean game scenes before UI elements appear, ensuring save thumbnails show actual gameplay content rather than menus or dialogs.

## Overview

When players open save menus, the current screen contains UI elements that shouldn't appear in save thumbnails. The temporary screenshot system solves this by:

1. **Pre-capture**: Taking screenshots before UI appears
2. **Temporary Storage**: Keeping screenshots in memory temporarily  
3. **Priority Usage**: Using temporary screenshots for saves when available
4. **Auto-cleanup**: Automatically clearing temporary screenshots after use

## Usage Patterns

### Basic Usage

```argode
# In your scenario script
scene classroom
show yuko happy center
yuko "What a beautiful day!"

# Capture clean screenshot before opening menu
capture

# UI operations won't affect the saved screenshot
ui save_menu show
```

### Programmatic Usage

```gdscript
# Before showing UI
func show_pause_menu():
    # Capture current game state
    ArgodeSystem.capture_temp_screenshot()
    
    # Now show UI - won't be captured
    pause_menu.show()

# Save will use the clean screenshot
func save_to_slot(slot: int, name: String):
    ArgodeSystem.save_game(slot, name)  # Uses temp screenshot if available
```

### Auto-capture Helper

```gdscript
# Built-in helper for UI systems
func show_menu_with_capture(menu_name: String):
    var save_manager = ArgodeSystem.SaveLoadManager
    save_manager.auto_capture_before_ui(menu_name)
    
    # Show your menu UI
    show_menu(menu_name)
```

## Technical Details

### Storage and Lifecycle

- **Memory Only**: Screenshots stored in RAM, not on disk
- **Base64 Format**: Compressed JPEG encoded as Base64 string
- **Fixed Size**: Thumbnails resized to 200x150 pixels
- **Automatic Expiry**: Screenshots expire after 5 minutes if unused

### Behavior Logic

```gdscript
# When saving, the system checks:
func _get_screenshot_for_save() -> String:
    if has_valid_temp_screenshot():
        return temp_screenshot_data  # Use temporary screenshot
    else:
        return capture_current_screen()  # Fallback to real-time capture
```

### Cleanup Events

Temporary screenshots are automatically cleared when:

- **Save Completed**: After successfully saving to any slot
- **Load Completed**: After loading from any slot  
- **Expired**: After 5 minutes of inactivity
- **Manual Clear**: When explicitly cleared via code

## API Reference

### Core Methods

```gdscript
# SaveLoadManager methods
capture_temp_screenshot() -> bool              # Capture temporary screenshot
has_temp_screenshot() -> bool                  # Check if valid temp screenshot exists
get_temp_screenshot_age() -> float             # Get age in seconds
auto_capture_before_ui(ui_name: String) -> bool  # Helper for UI operations

# ArgodeSystem wrapper methods  
ArgodeSystem.capture_temp_screenshot() -> bool
ArgodeSystem.has_temp_screenshot() -> bool
ArgodeSystem.clear_temp_screenshot()
```

### Configuration Constants

```gdscript
# In SaveLoadManager.gd
const ENABLE_SCREENSHOTS = true        # Enable/disable screenshot feature
const SCREENSHOT_WIDTH = 200          # Thumbnail width in pixels  
const SCREENSHOT_HEIGHT = 150         # Thumbnail height in pixels
const SCREENSHOT_QUALITY = 0.7        # JPEG quality (0.0-1.0)
const TEMP_SCREENSHOT_LIFETIME = 300.0  # Expiry time in seconds (5 minutes)
```

## Best Practices

### When to Capture

**Good Times:**
```argode
# Before dialogue choices
narrator "Choose your path..."
capture
choice "Go left" go_left
choice "Go right" go_right
```

**Before menu access:**
```gdscript
func on_menu_key_pressed():
    ArgodeSystem.capture_temp_screenshot()
    show_game_menu()
```

### What NOT to Capture

**Avoid capturing during:**
- Loading screens
- Transition effects
- Text boxes or dialogues (if you want clean backgrounds)
- Other UI elements

### Integration with Save Systems

```gdscript
# Example save menu integration
class SaveMenu:
    func _ready():
        # Capture was already done before showing this menu
        populate_save_slots()
    
    func save_to_slot(slot: int):
        var save_name = save_name_input.text
        # This will use the temporary screenshot captured before menu opened
        ArgodeSystem.save_game(slot, save_name)
        
        # Temp screenshot is automatically cleared after save
        close_menu()
```

## Troubleshooting

### Common Issues

**No screenshot captured:**
- Check if `ENABLE_SCREENSHOTS` is true
- Ensure viewport access permissions
- Verify the capture command ran successfully

**Screenshots showing UI:**
- Make sure `capture` is called BEFORE showing UI
- Check timing - UI might be showing during capture

**Screenshots expiring:**
- Default lifetime is 5 minutes
- Capture closer to when you'll actually save
- Check `get_temp_screenshot_age()` for timing

### Debug Information

```gdscript
var save_manager = ArgodeSystem.SaveLoadManager
print("Has temp screenshot: ", save_manager.has_temp_screenshot())
print("Screenshot age: ", save_manager.get_temp_screenshot_age(), " seconds")
print("Screenshot enabled: ", save_manager.is_screenshot_enabled())
```

## See Also

- [Save & Load System](index.md)
- [UI Integration](../ui/index.md)
- [Best Practices](../getting-started/best-practices.md)
