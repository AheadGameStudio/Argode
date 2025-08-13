# Save & Load System

The Argode system provides a comprehensive save/load functionality similar to Ren'Py, allowing players to save their game progress and restore it later with full state preservation.

## Overview

The save/load system preserves:
- **Game Variables**: All variable states and values
- **Character States**: Character positions, expressions, and visibility
- **Background States**: Current background scenes and layers
- **Audio States**: Current BGM, volume settings
- **Script Progress**: Current script position and call stack

## Basic Usage

### Built-in Commands

Use these commands directly in your `.rgd` script files:

```renpy
# Save to slot 0
save 0

# Save to slot 1 with custom name
save 1 "Before Boss Battle"

# Load from slot 0
load 0

# Load from slot 1
load 1
```

### Save Slots

- **10 Save Slots**: Slots 0-9 available
- **Auto Save**: Slot 9 is reserved for auto-save functionality
- **Slot Management**: Each slot stores complete game state

## Programmatic API

### ArgodeSystem Methods

```gdscript
# Save game to specified slot
var success = ArgodeSystem.save_game(slot_number, "Save Name")

# Load game from specified slot
var success = ArgodeSystem.load_game(slot_number)

# Get save information
var save_info = ArgodeSystem.get_save_info(slot_number)

# Auto-save functionality
var success = ArgodeSystem.SaveLoadManager.auto_save()
var success = ArgodeSystem.SaveLoadManager.load_auto_save()
```

### Save Information Structure

```gdscript
{
    "save_name": "Player Save",
    "save_date": "2025-08-13T14:30:15",
    "save_time": 1692800215,
    "script_file": "res://scenarios/main.rgd",
    "line_number": 42
}
```

## File Storage

### Save Location

**Windows:**
```
%APPDATA%\Godot\app_userdata\[ProjectName]\saves\
```

**macOS:**
```
~/Library/Application Support/Godot/app_userdata/[ProjectName]/saves/
```

**Linux:**
```
~/.local/share/godot/app_userdata/[ProjectName]/saves/
```

### File Structure

```
saves/
├── slot_0.save    # Save slot 0
├── slot_1.save    # Save slot 1
├── ...
└── slot_9.save    # Auto-save slot
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
    "slot": 0,
    "save_name": "Player Save",
    "save_date_string": "2025-08-13T14:30:15",
    "save_time": 1692800215,
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
ArgodeSystem.save_game(0, "Chapter 1 Complete")
ArgodeSystem.save_game(1, "Before Final Boss")
```

### Auto-Save Integration

```gdscript
# Auto-save at key moments
func on_chapter_complete():
    ArgodeSystem.SaveLoadManager.auto_save()

func on_important_choice():
    ArgodeSystem.SaveLoadManager.auto_save()
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
