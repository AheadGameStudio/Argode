# Game Settings System

The Argode framework includes a comprehensive game settings system that allows players to configure their gameplay experience. Settings are persistent across all game sessions and stored separately from save data.

## Overview

Game settings in Argode provide:
- **Persistent Configuration**: Settings persist across game sessions and save files
- **Categorized Organization**: Settings organized into logical categories
- **Automatic Persistence**: Changes are automatically saved to disk
- **Command Integration**: Easy-to-use script commands for all settings
- **Type Safety**: Proper value validation and type checking
- **Default Values**: Sensible defaults for all settings

## Setting Categories

### Audio Settings (`audio`)
Controls all audio-related preferences:
- `master_volume` (0.0-1.0): Master audio volume
- `bgm_volume` (0.0-1.0): Background music volume  
- `se_volume` (0.0-1.0): Sound effects volume
- `voice_volume` (0.0-1.0): Voice audio volume
- `mute_when_unfocused` (bool): Mute audio when game loses focus

### Display Settings (`display`)
Controls visual and window preferences:
- `fullscreen` (bool): Fullscreen mode toggle
- `window_size` (string): Window dimensions as "(width, height)"
- `vsync` (bool): Vertical sync enable/disable
- `max_fps` (int): Maximum frames per second limit

### Text Settings (`text`)
Controls text display and reading experience:
- `text_speed` (0.1-5.0): Text display speed multiplier
- `auto_play_speed` (0.1-5.0): Auto-play text speed
- `font_size` (int): Text font size
- `text_outline` (bool): Text outline visibility

### UI Settings (`ui`)
Controls user interface preferences:
- `dialog_opacity` (0.0-1.0): Dialog box opacity
- `ui_scale` (0.5-2.0): User interface scale factor
- `show_ui_animations` (bool): UI animation toggle
- `quick_menu_visible` (bool): Quick menu visibility

### Accessibility Settings (`accessibility`)
Controls accessibility features:
- `high_contrast` (bool): High contrast mode
- `screen_reader_support` (bool): Screen reader support
- `reduce_motion` (bool): Reduce motion effects
- `large_text` (bool): Large text mode

### System Settings (`system`)
Controls system-level preferences:
- `language` (string): Game language code (e.g., "en", "ja")
- `auto_save_frequency` (int): Auto-save frequency in minutes
- `confirm_quit` (bool): Show quit confirmation dialog
- `skip_intro` (bool): Skip intro sequences

## Script Commands

### `settings` Command
The primary command for managing all game settings.

**Syntax:**
```rgd
settings <action> [category] [key] [value]
```

**Actions:**
- `get <category> <key>` - Get a setting value
- `set <category> <key> <value>` - Set a setting value
- `reset` - Reset all settings to defaults
- `save` - Save current settings to file
- `load` - Reload settings from file
- `print` - Display all current settings

**Examples:**
```rgd
# Get current master volume
settings get audio master_volume

# Set background music volume
settings set audio bgm_volume 0.7

# Enable fullscreen mode
settings set display fullscreen true

# Set text speed to 1.5x
settings set text text_speed 1.5

# Reset all settings to defaults
settings reset

# Print all current settings
settings print
```

### `volume` Command
Convenient shortcut for audio volume control.

**Syntax:**
```rgd
volume [type] [value]
```

**Parameters:**
- `type` (optional): Volume type - `master`, `bgm`, `se`, `voice`
- `value` (optional): Volume level (0.0-1.0)

**Examples:**
```rgd
# Show all volume levels
volume

# Get specific volume level
volume master
volume bgm

# Set volume levels
volume master 0.8
volume bgm 0.6
volume se 0.9
volume voice 1.0
```

### `textspeed` Command
Convenient shortcut for text speed adjustment.

**Syntax:**
```rgd
textspeed [speed]
```

**Parameters:**
- `speed` (optional): Text speed multiplier (0.1-5.0)
  - `1.0` = Normal speed
  - `2.0` = Double speed
  - `0.5` = Half speed

**Examples:**
```rgd
# Show current text speed
textspeed

# Set text speed
textspeed 1.5    # 1.5x speed
textspeed 0.8    # 0.8x speed
textspeed 2.0    # Double speed
```

## Programmatic API

### SaveLoadManager Methods

```gdscript
# Get setting value
var volume = ArgodeSystem.SaveLoadManager.get_setting("audio", "master_volume")
var fullscreen = ArgodeSystem.SaveLoadManager.get_setting("display", "fullscreen")

# Set setting value
ArgodeSystem.SaveLoadManager.set_setting("audio", "bgm_volume", 0.7)
ArgodeSystem.SaveLoadManager.set_setting("text", "text_speed", 1.5)

# Settings file management
ArgodeSystem.SaveLoadManager.save_settings()
ArgodeSystem.SaveLoadManager.load_settings()
ArgodeSystem.SaveLoadManager.reset_settings()

# Check if setting exists
var has_setting = ArgodeSystem.SaveLoadManager.has_setting("audio", "master_volume")

# Get all settings in a category
var audio_settings = ArgodeSystem.SaveLoadManager.get_category_settings("audio")

# Get all settings
var all_settings = ArgodeSystem.SaveLoadManager.get_all_settings()
```

