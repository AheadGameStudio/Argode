# ArgodeSystem API Reference

The `ArgodeSystem` is the central singleton of the Argode framework, providing the core functionalities and acting as the orchestrator for all other managers. It is the primary entry point for integrating Argode into your Godot project.

## Accessing ArgodeSystem

Since `ArgodeSystem` is an autoloaded singleton, you can access it globally from any script in your Godot project:

```gdscript
# Accessing ArgodeSystem
var argode_system = get_node("/root/ArgodeSystem") # If you named your autoload "ArgodeSystem"
# Or, if you set it as a global singleton in Project Settings
# var argode_system = ArgodeSystem
```

## Initialization

Before using Argode's features, you must initialize the system. This is typically done once at the start of your game, usually from your main scene's script.

### `initialize_game(layer_map: Dictionary) -> bool`

This function performs the comprehensive initialization of the Argode framework. It sets up the visual layers, builds asset definitions, and configures the internal managers.

*   **`layer_map` (Dictionary)**: A dictionary mapping layer role names (e.g., `"background"`, `"character"`, `"ui"`, `"effects"`) to their corresponding Godot `CanvasLayer` nodes. This allows Argode to integrate with your custom scene structure.

**Example:**

```gdscript
# In your main scene's _ready() function
func _ready():
    var layer_map = {
        "background": $CanvasLayer_Background,
        "character": $CanvasLayer_Characters,
        "ui": $CanvasLayer_UI,
        "effects": $CanvasLayer_Effects
    }
    if ArgodeSystem.initialize_game(layer_map):
        print("ArgodeSystem initialized successfully!")
    else:
        print("ArgodeSystem initialization failed.")
```

## Script Execution

`ArgodeSystem` provides methods to control the execution of your `.rgd` scripts.

### `start_script(script_path: String, label_name: String = "start")`

Loads and begins execution of an `.rgd` script file from a specified label.

*   **`script_path` (String)**: The `res://` path to the `.rgd` script file (e.g., `"res://scenarios/chapter1.rgd"`).
*   **`label_name` (String)**: (Optional) The name of the label within the script to start execution from. Defaults to `"start"`.

**Example:**

```gdscript
ArgodeSystem.start_script("res://scenarios/main_story.rgd", "prologue")
```

### `next_line()`

Advances the script to the next line. This is typically called in response to user input (e.g., a mouse click or key press) to progress dialogue or narrative.

**Example:**

```gdscript
func _input(event):
    if event.is_action_pressed("ui_accept"):
        ArgodeSystem.next_line()
```

### `is_playing() -> bool`

Returns `true` if an `.rgd` script is currently being played, `false` otherwise.

## Custom Command Management

`ArgodeSystem` provides an API to interact with the `CustomCommandHandler`, allowing you to register and manage your custom GDScript commands.

### `get_custom_command_handler() -> CustomCommandHandler`

Returns the `CustomCommandHandler` instance, providing direct access to its methods for advanced usage.

### `register_custom_command(custom_command: BaseCustomCommand) -> bool`

Registers an instance of a `BaseCustomCommand` (your custom GDScript command) with the framework.

*   **`custom_command` (BaseCustomCommand)**: An instance of your custom command script that extends `BaseCustomCommand`.

### `register_command_by_callable(command_name: String, callable: Callable, is_sync: bool = false) -> bool`

Registers a custom command by associating a command name with a `Callable` (a function or method). This is a convenient way to quickly expose GDScript functions as `.rgd` commands.

*   **`command_name` (String)**: The name of the command as it will appear in `.rgd` scripts (e.g., `"my_effect"`).
*   **`callable` (Callable)**: The `Callable` (e.g., `my_node.my_function`) that will be executed when the command is encountered.
*   **`is_sync` (bool)**: (Optional) If `true`, the script will wait for the `Callable` to complete before proceeding. Defaults to `false` (asynchronous).

### `list_custom_commands() -> Array[String]`

Returns an array of strings containing the names of all currently registered custom commands. Useful for debugging or dynamic command listing.

## Signals

`ArgodeSystem` emits several signals that you can connect to for custom logic or monitoring.

### `system_initialized`

Emitted when the `initialize_game()` function successfully completes all initialization steps.

### `system_error(message: String)`

Emitted when a critical error occurs during ArgodeSystem's initialization or operation. The `message` parameter provides details about the error.

### `definition_loaded(results: Dictionary)`

Emitted after all definition files (e.g., `characters.rgd`, `assets.rgd`) have been loaded and processed. The `results` dictionary contains information about the loaded definitions.

---

[Learn About ScriptPlayer API →](script-player.md){ .md-button }
[Learn About Managers API →](managers.md){ .md-button }