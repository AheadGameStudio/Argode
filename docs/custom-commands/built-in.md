# Built-in Custom Commands

Argode includes a comprehensive set of pre-built custom commands that you can use immediately in your visual novels. These commands demonstrate best practices and provide common functionality out of the box.

## 🪟 Window Operations

### `window shake`
Shake the game window for dramatic effect.

```rgd
window shake intensity=5.0 duration=0.5
window shake 3.0 0.8  # Positional parameters
```

**Parameters:**
- `intensity` (float): Shake strength (default: 5.0)
- `duration` (float): Duration in seconds (default: 0.5)

**Use Cases:**
- Explosions and impacts
- Earthquake scenes  
- Dramatic reveals

---

### `window fullscreen`
Toggle fullscreen mode.

```rgd
window fullscreen true
window fullscreen false
window fullscreen toggle  # Toggles current state
```

**Parameters:**
- `state` (bool/string): `true`, `false`, or `"toggle"`

---

### `window minimize`
Minimize the game window.

```rgd
window minimize
```

**Use Cases:**
- Easter eggs
- Breaking the fourth wall
- Special story moments

## 📹 Camera Effects

### `camera_shake`  
Shake the camera/screen for visual impact.

```rgd
camera_shake intensity=2.0 duration=0.5 type=both
camera_shake 3.0 1.0 horizontal  # Positional parameters
```

**Parameters:**
- `intensity` (float): Shake strength (default: 1.0)
- `duration` (float): Duration in seconds (default: 0.5)  
- `type` (string): Direction - `both`, `horizontal`, `vertical` (default: both)

**Examples:**
```rgd
# Subtle character emotion
camera_shake intensity=0.5 duration=0.2 type=horizontal

# Major explosion
camera_shake intensity=8.0 duration=1.5 type=both

# Vertical impact
camera_shake intensity=3.0 duration=0.8 type=vertical
```

## 🎨 Screen Effects

### `screen_tint`
Apply a color tint to the entire screen.

```rgd
screen_tint color=#ff0000 intensity=0.3 duration=1.0
screen_tint red 0.5 2.0  # Positional parameters
```

