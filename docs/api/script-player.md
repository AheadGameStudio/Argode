# ScriptPlayer API Reference

The `ScriptPlayer` is the core component responsible for interpreting and executing your `.rgd` script files. It manages the flow of your narrative, processes commands, and handles interactions with other Argode managers. While `ScriptPlayer` is an internal component of `ArgodeSystem`, its key functionalities are exposed through `ArgodeSystem`'s public API for ease of use.

## Core Functionalities

### Loading and Starting Scripts

The `ScriptPlayer` loads your `.rgd` files and begins execution from a specified point.

#### `load_script(path: String)`

Loads an `.rgd` script file into the `ScriptPlayer`. This prepares the script for execution but does not start it immediately.

*   **`path` (String)**: The `res://` path to the `.rgd` script file (e.g., `"res://scenarios/chapter1.rgd"`).

**Example:**

```gdscript
ArgodeSystem.Player.load_script("res://scenarios/my_story.rgd")
```

#### `play_from_label(label_name: String)`

Starts or resumes script execution from a specific `label` within the currently loaded script. If the label is in a different `.rgd` file, `ScriptPlayer` will attempt a cross-file jump using the `LabelRegistry`.

*   **`label_name` (String)**: The name of the `label` to jump to (e.g., `"start"`, `"chapter_2_intro"`).

**Example:**

```gdscript
# After loading a script
ArgodeSystem.Player.play_from_label("start")

# Or, as part of ArgodeSystem's public API
ArgodeSystem.start_script("res://scenarios/my_story.rgd", "start")
```

### Advancing the Script

#### `next()`

Advances the script to the next line of execution. This method is typically called by `ArgodeSystem.next_line()` in response to user input (e.g., a mouse click to advance dialogue).

**Example:**

```gdscript
# In your input handler
func _input(event):
    if event.is_action_pressed("ui_accept"):
        ArgodeSystem.next_line() # This calls ScriptPlayer.next() internally
```

### Script State

#### `is_playing() -> bool`

Returns `true` if the `ScriptPlayer` is currently executing an `.rgd` script, `false` otherwise.

## Flow Control

The `ScriptPlayer` handles various flow control commands defined in `.rgd` scripts, including `jump`, `call`, `return`, `if`/`else`, and `menu`.

### `on_choice_selected(choice_index: int)`

This method is called by the `UIManager` when a user makes a selection from a `menu` command. It directs the `ScriptPlayer` to the appropriate branch of the script based on the chosen option.

*   **`choice_index` (int)**: The 0-based index of the selected choice.

**Example (Internal Call):**

```gdscript
# UIManager calls this after a choice is made
ArgodeSystem.Player.on_choice_selected(selected_index)
```

### External Call/Return (for UI Integration)

These methods are primarily used by `AdvScreen` nodes or other custom Godot scenes that need to temporarily take control of the script flow and then return.

#### `call_label(label_name: String)`

Pushes the current script position onto a call stack and jumps to the specified `label`. This is similar to the `.rgd` `call` command but can be triggered from GDScript.

*   **`label_name` (String)**: The name of the `label` to call.

**Example:**

```gdscript
# From an AdvScreen script
ArgodeSystem.Player.call_label("game_over_scene")
```

#### `return_from_call()`

Pops the last position from the call stack and resumes script execution from that point. This is similar to the `.rgd` `return` command.

**Example:**

```gdscript
# From an AdvScreen script, after a modal screen is closed
ArgodeSystem.Player.return_from_call()
```

## Signals

The `ScriptPlayer` emits signals to notify other parts of the system about its state changes or events.

### `script_finished`

Emitted when the `ScriptPlayer` reaches the end of the currently loaded script.

### `custom_command_executed(command_name: String, parameters: Dictionary, line: String)`

Emitted when the `ScriptPlayer` encounters a command in an `.rgd` script that is not a built-in command. This signal is primarily used by the `CustomCommandHandler` to dispatch to your custom GDScript logic.

*   **`command_name` (String)**: The name of the custom command.
*   **`parameters` (Dictionary)**: A dictionary containing the parsed parameters of the custom command.
*   **`line` (String)**: The full original line from the `.rgd` script.

---

[Learn About ArgodeSystem API →](argode-system.md){ .md-button }
[Learn About Managers API →](managers.md){ .md-button }