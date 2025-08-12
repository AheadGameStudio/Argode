# Advanced Features Example

This example showcases some of Argode's more advanced features, including complex UI interactions, variable manipulation, conditional logic, and the use of both synchronous and asynchronous custom commands.

## Features Demonstrated

-   **Complex UI Interaction:** Using `ui call` for modal screens and returning results via `screen_result`.
-   **Variable Manipulation:** Utilizing `set_array` and `set_dict` for structured data, and `set` for basic variables.
-   **Conditional Logic:** Branching story paths based on variable values using `if`, `elif`, `else`.
-   **Synchronous Custom Commands:** Commands that pause the script until their completion (e.g., a custom screen effect).
-   **Asynchronous Custom Commands:** Commands that run in the background without blocking the script (e.g., playing a sound).
-   **Definition Usage:** Leveraging pre-defined characters, images, and audio.

## Project Structure

To run this example, you will need:

-   `ArgodeSystem` set up as an Autoload.
-   A main Godot scene (e.g., `Main.tscn`) to start the script.
-   The RGD script file for this example (e.g., `scenarios/advanced_demo.rgd`).
-   Custom command `.gd` files (e.g., `res://custom/commands/ScreenEffectCommand.gd`, `res://custom/commands/PlaySoundCommand.gd`).
-   Custom UI `.tscn` files (e.g., `res://ui/choice_dialog.tscn`, `res://ui/inventory_screen.tscn`).
-   Necessary assets (images, audio).

## Code Example: `scenarios/advanced_demo.rgd`

```rgd
# --- Definitions (can be in separate files) ---
character narrator "Narrator" color=#ffffff
character alice "Alice" color=#ff69b4

image bg laboratory "res://assets/images/backgrounds/laboratory.png"
image char alice_shocked "res://assets/images/characters/alice_shocked.png"

audio sfx alarm "res://assets/audio/sfx/alarm.ogg"

# --- Story Start ---
label start:
    narrator "Welcome to the Advanced Features Demo!"
    narrator "This demo will show you some powerful Argode capabilities."

    scene laboratory with fade
    show alice_shocked at center with dissolve

    # --- Complex UI Interaction (Modal Dialog) ---
    narrator "An alarm blares! What will you do?"
    play_sound sfx alarm # Asynchronous command

    # Call a custom UI scene (modal) and get a result
    ui call "res://ui/choice_dialog.tscn" # Assuming this UI returns a result

    # The script pauses here until choice_dialog.tscn emits screen_result or close_screen
    # The result from screen_result will be stored internally by UICommand
    # For this example, we'll assume the result is accessible or handled by a custom command

    # --- Conditional Logic based on assumed UI result (for demonstration) ---
    # In a real scenario, you'd check the result returned by the UICommand
    # For now, let's simulate a choice result for branching
    set player_choice = "investigate"

    if player_choice == "investigate":
        narrator "You bravely decide to investigate the source of the alarm."
        jump investigate_alarm
    elif player_choice == "hide":
        narrator "You decide to hide and wait it out."
        jump hide_and_wait
    else:
        narrator "You hesitate, unsure what to do."
        jump hesitate

# --- Branch: Investigate Alarm ---
label investigate_alarm:
    narrator "You cautiously approach the source of the sound."
    # Synchronous custom command (assumed to be implemented in custom/commands/ScreenEffectCommand.gd)
    screen_effect type="flash" color=#FF0000 duration=0.5 # This command blocks
    narrator "A blinding light erupts!"

    # Variable manipulation with arrays
    set_array discovered_items ["strange_device", "glowing_crystal"]
    narrator "You found a {discovered_items[0]} and a {discovered_items[1]}!"

    jump end_demo

# --- Branch: Hide and Wait ---
label hide_and_wait:
    narrator "You find a good hiding spot and wait for the alarm to stop."
    wait 3.0 # Built-in synchronous command
    narrator "The alarm eventually fades. You emerge cautiously."

    # Variable manipulation with dictionaries
    set_dict player_status {"safe": true, "curiosity": "low"}
    narrator "Your status: Safe ({player_status.safe}), Curiosity: {player_status.curiosity}."

    jump end_demo

# --- Branch: Hesitate ---
label hesitate:
    narrator "Your indecision costs you. The alarm continues, and you feel a sense of dread."
    jump end_demo

# --- End of Demo ---
label end_demo:
    hide alice_shocked with dissolve
    scene black with fade # Assuming 'black' is a defined black background
    narrator "This concludes the Advanced Features Demo."
    narrator "Explore the code and documentation to learn more!"
    # End of script
```

## Custom Command/UI Code Snippets

### `res://custom/commands/ScreenEffectCommand.gd` (Synchronous Example)

```gdscript
# A simplified example of a synchronous screen effect command
extends BaseCustomCommand

func _init():
    command_name = "screen_effect"
    help_text = "screen_effect type=<type> color=<color> duration=<duration>"

func is_synchronous() -> bool:
    return true # This command blocks the script

func execute_internal_async(parameters: Dictionary, adv_system: Node) -> void:
    var type = parameters.get("type", "flash")
    var color = parameters.get("color", Color.WHITE)
    var duration = parameters.get("duration", 0.1)

    # Assuming LayerManager has a method to handle screen effects
    if adv_system.LayerManager:
        await adv_system.LayerManager.apply_screen_effect(type, color, duration)
    else:
        print("LayerManager not available for screen effect.")
    log_command("Screen effect '" + type + "' applied.")
```

### `res://ui/choice_dialog.tscn` (Modal UI Example)

This is a simple UI scene that would be opened by `ui call` and emit `screen_result`.

**`choice_dialog.gd` (script attached to the Control node of `choice_dialog.tscn`):**

```gdscript
extends Control

# Signals to communicate with ArgodeSystem
signal screen_result(result: Variant)
signal close_screen()

func _on_investigate_button_pressed():
    emit_signal("screen_result", "investigate")

func _on_hide_button_pressed():
    emit_signal("screen_result", "hide")

func _on_hesitate_button_pressed():
    emit_signal("screen_result", "hesitate")
```

## How to Run This Example

1.  **Ensure Argode is installed** and `ArgodeSystem` is set up as an Autoload.
2.  **Create the `scenarios` folder** and save the `advanced_demo.rgd` script there.
3.  **Create `custom/commands` folder** and save `ScreenEffectCommand.gd` there.
4.  **Create `ui` folder** and save `choice_dialog.tscn` and its script `choice_dialog.gd` there.
5.  **Prepare Assets:** Ensure you have placeholder images for `laboratory.png` and `alice_shocked.png`, and an audio file for `alarm.ogg` at the specified paths.
6.  **Main Scene:** Use a `Main.tscn` similar to the Simple VN example to start `advanced_demo.rgd`.
7.  **Run:** Press `F5` to run your project.

## Next Steps

-   Experiment with different parameters for `screen_effect`.
-   Implement `PlaySoundCommand.gd` as an asynchronous command.
-   Create more complex UI scenes that interact with Argode variables.

---

This example provides a foundation for building highly interactive and dynamic visual novels with Argode.
