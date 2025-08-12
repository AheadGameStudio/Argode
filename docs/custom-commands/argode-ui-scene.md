# Creating Interactive UI Scenes

Argode allows you to integrate custom Godot UI scenes (`.tscn` files with a `Control` node as their root) directly into your visual novel flow using the `ui` command. These scenes can be simple displays or complex interactive elements like menus, inventory screens, or mini-games.

## 🎨 UI Scene Structure

To make your UI scene interact seamlessly with Argode, follow these guidelines:

1.  **Root Node:** The root node of your scene **must be a `Control` node**.
2.  **Script:** Attach a script to your root `Control` node.
3.  **Optional `_setup_argode_references` Method:** Implement this method in your UI scene's script. The `ui` command will call this method to inject the `ArgodeSystem` instance and other useful references.

```gdscript
# Your UI Scene's Script (e.g., MyMenu.gd)
extends Control

# These will be automatically set by the UICommand
var argode_system: Node = null
var adv_screen: Node = null # Reference to the main message window (AdvScreen)

# This method is called by UICommand to inject Argode references.
# It's a good place to initialize your UI based on game state.
func _setup_argode_references(system_node: Node, screen_node: Node = null):
    self.argode_system = system_node
    self.adv_screen = screen_node
    print("UI Scene: Argode references set!")
    
    # Example: Get a variable from the game state
    var player_name = argode_system.VariableManager.get_variable("player_name")
    if player_name:
        print("Hello, " + player_name)

func _ready():
    # Your UI initialization logic here
    pass
```

## 📡 Interacting with Argode

Your UI scene can interact with the Argode system by emitting specific signals. The `UICommand` listens for these signals and acts accordingly.

### 1. Executing Argode Commands from UI

If your UI needs to trigger an Argode command (e.g., `jump` to a new label, `set` a variable, or `show` a character), emit the `argode_command_requested` signal.

**Signal:** `argode_command_requested(command_name: String, parameters: Dictionary)`

**Example:**
```gdscript
# In your UI scene's script (e.g., a button's _pressed() function)
func _on_start_game_button_pressed():
    # Request Argode to jump to the 'prologue' label
    emit_signal("argode_command_requested", "jump", {"label": "prologue"})
    
    # Request Argode to set a variable
    emit_signal("argode_command_requested", "set", {"name": "game_started", "value": true})
```

### 2. Closing `ui call` Screens and Returning Results

When you use `ui call` to display a modal UI (like a menu or a choice screen), the Argode script waits for that UI to close. Your UI scene should emit one of two signals to indicate it's done:

-   **`close_screen()`**: Closes the UI scene without returning any specific result. The Argode script will simply resume.
-   **`screen_result(result: Variant)`**: Closes the UI scene and passes a `Variant` value back to the Argode system. This result can then be accessed in your `.rgd` script (though direct access in `.rgd` is not yet implemented, it's useful for internal logic).

**Example:**
```gdscript
# In your UI scene's script (e.g., a choice button's _pressed() function)
func _on_choice_a_button_pressed():
    # Close the UI and return a string result
    emit_signal("screen_result", "choice_A_made")

func _on_cancel_button_pressed():
    # Close the UI without returning a specific result
    emit_signal("close_screen")
```

## 📚 Accessing Argode System Functionalities

Through the `argode_system` reference injected by `_setup_argode_references`, your UI scene can access various Argode managers and functionalities:

```gdscript
# Example: Accessing VariableManager
func _get_player_level():
    if argode_system and argode_system.VariableManager:
        return argode_system.VariableManager.get_variable("player_level")
    return 0

# Example: Showing a message via UIManager (if UIManager exposes such a method)
func _show_game_message(text: String):
    if argode_system and argode_system.UIManager:
        # Assuming UIManager has a method like show_message_window
        argode_system.UIManager.show_message_window(text)
```

## 🎬 Example: Simple Title Screen

Here's a basic example of a title screen that interacts with Argode:

**Scene Setup:**
- Root Node: `Control` (named `TitleScreen`) with script `TitleScreen.gd` attached.
- Child Nodes: `Button` (named `StartButton`), `Button` (named `ExitButton`).

**`TitleScreen.gd`:**
```gdscript
# res://scenes/ui/TitleScreen.gd
extends Control

var argode_system: Node = null

func _setup_argode_references(system_node: Node, _screen_node: Node = null):
    self.argode_system = system_node
    print("TitleScreen: ArgodeSystem reference set.")

func _ready():
    $StartButton.pressed.connect(_on_StartButton_pressed)
    $ExitButton.pressed.connect(_on_ExitButton_pressed)

func _on_StartButton_pressed():
    # Request Argode to jump to the 'start_game' label
    emit_signal("argode_command_requested", "jump", {"label": "start_game"})
    # Request to close this title screen
    emit_signal("close_screen")

func _on_ExitButton_pressed():
    # Request Argode to quit the game (assuming a 'quit' command exists)
    emit_signal("argode_command_requested", "quit", {})
    # Request to close this title screen
    emit_signal("close_screen")
```

## 📜 Using UI Scenes in Scripts

Once your UI scene is set up, you can use it in your `.rgd` scripts with the `ui` command:

```rgd
# Display a UI scene (non-modal)
ui show "res://scenes/ui/TitleScreen.tscn" at center with fade

# Call a UI scene (modal - script waits for it to close)
ui call "res://scenes/ui/ChoiceMenu.tscn"

# Hide a UI scene
ui hide "res://scenes/ui/TitleScreen.tscn"

# Free a UI scene
ui free "res://scenes/ui/TitleScreen.tscn"
```

---

By following these guidelines, you can create rich, interactive user interfaces that seamlessly integrate with your Argode visual novel.