### Default Values Access

```gdscript
# Get default value for a setting
var default_volume = ArgodeSystem.SaveLoadManager.get_setting_default("audio", "master_volume")

# Check if setting is at default value
var is_default = ArgodeSystem.SaveLoadManager.is_setting_default("text", "text_speed")
```

## File Storage

### Storage Location
Settings are stored in `user://argode_settings.cfg` using Godot's ConfigFile format.

### File Format
```ini
[audio]
master_volume=1.0
bgm_volume=0.8
se_volume=0.9
voice_volume=1.0
mute_when_unfocused=false

[display]
fullscreen=false
window_size="(1920, 1080)"
vsync=true
max_fps=60

[text]
text_speed=1.0
auto_play_speed=2.0
font_size=16
text_outline=true
```

## Integration with Game Systems

### Automatic Application
Many settings are automatically applied when changed:
- **Audio volumes**: Applied immediately to audio buses
- **Display settings**: Applied to window and rendering
- **Text settings**: Applied to text display systems

### Custom Integration

```gdscript
# Listen for settings changes
func _ready():
    ArgodeSystem.SaveLoadManager.setting_changed.connect(_on_setting_changed)

func _on_setting_changed(category: String, key: String, value):
    match category:
        "audio":
            _apply_audio_setting(key, value)
        "display":
            _apply_display_setting(key, value)
        "text":
            _apply_text_setting(key, value)

func _apply_audio_setting(key: String, value):
    match key:
        "master_volume":
            AudioServer.set_bus_volume_db(0, linear_to_db(value))
        "bgm_volume":
            AudioServer.set_bus_volume_db(1, linear_to_db(value))
```

## Best Practices

### Settings Menu Integration

```gdscript
# Create settings menu with automatic persistence
func create_volume_slider():
    var slider = HSlider.new()
    slider.min_value = 0.0
    slider.max_value = 1.0
    slider.value = ArgodeSystem.SaveLoadManager.get_setting("audio", "master_volume")
    
    slider.value_changed.connect(func(value):
        ArgodeSystem.SaveLoadManager.set_setting("audio", "master_volume", value)
    )

func create_fullscreen_checkbox():
    var checkbox = CheckBox.new()
    checkbox.button_pressed = ArgodeSystem.SaveLoadManager.get_setting("display", "fullscreen")
    
    checkbox.toggled.connect(func(pressed):
        ArgodeSystem.SaveLoadManager.set_setting("display", "fullscreen", pressed)
    )
```

### Validation and Error Handling

```gdscript
# Validate setting values before applying
func set_volume_safely(volume_type: String, value: float):
    if value < 0.0 or value > 1.0:
        print("Invalid volume value: ", value)
        return false
    
    return ArgodeSystem.SaveLoadManager.set_setting("audio", volume_type + "_volume", value)

# Handle settings load errors
if not ArgodeSystem.SaveLoadManager.load_settings():
    print("Failed to load settings, using defaults")
    ArgodeSystem.SaveLoadManager.reset_settings()
```

### Performance Considerations

```gdscript
# Batch setting changes
func apply_audio_preset(preset_name: String):
    # Temporarily disable auto-save during batch operations
    ArgodeSystem.SaveLoadManager.set_auto_save_enabled(false)
    
    match preset_name:
        "quiet":
            ArgodeSystem.SaveLoadManager.set_setting("audio", "master_volume", 0.3)
            ArgodeSystem.SaveLoadManager.set_setting("audio", "bgm_volume", 0.2)
            ArgodeSystem.SaveLoadManager.set_setting("audio", "se_volume", 0.4)
        "normal":
            ArgodeSystem.SaveLoadManager.set_setting("audio", "master_volume", 1.0)
            ArgodeSystem.SaveLoadManager.set_setting("audio", "bgm_volume", 0.8)
            ArgodeSystem.SaveLoadManager.set_setting("audio", "se_volume", 0.9)
    
    # Re-enable auto-save and save all changes
    ArgodeSystem.SaveLoadManager.set_auto_save_enabled(true)
    ArgodeSystem.SaveLoadManager.save_settings()
```

## Migration and Versioning

### Settings Version Compatibility
The system handles settings file version updates automatically:

```gdscript
# Check settings version
var settings_version = ArgodeSystem.SaveLoadManager.get_settings_version()

# Migrate old settings format
if settings_version < "2.0":
    ArgodeSystem.SaveLoadManager.migrate_settings_from_old_format()
```

## Troubleshooting

### Common Issues

1. **Settings Not Persisting**
   - Check file permissions in user data directory
   - Verify settings are being saved with `save_settings()`
   - Check for file system errors

2. **Invalid Setting Values**
   - Verify value types match expected types
   - Check value ranges for numeric settings
   - Use validation before setting values

3. **Settings Reset Unexpectedly**
   - Check for corrupted settings file
   - Verify default value definitions
   - Check for code that calls `reset_settings()`

### Debug Commands

```rgd
# Debug settings system
settings print           # Show all current settings
settings load            # Reload from file
settings save            # Force save to file
```

## See Also

- [Save & Load System](./index.md)
- [Built-in Commands](../custom-commands/built-in.md)
- [Audio System](../audio/index.md)
- [Variables System](../variables/index.md)
