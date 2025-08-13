# Save & Load System

The Argode system provides a comprehensive save/load functionality with advanced features like screenshot thumbnails and flexible slot management, allowing players to save their game progress and restore it later with full state preservation. Additionally, the system includes persistent game settings management that persists across all game sessions.

## Overview

The save/load system preserves:
- **Game Variables**: All variable states and values
- **Character States**: Character positions, expressions, and visibility
- **Background States**: Current background scenes and layers
- **Audio States**: Current BGM, volume settings
- **Script Progress**: Current script position and call stack
- **Screenshot Thumbnails**: Visual preview of saved game states (Base64 encoded)

The system also manages persistent game settings that are separate from save data and persist across all game sessions:
- **Audio Settings**: Volume levels for different audio types
- **Display Settings**: Screen resolution, fullscreen mode
- **Text Settings**: Text speed and reading preferences
- **UI Settings**: Interface preferences
- **Accessibility Settings**: Accessibility options
- **System Settings**: Language and system preferences

## Game Settings vs Save Data

**Game Settings** are persistent configuration options that apply to all saves and persist across game sessions:
- Stored in `user://argode_settings.cfg`
- Independent of save slots
- Includes audio volumes, display preferences, text speed
- Managed via the `settings`, `volume`, and `textspeed` commands

**Save Data** preserves specific game progress and state:
- Stored in save slot files (`user://saves/slot_X.save`)
- Contains story progress, variables, character states
- Managed via the `save` and `load` commands
## Screenshot Thumbnails

The system automatically captures screenshots to provide visual previews of save states.

### Temporary Screenshots

To avoid UI elements in save thumbnails, use the temporary screenshot feature:

```rgd
# Capture current game scene before opening menus
capture

# Open menu/UI (won't be captured)
ui pause_menu show

# Save with clean screenshot
save 1 "Chapter Complete"
```

### Automatic Screenshot Handling

- **Temporary Priority**: Uses temporary screenshot if available
- **Real-time Fallback**: Captures current screen if no temporary screenshot
- **Auto-cleanup**: Temporary screenshots are automatically cleared after save/load
- **Expiration**: Temporary screenshots expire after 5 minutes

### Screenshot Settings

```gdscript
# In SaveLoadManager.gd
const ENABLE_SCREENSHOTS = true        # Enable/disable screenshots
const SCREENSHOT_WIDTH = 200          # Thumbnail width
const SCREENSHOT_HEIGHT = 150         # Thumbnail height  
const SCREENSHOT_QUALITY = 0.7        # JPEG quality (0.0-1.0)
```

## Basic Usage

### Built-in Commands

Use these commands directly in your `.rgd` script files:

```argode
# Capture temporary screenshot (before opening menus)
capture

# Save to slot 1 (slot 0 is reserved for auto-save)
save 1

# Save to slot 2 with custom name
save 2 "Before Boss Battle"

# Load from auto-save slot
load 0

# Load from manual save slot
load 1

# Manage game settings
settings set audio master_volume 0.8
settings get display fullscreen
volume bgm 0.6
textspeed 1.5
```

### Save Slots

- **Configurable Slots**: Default 10 slots (1 auto-save + 9 manual saves)
- **Auto Save**: Slot 0 is reserved for auto-save functionality
- **Manual Saves**: Slots 1+ for user saves
- **Slot Management**: Each slot stores complete game state with screenshot thumbnail

## Programmatic API

### ArgodeSystem Methods

```gdscript
# Save game to specified slot
var success = ArgodeSystem.save_game(slot_number, "Save Name")

# Load game from specified slot
var success = ArgodeSystem.load_game(slot_number)

# Get save information (includes screenshot data)
var save_info = ArgodeSystem.get_save_info(slot_number)

# Auto-save functionality
var success = ArgodeSystem.SaveLoadManager.auto_save()
var success = ArgodeSystem.SaveLoadManager.load_auto_save()

# Temporary screenshot management
var success = ArgodeSystem.capture_temp_screenshot()
var has_screenshot = ArgodeSystem.has_temp_screenshot()
ArgodeSystem.clear_temp_screenshot()

# Game settings management
ArgodeSystem.SaveLoadManager.set_setting("audio", "master_volume", 0.8)
var volume = ArgodeSystem.SaveLoadManager.get_setting("audio", "master_volume")
ArgodeSystem.SaveLoadManager.save_settings()
ArgodeSystem.SaveLoadManager.load_settings()
```

### Save Information Structure

```gdscript
{
    "save_name": "Player Save",
    "save_date": "2025-08-13T14:30:15",
    "save_time": 1692800215,
    "script_file": "res://scenarios/main.rgd",
    "line_number": 42,
    "has_screenshot": true,
    "screenshot": "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQ..."  # Base64 image data
}
```

## File Storage

### Save Location

**Windows:**
```
%APPDATA%\Godot\app_userdata\[ProjectName]\saves\     # Save data
%APPDATA%\Godot\app_userdata\[ProjectName]\           # Game settings (argode_settings.cfg)
```

**macOS:**
```
~/Library/Application Support/Godot/app_userdata/[ProjectName]/saves/     # Save data
~/Library/Application Support/Godot/app_userdata/[ProjectName]/           # Game settings (argode_settings.cfg)
```

**Linux:**
```
~/.local/share/godot/app_userdata/[ProjectName]/saves/     # Save data
~/.local/share/godot/app_userdata/[ProjectName]/           # Game settings (argode_settings.cfg)
```

