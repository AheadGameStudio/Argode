# AudioManager - Audio Control

AudioManager is responsible for controlling audio (BGM and SE) playback, stopping, and volume control in the Argode system.

## Overview

Using AudioManager, you can directly control audio files from GDScript. This provides programmatic audio control separate from the `audio` commands in scenario scripts.

## Accessing AudioManager

```gdscript
# Access AudioManager through ArgodeSystem
var argode_system = get_node("/root/ArgodeSystem")
var audio_manager = argode_system.AudioManager
```

## BGM Control

### play_bgm()
Plays background music.

```gdscript
audio_manager.play_bgm(audio_name, loop, volume, fade_in_duration)
```

**Parameters:**
- `audio_name` (String): Audio file name (defined in assets.rgd)
- `loop` (bool): Whether to loop playback (default: true)
- `volume` (float): Volume level (0.0-1.0, default: 1.0)
- `fade_in_duration` (float): Fade-in duration in seconds (default: 0.0)

**Examples:**
```gdscript
# Basic playback
audio_manager.play_bgm("yoru_no_zattou")

# Play without loop at 80% volume
audio_manager.play_bgm("bgm_peaceful", false, 0.8)

# Play with 3-second fade-in
audio_manager.play_bgm("bgm_dramatic", true, 1.0, 3.0)
```

### stop_bgm()
Stops background music.

```gdscript
audio_manager.stop_bgm(fade_out_duration)
```

**Parameters:**
- `fade_out_duration` (float): Fade-out duration in seconds (default: 0.0)

**Examples:**
```gdscript
# Stop immediately
audio_manager.stop_bgm()

# Stop with 2-second fade-out
audio_manager.stop_bgm(2.0)
```

### set_bgm_volume()
Adjusts BGM volume.

```gdscript
audio_manager.set_bgm_volume(volume)
```

**Parameters:**
- `volume` (float): Volume level (0.0-1.0)

## SE Control

### play_se()
Plays sound effects.

```gdscript
audio_manager.play_se(audio_name, volume, pitch)
```

**Parameters:**
- `audio_name` (String): SE name (defined in assets.rgd)
- `volume` (float): Volume level (0.0-1.0, default: 1.0)
- `pitch` (float): Pitch multiplier (0.5-2.0, default: 1.0)

**Examples:**
```gdscript
# Basic SE playback
audio_manager.play_se("keyword_ping")

# Play at 80% volume
audio_manager.play_se("door_open", 0.8)

# Play at 70% volume with 1.2x pitch
audio_manager.play_se("footsteps", 0.7, 1.2)
```

### stop_se()
Stops sound effects.

```gdscript
audio_manager.stop_se(audio_name)
```

**Parameters:**
- `audio_name` (String): Name of SE to stop (empty string stops all SE)

**Examples:**
```gdscript
# Stop specific SE
audio_manager.stop_se("keyword_ping")

# Stop all SE
audio_manager.stop_se()
```

### set_se_volume()
Adjusts SE volume.

```gdscript
audio_manager.set_se_volume(volume)
```

## Master Volume Control

### set_master_volume()
Adjusts overall volume.

```gdscript
audio_manager.set_master_volume(volume)
```

**Parameters:**
- `volume` (float): Master volume (0.0-1.0)

## Signals

AudioManager provides the following signals:

- `bgm_started(bgm_name: String)` - When BGM starts
- `bgm_stopped()` - When BGM stops
- `bgm_volume_changed(volume: float)` - When BGM volume changes
- `se_played(se_name: String)` - When SE plays
- `se_volume_changed(volume: float)` - When SE volume changes

**Signal connection example:**
```gdscript
func _ready():
    var audio_manager = get_node("/root/ArgodeSystem").AudioManager
    audio_manager.bgm_started.connect(_on_bgm_started)
    audio_manager.bgm_stopped.connect(_on_bgm_stopped)
    audio_manager.se_played.connect(_on_se_played)

func _on_bgm_started(bgm_name: String):
    print("BGM started:", bgm_name)

func _on_bgm_stopped():
    print("BGM stopped")

func _on_se_played(se_name: String):
    print("SE played:", se_name)
```

## Practical Examples

### Menu UI Audio Control

```gdscript
extends Control

var audio_manager

func _ready():
    var argode_system = get_node("/root/ArgodeSystem")
    audio_manager = argode_system.AudioManager

func _on_button_pressed():
    """Play SE when button is pressed"""
    audio_manager.play_se("keyword_ping", 0.5)

func _on_menu_opened():
    """Adjust BGM when menu opens"""
    # Temporarily lower current BGM volume
    audio_manager.set_bgm_volume(0.3)
    audio_manager.play_se("menu_open", 0.8)

func _on_menu_closed():
    """Restore BGM when menu closes"""
    # Restore BGM volume
    audio_manager.set_bgm_volume(1.0)
    audio_manager.play_se("menu_close", 0.8)
```

### Game Scene BGM Control

```gdscript
extends Node

func _ready():
    var audio_manager = get_node("/root/ArgodeSystem").AudioManager
    
    # Play BGM when game starts
    audio_manager.play_bgm("yoru_no_zattou", true, 0.8)

func _on_battle_started():
    """Switch BGM when battle starts"""
    var audio_manager = get_node("/root/ArgodeSystem").AudioManager
    
    # Switch to battle BGM with 1.5s fade-in
    audio_manager.play_bgm("bgm_tense", true, 1.0, 1.5)

func _on_battle_ended():
    """Return BGM when battle ends"""
    var audio_manager = get_node("/root/ArgodeSystem").AudioManager
    
    # Return to normal BGM with 2s fade-in
    audio_manager.play_bgm("bgm_peaceful", true, 0.8, 2.0)
```

### Environmental Audio Control

```gdscript
extends Node

func _on_rain_started():
    """When rain starts"""
    var audio_manager = get_node("/root/ArgodeSystem").AudioManager
    
    # Play rain loop SE
    audio_manager.play_se("rain_loop", 0.6)
    
    # Lower BGM volume for atmosphere
    audio_manager.set_bgm_volume(0.4)

func _on_rain_stopped():
    """When rain stops"""
    var audio_manager = get_node("/root/ArgodeSystem").AudioManager
    
    # Stop rain sound
    audio_manager.stop_se("rain_loop")
    
    # Restore BGM volume
    audio_manager.set_bgm_volume(1.0)
```

## Important Notes

1. **Audio File Definitions**: Audio files must be pre-defined in `assets.rgd`.
2. **Volume Range**: Volume should be specified in the range 0.0-1.0.
3. **SE Overlapping**: Playing SE with the same name consecutively will stop the previous playback and start new playback.
4. **Memory Management**: SE players are automatically pooled and reused after use.

## Related Topics

- [Script Commands - audio](../script/audio-commands.md) - Audio commands in scenario scripts
- [Audio Definitions](../getting-started/audio-setup.md) - How to define audio files
- [Managers Overview](./managers.md) - About other managers
