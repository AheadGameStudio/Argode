# AdvScreen System

AdvScreen is Argode's powerful and flexible system for displaying dialogue, choices, and other interactive elements in your visual novel. It serves as the primary message window and UI container, designed for rich customization and seamless integration with your RGD scripts.

## Core Components

AdvScreen is managed by the `UIManager`, which handles its lifecycle, content display, and interaction with the ArgodeSystem. It's designed to be highly customizable, allowing you to change its appearance and behavior to match your game's aesthetic.

## Customization

AdvScreen's appearance can be extensively customized through Godot's theming system. You can define custom styles, fonts, and colors to create a unique look for your game.

For more details on customizing the look and feel, refer to the [Theming Guide](themes.md).

If you need to create entirely custom UI elements or integrate complex Godot scenes, refer to the [Custom UI Guide](custom.md).

## Interaction with RGD Script

AdvScreen automatically displays dialogue and presents choices based on your RGD script commands.

### Displaying Dialogue

When your script encounters a dialogue line, AdvScreen will display the character's name (if specified) and their dialogue text.

```rgd
character alice "Alice"

alice "Hello, player!"
narrator "This is a narration."
```

### Presenting Choices

The `menu` command in your RGD script will trigger AdvScreen to display a list of choices to the player. The script will pause until a selection is made.

```rgd
menu:
    "Option A":
        narrator "You chose A."
    "Option B":
        narrator "You chose B."
```

### Integration with `ui` Command

The `ui` command can be used to show or hide the AdvScreen itself, or to display other custom UI scenes on top of it.

```rgd
# Hide the AdvScreen (message window)
ui hide advscreen

# Show the AdvScreen
ui show advscreen

# Display a custom menu over AdvScreen
ui call "res://ui/my_custom_menu.tscn"
```

## Key Features

-   **Text Animation:** Supports various text animation effects for dynamic dialogue presentation.
-   **Name Box:** Dedicated area for displaying the speaking character's name.
-   **Dialogue History:** Players can review past dialogue lines.
-   **Auto-Forward:** Automatically advances dialogue after a set delay.
-   **Click-to-Continue:** Requires player input to advance dialogue.

---

AdvScreen is a powerful tool for creating engaging and visually appealing dialogue experiences in your Argode visual novel.