### File Structure

**Save Data:**
```
saves/
├── slot_0.save    # Auto-save slot  
├── slot_1.save    # Manual save slot 1
├── slot_2.save    # Manual save slot 2
├── ...
└── slot_9.save    # Manual save slot 9
```

**Game Settings:**
```
argode_settings.cfg    # Persistent game settings (ConfigFile format)
```
## Security & Encryption

### Encryption Settings

The system supports file encryption for save data protection:

```gdscript
# In SaveLoadManager.gd
const ENABLE_ENCRYPTION = true                    # Enable/disable encryption
const ENCRYPTION_KEY = "your_encryption_key"     # Encryption key
```

### Encryption Features

- **AES Encryption**: Uses Godot's built-in encryption
- **Automatic**: Transparent encryption/decryption
- **Configurable**: Can be enabled/disabled per project

### Production Recommendations

For production builds, consider:

```gdscript
# Use environment variables
var encryption_key = OS.get_environment("GAME_SAVE_KEY")

# Generate user-specific keys
var user_key = OS.get_unique_id() + "salt_string"
```

## Error Handling

### Common Error Cases

```gdscript
# Check save result
if not ArgodeSystem.save_game(0, "My Save"):
    print("Save failed!")

# Check load result  
if not ArgodeSystem.load_game(0):
    print("Load failed - file not found or corrupted")

# Validate slot number
if slot < 0 or slot >= 10:
    print("Invalid slot number")
```

### Error Signals

```gdscript
# Connect to save/load signals
ArgodeSystem.SaveLoadManager.save_failed.connect(_on_save_failed)
ArgodeSystem.SaveLoadManager.load_failed.connect(_on_load_failed)

func _on_save_failed(slot: int, error: String):
    print("Save failed for slot ", slot, ": ", error)

func _on_load_failed(slot: int, error: String):
    print("Load failed for slot ", slot, ": ", error)
```

## Advanced Features

### Save Data Structure

The save file contains:

```json
{
    "version": "2.0",
    "slot": 1,
    "save_name": "Player Save",
    "save_date_string": "2025-08-13T14:30:15",
    "save_time": 1692800215,
    "screenshot": "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQ...",
    "variables": {
        "player_name": "Hero",
        "level": 5,
        "gold": 1000
    },
    "characters": {},
    "background": {},
    "audio": {
        "volume_settings": {
            "master_volume": 1.0,
            "bgm_volume": 0.8,
            "se_volume": 0.9
        }
    },
    "current_script_path": "res://scenarios/main.rgd",
    "current_line_index": 42,
    "call_stack": []
}
```

### Working with Screenshots

```gdscript
# Get screenshot from save data
var save_info = ArgodeSystem.get_save_info(slot)
if save_info.has("screenshot"):
    var texture = ArgodeSystem.SaveLoadManager.create_image_texture_from_screenshot(
        save_info["screenshot"]
    )
    # Use texture in UI
    save_thumbnail.texture = texture
```

### Custom Save Data

Extend the save system with custom data:

```gdscript
# In your custom script
func add_custom_save_data(save_data: Dictionary):
    save_data["custom_data"] = {
        "achievements": unlocked_achievements,
        "statistics": game_statistics
    }
```

## Best Practices

### Save Naming

```gdscript
# Use descriptive save names
ArgodeSystem.save_game(1, "Chapter 1 Complete")
ArgodeSystem.save_game(2, "Before Final Boss")

# Auto-save doesn't need naming
ArgodeSystem.SaveLoadManager.auto_save()
```

### Auto-Save Integration

```gdscript
# Auto-save at key moments
func on_chapter_complete():
    ArgodeSystem.SaveLoadManager.auto_save()

func on_important_choice():
    ArgodeSystem.SaveLoadManager.auto_save()
```

### Screenshot Best Practices

```gdscript
# Capture clean screenshots before UI operations
func open_save_menu():
    # Capture current game state first
    ArgodeSystem.capture_temp_screenshot()
    
    # Then show menu UI
    show_save_menu()

func save_game_with_clean_thumbnail(slot: int, name: String):
    # Screenshot was already captured before menu opened
    ArgodeSystem.save_game(slot, name)
```

### Save Validation

```gdscript
# Check if save exists before loading
var save_info = ArgodeSystem.get_save_info(slot)
if save_info.is_empty():
    print("No save data in slot ", slot)
else:
    ArgodeSystem.load_game(slot)
```

## Troubleshooting

### Common Issues

1. **Save Not Working**
   - Check file permissions
   - Verify disk space
   - Check encryption settings

2. **Load Fails**
   - Verify save file exists
   - Check version compatibility
   - Validate encryption key

3. **Performance Issues**
   - Large save files may cause delays
   - Consider compressing save data
   - Use async operations for UI

### Debug Information

```gdscript
# Get save system status
print("Encryption enabled: ", ArgodeSystem.SaveLoadManager.is_encryption_enabled())
print("Save directory: ", ArgodeSystem.SaveLoadManager.get_save_directory())
print("All saves: ", ArgodeSystem.SaveLoadManager.get_all_save_info())
```

## See Also

- [Variables System](../variables/index.md)
- [Character Management](../characters/index.md)
- [Audio System](../audio/index.md)  
- [Built-in Commands](../custom-commands/built-in.md) - Including settings, volume, and textspeed commands
