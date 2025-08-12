# Creating Custom UI

While Argode's AdvScreen provides a robust foundation for dialogue and choices, you'll often need to create custom UI elements for unique game mechanics, inventory screens, character status displays, mini-games, or any other interactive elements that go beyond standard visual novel features.

Argode is designed to integrate seamlessly with any Godot `Control` scene, allowing you to build highly customized interfaces.

## UI Scene Structure Recap

As discussed in the [Creating Interactive UI Scenes](argode-ui-scene.md) guide, your custom UI scene should:

-   Have a `Control` node as its root.
-   Optionally implement the `_setup_argode_references(system_node: Node, screen_node: Node = null)` method to receive the `ArgodeSystem` instance and `AdvScreen` reference.

## Interacting with Argode from Custom UI

Your custom UI scenes can communicate with the Argode system primarily by emitting specific signals.

### Executing Argode Commands

To trigger an Argode command from your custom UI (e.g., a button click that jumps to a new story section, sets a variable, or shows another UI), emit the `argode_command_requested` signal.

**Signal:** `argode_command_requested(command_name: String, parameters: Dictionary)`

**Example:**

```gdscript
# In your custom UI script, e.g., a button's _pressed() function
func _on_load_game_button_pressed():
    # Request Argode to execute the 'load' command
    emit_signal("argode_command_requested", "load", {"slot": 1})
    # Close this UI after the command is requested
    emit_signal("close_screen")

func _on_show_map_button_pressed():
    # Request Argode to show a map UI scene
    emit_signal("argode_command_requested", "ui", {"_raw": "show res://ui/map_screen.tscn"})
```

### Closing Modal UI (`ui call`)

If your UI scene was opened using the `ui call` command (making it modal), you need to signal Argode when it's time to close. You can also return a result.

-   **`close_screen()`**: Closes the UI scene without returning any specific data.
-   **`screen_result(result: Variant)`**: Closes the UI scene and passes a `Variant` value back to Argode. This is useful for choice screens or mini-games that need to return a specific outcome.

**Example:**

```gdscript
# In a choice menu UI script
func _on_choice_a_button_pressed():
    emit_signal("screen_result", "choice_A_selected")

func _on_cancel_button_pressed():
    emit_signal("close_screen")
```

### Accessing Argode System Managers

If you implemented `_setup_argode_references`, you'll have access to the `argode_system` instance, which is the central hub for all Argode managers (e.g., `VariableManager`, `UIManager`, `CharacterManager`).

**Example:**

```gdscript
# In your custom UI script
func _update_player_hp_display():
    if argode_system and argode_system.VariableManager:
        var current_hp = argode_system.VariableManager.get_variable("player_hp")
        $HPLabel.text = "HP: " + str(current_hp)

func _on_show_character_info_button_pressed():
    if argode_system and argode_system.CharacterManager:
        var character_data = argode_system.CharacterManager.get_character_data("alice")
        print("Alice's data: ", character_data)
```

## Integrating Custom UI with RGD Script

Once your custom UI scene is created, you can display and manage it directly from your `.rgd` scripts using the `ui` command.

```rgd
# Show a non-modal inventory screen
ui show "res://ui/inventory_screen.tscn" at center

# Call a modal mini-game and wait for its result
ui call "res://ui/puzzle_game.tscn"

# Hide a custom UI
ui hide "res://ui/inventory_screen.tscn"

# Free a custom UI (remove from memory)
ui free "res://ui/inventory_screen.tscn"
```

## Example Scenarios

### Inventory Screen

An inventory screen could display items stored in an Argode array variable (`set_array inventory [...]`). Buttons for each item could emit `argode_command_requested` to trigger `use_item` or `equip_item` custom commands.

### Character Status Screen

Display character stats (HP, MP, Level) stored in an Argode dictionary variable (`set_dict player_stats {...}`). The UI would read these variables via `argode_system.VariableManager.get_variable()`.

### Mini-game Integration

A custom UI scene could host a simple mini-game. When the mini-game finishes, it emits `screen_result(true)` for success or `screen_result(false)` for failure, allowing the `.rgd` script to branch accordingly after the `ui call` command.

---

By combining Godot's powerful UI tools with Argode's scripting capabilities, you can create truly unique and interactive experiences for your visual novel.
