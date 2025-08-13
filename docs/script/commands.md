# Commands Reference

Commands are the core building blocks of your Argode visual novel script. They are instructions that tell the ArgodeSystem to perform specific actions, such as displaying characters, changing backgrounds, playing sounds, or controlling the user interface.

## General Command Syntax

Most commands follow a simple syntax:

```rgd
command_name [positional_argument_1] [positional_argument_2] ... [keyword_argument_1=value_1] [keyword_argument_2="value_2"]
```

-   **`command_name`**: The name of the command (e.g., `show`, `scene`, `wait`, `ui`).
-   **Positional Arguments**: Values passed to the command based on their order. These are typically used for the most common or primary parameters.
-   **Keyword Arguments**: Parameters specified by `key=value`. These are optional and can be provided in any order.

**Examples:**

```rgd
# Positional arguments
show alice happy at center

# Keyword arguments
show alice expression=happy position=center

# Mixed arguments
show alice happy at center with fade duration=1.0
```

## Types of Commands

Argode supports two main types of commands:

### Built-in Commands

These are commands that come bundled with the Argode framework. They provide essential functionalities for common visual novel tasks. You can find a comprehensive list and detailed usage instructions in the [Built-in Commands Reference](../custom-commands/built-in.md).

**Examples:**

```rgd
wait 2.5
ui show "res://ui/main_menu.tscn"
set_array inventory ["sword", "potion"]
```

### Custom Commands

Custom commands allow you to extend Argode's functionality by creating your own commands tailored to your game's specific needs. They are implemented as Godot scripts and are automatically discovered by Argode.

Learn how to create your own custom commands in the [Custom Commands Overview](../custom-commands/overview.md).

**Examples:**

```rgd
# Assuming you created a custom 'shake_screen' command
shake_screen intensity=5.0 duration=0.5

# Assuming you created a custom 'add_item' command
add_item "Magic Sword" quantity=1
```

## Common Command Categories

While the full list of commands is in the [Built-in Commands Reference](../custom-commands/built-in.md), here are some common categories you'll encounter:

-   **Dialogue & Character Control:** Commands for displaying dialogue, showing/hiding characters, and managing their expressions and positions.
    -   Examples: `show`, `hide`, `scene`, `character` (for definitions)
-   **Flow Control:** Commands that manage the narrative progression, branching, and subroutines.
    -   Examples: `jump`, `call`, `return`, `menu`
-   **UI Control:** Commands for displaying, hiding, and managing custom UI scenes.
    -   Examples: `ui` (with its subcommands like `show`, `call`, `free`)
-   **Variable Management:** Commands for setting and manipulating game variables.
    -   Examples: `set`, `set_array`, `set_dict`
-   **Timing:** Commands for pausing script execution.
    -   Examples: `wait`
-   **Audio:** Commands for playing background music and sound effects.
    -   Examples: `play_music`, `stop_music`, `play_sound`

---

This overview provides a general understanding of commands in Argode. For detailed information on each built-in command, please refer to the [Built-in Commands Reference](../custom-commands/built-in.md).