**Parameters:**
- `color` (Color): Tint color (default: #ffffff)
- `intensity` (float): Tint strength 0.0-1.0 (default: 0.5)
- `duration` (float): Fade-in duration (default: 1.0)

**Use Cases:**
```rgd
# Danger/anger scene
screen_tint color=#ff0000 intensity=0.2 duration=0.5

# Sadness/melancholy  
screen_tint color=#0066ff intensity=0.3 duration=2.0

# Sickness/poison
screen_tint color=#00ff00 intensity=0.4 duration=1.0

# Remove tint
screen_tint color=#ffffff intensity=0.0 duration=1.5
```

---

### `screen_flash`
Quick screen flash effect.

```rgd
screen_flash color=#ffffff duration=0.1 intensity=1.0
screen_flash white 0.05  # Positional parameters
```

**Parameters:**
- `color` (Color): Flash color (default: #ffffff) 
- `duration` (float): Flash duration (default: 0.1)
- `intensity` (float): Flash brightness (default: 1.0)

**Examples:**
```rgd
# Lightning flash
screen_flash color=#ffffff duration=0.05 intensity=0.8

# Magic spell effect  
screen_flash color=#ff00ff duration=0.2 intensity=0.6

# Camera flash
screen_flash color=#ffffff duration=0.1 intensity=1.0
```

---

### `screen_blur` 
Apply blur effect to the screen.

```rgd
screen_blur intensity=2.0 duration=0.5
screen_blur 1.5 1.0  # Positional parameters
```

**Parameters:**
- `intensity` (float): Blur amount (default: 1.0)
- `duration` (float): Transition duration (default: 0.5)

**Use Cases:**
```rgd
# Character loses focus
screen_blur intensity=3.0 duration=1.0

# Dream sequence start
screen_blur intensity=2.0 duration=2.0

# Remove blur
screen_blur intensity=0.0 duration=1.0
```

## 🎵 Audio Commands

### `play_sound`
Play a sound effect.

```rgd
play_sound "door_open.wav" volume=1.0
play_sound footsteps.ogg 0.8  # Positional parameters
```

**Parameters:**
- `file` (string): Audio file path
- `volume` (float): Volume 0.0-1.0 (default: 1.0)

---

### `play_music`
Play background music with optional fade.

```rgd
play_music "theme.ogg" volume=0.7 fade_in=2.0
play_music battle_music.ogg  # Positional parameters
```

**Parameters:**
- `file` (string): Music file path
- `volume` (float): Volume 0.0-1.0 (default: 0.8)
- `fade_in` (float): Fade-in duration (default: 0.0)

---

### `stop_music`
Stop background music with optional fade-out.

```rgd
stop_music fade_out=1.5
stop_music 2.0  # Positional parameter
```

**Parameters:**
- `fade_out` (float): Fade-out duration (default: 0.0)

## ✨ Particle Effects

### `particle_effect`
Create particle effects at specified positions.

```rgd
particle_effect explosion x=400 y=300 scale=1.0
particle_effect snow x=640 y=100 scale=0.5
```

**Parameters:**
- `type` (string): Effect type (`explosion`, `snow`, `fire`, `sparkle`)
- `x` (float): X position (default: screen center)
- `y` (float): Y position (default: screen center)  
- `scale` (float): Effect scale (default: 1.0)

**Built-in Effect Types:**
- `explosion`: Fiery explosion with debris
- `snow`: Gentle falling snow
- `fire`: Flickering flames
- `sparkle`: Magical sparkles
- `smoke`: Rising smoke clouds

## 🎭 Layer Effects

### `layer_tint`
Apply tint to specific layers.

```rgd
layer_tint background color=#0066cc intensity=0.5 duration=1.0
layer_tint characters red 0.3 2.0  # Positional parameters
```

**Parameters:**
- `layer` (string): Layer name (`background`, `characters`, `ui`)
- `color` (Color): Tint color
- `intensity` (float): Tint strength 0.0-1.0
- `duration` (float): Transition duration

**Examples:**
```rgd
# Sunset lighting on background
layer_tint background color=#ff8800 intensity=0.4 duration=3.0

# Character in shadow
layer_tint characters color=#000066 intensity=0.6 duration=1.0
```

## 🕐 Timing Commands

### `wait`  
Pause script execution for specified duration.

```rgd
wait duration=2.0
wait 1.5  # Positional parameter
```

**Parameters:**
- `duration` (float): Wait time in seconds

**Use Cases:**
```rgd
narrator "Something is about to happen..."
wait 2.0
screen_flash
narrator "There it is!"
```

---

### `wait_for_input`
Wait for player input before continuing.

```rgd
wait_for_input message="Press any key to continue"
wait_for_input  # Uses default message
```

**Parameters:**
- `message` (string): Instruction text (optional)

## 💾 Save System Commands

### `quicksave`
Create a quick save at current position.

```rgd
quicksave slot=1 message="Progress saved!"
quicksave  # Uses default slot
```

**Parameters:**
- `slot` (int): Save slot number (default: 1)
- `message` (string): Confirmation message (optional)

---

### `quickload`  
Load from quick save slot.

```rgd
quickload slot=1
quickload  # Loads from default slot
```

**Parameters:**
- `slot` (int): Save slot number (default: 1)

## 🎮 Advanced Examples

### Combining Commands
```rgd
label dramatic_reveal:
    narrator "The truth is about to be revealed..."
    
    # Build tension
    camera_shake intensity=1.0 duration=0.5 type=horizontal
    wait 0.5
    
    # Major revelation
    screen_flash color=#ffffff duration=0.1
    screen_tint color=#ff0000 intensity=0.3 duration=0.5
    window shake intensity=8.0 duration=1.0
    play_sound "dramatic_sting.wav" volume=1.0
    
    narrator "I am your father!"
    
    # Calm down
    wait 2.0
    screen_tint color=#ffffff intensity=0.0 duration=2.0
```

### Atmospheric Scene
```rgd  
label forest_night:
    scene bg_forest_night with fade
    
    # Set night atmosphere
    screen_tint color=#000066 intensity=0.4 duration=2.0
    layer_tint background color=#001122 intensity=0.6 duration=2.0
    play_music "night_ambience.ogg" volume=0.5 fade_in=3.0
    
    # Add environmental effects
    particle_effect snow x=320 y=100 scale=0.3
    wait 1.0
    particle_effect snow x=500 y=150 scale=0.4
    
    alice "It's getting cold..."
```

## 🔧 Implementation Notes

All built-in custom commands are implemented in `CustomCommandHandler.gd` and follow these patterns:

- **Parameter validation**: All inputs are validated and clamped to safe ranges
- **Error handling**: Invalid parameters generate warnings instead of crashes
- **Async support**: Long-running commands properly signal completion
- **Resource cleanup**: Effects are automatically cleaned up when scenes change

## 📚 Next Steps

- **[Creating Custom Commands](creating.md)**: Build your own commands
- **[Advanced Patterns](../examples/custom-features.md)**: Complex command combinations
- **[Performance Tips](../advanced/performance.md)**: Optimizing command usage

---

These built-in commands provide a solid foundation for most visual novel needs. Combined with the ability to create your own custom commands, Argode offers unlimited creative possibilities!

[Learn to Create Commands →](creating.md){ .md-button .md-button--primary }
[View Examples →](../examples/custom-features.md){ .md-button }
