# Simple Visual Novel Example

This example demonstrates the core functionalities of Argode by presenting a basic visual novel story. It covers character definitions, dialogue, background changes, character display, choice menus, and basic flow control.

## Features Demonstrated

-   **Character Definitions:** Defining characters with names and colors.
-   **Dialogue System:** Displaying character dialogue and narrator text.
-   **Background Management:** Changing scenes with transitions.
-   **Character Display:** Showing and hiding characters with expressions and positions.
-   **Choice Menus:** Presenting player choices that lead to branching paths.
-   **Flow Control:** Using `jump` to navigate between story sections.

## Project Structure

To run this example, you would typically have:

-   `ArgodeSystem` set up as an Autoload.
-   A main Godot scene (e.g., `Main.tscn`) that initializes Argode and starts the script.
-   The RGD script file for this example (e.g., `scenarios/simple_vn.rgd`).
-   Necessary assets (images for backgrounds and characters).

## Code Example: `scenarios/simple_vn.rgd`

```rgd
# --- Definitions (can be in a separate definitions file) ---
character narrator "Narrator" color=#ffffff
character alice "Alice" color=#ff69b4
character bob "Bob" color=#87ceeb

image bg forest_day "res://assets/images/backgrounds/forest_day.png"
image bg forest_night "res://assets/images/backgrounds/forest_night.png"

# Assuming character sprites exist at these paths
image char alice_normal "res://assets/images/characters/alice_normal.png"
image char alice_happy "res://assets/images/characters/alice_happy.png"
image char bob_normal "res://assets/images/characters/bob_normal.png"

# --- Story Start ---
label start:
    narrator "Welcome to the Simple Visual Novel Example!"
    narrator "This story will demonstrate basic Argode features."

    # Change background scene
    scene forest_day with fade

    # Show a character
    show alice_normal at center with dissolve
    alice "Hello there! I'm Alice."
    alice "It's a beautiful day in the forest, isn't it?"

    # Present a choice menu
    menu:
        "Explore the forest":
            jump explore_forest
        "Talk to Alice more":
            jump talk_to_alice
        "End the story":
            jump end_story

# --- Branch: Explore Forest ---
label explore_forest:
    narrator "You decide to explore the forest."
    hide alice_normal with fade
    scene forest_night with dissolve
    narrator "As night falls, you encounter someone new..."

    show bob_normal at left with fade
    bob "Greetings, traveler. Lost, are we?"

    menu:
        "Ask for help":
            jump ask_for_help
        "Run away":
            jump run_away

# --- Branch: Talk to Alice ---
label talk_to_alice:
    alice "What would you like to talk about?"
    menu:
        "Ask about the world":
            alice "This world is full of wonders!"
            jump continue_alice_talk
        "Ask about her day":
            alice "My day has been lovely, thank you!"
            jump continue_alice_talk

label continue_alice_talk:
    alice "Is there anything else?"
    menu:
        "Ask about Bob":
            alice "Bob? Oh, he's a good friend. You might meet him later."
            jump end_story # For simplicity, jump to end
        "Say goodbye":
            jump end_story

# --- Sub-branches from Explore Forest ---
label ask_for_help:
    bob "Of course. Follow me, I know a safe path."
    narrator "You follow Bob, feeling a sense of relief."
    jump end_story

label run_away:
    narrator "You turn and run, leaving Bob behind."
    hide bob_normal with fade
    narrator "You eventually find your way out, but wonder what you missed."
    jump end_story

# --- End of Story ---
label end_story:
    hide alice_normal with dissolve
    hide bob_normal with dissolve
    scene black with fade # Assuming 'black' is a defined black background
    narrator "Thank you for playing the Simple Visual Novel Example!"
    narrator "Feel free to modify this script and explore Argode's features."
    # End of script
```

## How to Run This Example

1.  **Ensure Argode is installed** and `ArgodeSystem` is set up as an Autoload in your Godot project.
2.  **Create the `scenarios` folder** in your project root if it doesn't exist.
3.  **Save the RGD script** above as `scenarios/simple_vn.rgd` in your project.
4.  **Prepare Assets:** Create placeholder image files for `res://assets/images/backgrounds/forest_day.png`, `forest_night.png`, `res://assets/images/characters/alice_normal.png`, `alice_happy.png`, `bob_normal.png`, and a black background image (e.g., `res://assets/images/backgrounds/black.png`). These can be simple colored rectangles for testing.
5.  **Create a Main Scene:** Create a new Godot scene (e.g., `Main.tscn`) with a `Control` node as its root. Attach a script to this `Control` node:

    ```gdscript
    # Main.gd
    extends Control

    func _ready():
        if ArgodeSystem:
            # Start the simple visual novel script
            ArgodeSystem.start_script("res://scenarios/simple_vn.rgd", "start")
        else:
            print("ArgodeSystem not found! Make sure it's in autoload.")
    ```
6.  **Set Main Scene:** In `Project → Project Settings → Application → Run`, set your `Main.tscn` as the **Main Scene**.
7.  **Run:** Press `F5` to run your project and experience the simple visual novel.

## Next Steps

-   Modify the `simple_vn.rgd` script to change dialogue, add more choices, or introduce new characters.
-   Explore other Argode commands and features mentioned in the documentation.
-   Learn how to create your own [Custom Commands](../custom-commands/creating.md) for unique effects.

---

This example provides a solid foundation for building more complex and engaging visual novels with Argode.
