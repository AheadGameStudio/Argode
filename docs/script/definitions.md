# Definitions Reference

Definitions in Argode allow you to pre-define various assets and entities, making them easily accessible and reusable throughout your visual novel scripts. By centralizing your definitions, you can keep your main story scripts clean and focused on the narrative flow.

## Definition Files

While you can place definitions anywhere in your `.rgd` files, it's highly recommended to organize them into dedicated definition files within the `definitions/` directory (e.g., `definitions/characters.rgd`, `definitions/assets.rgd`). Argode automatically loads all `.rgd` files found in this directory at startup.

## Types of Definitions

### Character Definitions (`character`)

Define your characters, including their display name and an optional default color for their dialogue.

**Syntax:**
```rgd
character <name> "<display_name>" [color=<hex_color>]
```

-   `<name>`: A unique identifier for the character (e.g., `alice`, `narrator`). This is what you'll use in your script.
-   `<display_name>`: The name that will be displayed in the dialogue box.
-   `color`: (Optional) A hexadecimal color code (e.g., `#ff69b4`) for the character's dialogue text.

**Example:**

```rgd
character alice "Alice" color=#ff69b4
character bob "Bob" color=#87ceeb
character narrator "Narrator" color=#ffffff
```

**Usage in Script:**

```rgd
alice "Hello, Bob!"
bob "Hi, Alice!"
narrator "They greeted each other."
```

### Image Definitions (`image`)

Define images (backgrounds, character sprites, CGs) with a tag and a name, mapping them to their file paths. This allows you to refer to images by a simple name in your script instead of a long path.

**Syntax:**
```rgd
image <tag> <name> "<path_to_image>"
```

-   `<tag>`: A category for the image (e.g., `bg` for backgrounds, `char` for character sprites, `cg` for CGs).
-   `<name>`: A unique identifier for the image within its tag (e.g., `forest_day`, `alice_happy`).
-   `<path_to_image>`: The resource path to the image file (e.g., `"res://assets/images/backgrounds/forest_day.png"`).

**Example:**

```rgd
image bg forest_day "res://assets/images/backgrounds/forest_day.png"
image bg city_night "res://assets/images/backgrounds/city_night.png"
image char alice_happy "res://assets/images/characters/alice_happy.png"
```

**Usage in Script:**

```rgd
scene forest_day with fade # Uses the 'bg' tag implicitly
show alice_happy at center # Uses the 'char' tag implicitly
```

### Audio Definitions (`audio`)

Define audio files (music, sound effects) with a tag and a name, mapping them to their file paths. This simplifies playing audio in your script.

**Syntax:**
```rgd
audio <tag> <name> "<path_to_audio>"
```

-   `<tag>`: A category for the audio (e.g., `music` for background music, `sfx` for sound effects).
-   `<name>`: A unique identifier for the audio within its tag (e.g., `peaceful`, `door_open`).
-   `<path_to_audio>`: The resource path to the audio file (e.g., `"res://assets/audio/music/peaceful.ogg"`).

**Example:**

```rgd
audio music peaceful "res://assets/audio/music/peaceful.ogg"
audio sfx door_open "res://assets/audio/sfx/door_open.wav"
```

**Usage in Script:**

```rgd
play_music peaceful
play_sound door_open
```

### Shader Definitions (`shader`)

Define custom shaders that can be applied to the screen or specific layers.

**Syntax:**
```rgd
shader <name> "<path_to_shader>"
```

-   `<name>`: A unique identifier for the shader (e.g., `blur`, `grayscale`).
-   `<path_to_shader>`: The resource path to the shader file (e.g., `"res://shaders/blur.gdshader"`).

**Example:**

```rgd
shader blur_effect "res://shaders/blur_effect.gdshader"
```

**Usage in Script:**

```rgd
screen_shader blur_effect intensity=0.5
```

## Best Practices

-   **Centralize Definitions:** Keep all your definitions in the `definitions/` folder for easy management and overview.
-   **Consistent Naming:** Use clear and consistent naming conventions for your definition names and tags.
-   **Categorize with Tags:** Utilize tags (for images and audio) to logically group your assets.

---

By effectively using definitions, you can make your Argode scripts cleaner, more readable, and easier to maintain.
