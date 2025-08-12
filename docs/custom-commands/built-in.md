# Built-in Commands

Argode comes with a set of powerful, ready-to-use commands. These are the foundational tools for building your game's logic, managing variables, and creating interactive UI.

All built-in commands are automatically registered and available in your `.rgd` script files. They are located in the `addons/argode/builtin/commands/` directory.

## 🕐 Timing

### `wait`
Pauses the script execution for a specified duration. This is an asynchronous command, meaning it will not freeze the game while waiting.

**Syntax**
```rgd
wait <duration>
```

**Parameters**
- `<duration>` (float): The time to wait in seconds.

**Examples**
```rgd
narrator "Something is about to happen..."
wait 2.5
narrator "There it is!"
```

---

## 🖥️ User Interface

### `ui`
The `ui` command is a versatile tool for managing user interface scenes (`.tscn` files that have a `Control` node as their root). You can use it to display, hide, and manage complex UI elements like menus, HUDs, and choice buttons.

The `ui` command works in conjunction with the `LayerManager`, and it will add UI elements to the layer designated for "ui".

#### `ui show`
Loads and displays a UI scene.

**Syntax**
```rgd
ui show <scene_path> [at <position>] [with <transition>]
```

**Parameters**
- `<scene_path>` (string): The full path to the `.tscn` file (e.g., `"res://scenes/ui/my_menu.tscn"`).
- `at <position>` (string, optional): Where to place the UI. Common values are `center`, `left`, `right`, `top`, `bottom`. Defaults to `center`.
- `with <transition>` (string, optional): A transition effect to use when showing the scene (e.g., `fade`, `dissolve`). Defaults to no transition.

**Example**
```rgd
# Show a status HUD at the top of the screen with a fade-in
ui show "res://ui/hud.tscn" at top with fade
```

#### `ui free`
Removes (frees) a previously shown UI scene.

**Syntax**
```rgd
ui free <scene_path>
ui free all
```

**Parameters**
- `<scene_path>` (string): The path of the scene to remove.
- `all`: If specified, all currently active UI scenes will be removed.

**Example**
```rgd
# Remove the HUD
ui free "res://ui/hud.tscn"
```

#### `ui call`
Displays a UI scene as a **modal screen**. The script will pause and wait until this screen is closed (either by the screen itself or with `ui close`). This is perfect for menus, confirmation dialogs, or any UI that requires user interaction before the story can proceed.

**Syntax**
```rgd
ui call <scene_path> [at <position>] [with <transition>]
```

**Example**
```rgd
# Show a choice menu and wait for the player to decide
ui call "res://ui/choice_menu.tscn"
# The script will only continue after the choice menu is closed.
narrator "You made a choice."
```

#### `ui close`
Closes a UI scene that was opened with `ui call`. If multiple screens were called, it will close the most recent one.

**Syntax**
```rgd
ui close
ui close <scene_path>
```

**Parameters**
- `<scene_path>` (string, optional): The specific scene to close. If omitted, closes the last screen that was called.

**Example**
```gdscript
# In your choice_menu.tscn script, when a button is pressed:
func _on_Button_pressed():
    # This will close the menu and resume the rgd script
    emit_signal("close_screen") 
```
```rgd
# Alternatively, from another event in your script
ui close "res://ui/choice_menu.tscn"
```

#### `ui list`
Prints a list of all currently active UI scenes to the console. This is a useful debugging tool.

**Syntax**
```rgd
ui list
```

---

## 📦 Variable Management

These commands allow you to create and modify complex data types like arrays and dictionaries directly from your scripts. They work with the `VariableManager`.

### `set_array`
Creates or overwrites a variable with a new array. The array is defined using a Godot-like array literal format.

**Syntax**
```rgd
set_array <variable_name> [value1, value2, "string_value", ...]
```

**Parameters**
- `<variable_name>` (string): The name of the variable to set (e.g., `inventory`, `quest_flags`).
- The second argument must be a string literal enclosed in `[]` representing the array.

**Example**
```rgd
# Initialize an inventory for the player
set_array inventory ["sword", "shield", "potion"]

# You can then access it using standard variable syntax
narrator "You have a {inventory[0]}."
```

### `set_dict`
Creates or overwrites a variable with a new dictionary. The dictionary is defined using a Godot-like dictionary literal format.

**Syntax**
```rgd
set_dict <variable_name> {key1: value1, "key2": "string_value", ...}
```

**Parameters**
- `<variable_name>` (string): The name of the variable to set (e.g., `player_stats`, `item_properties`).
- The second argument must be a string literal enclosed in `{}` representing the dictionary.

**Example**
```rgd
# Define stats for a character
set_dict player_stats {"name": "Yuko", "level": 5, "hp": 100, "mp": 50}

# Access the stats
narrator "Character: {player_stats.name}, Level: {player_stats.level}"
```