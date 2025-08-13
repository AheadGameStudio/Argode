# Basic Setup Guide

This guide covers the essential setup steps for your Godot project to work with Argode.

## Setup Autoload

1. Open **Project Settings** (`Project → Project Settings`)
2. Go to **Autoload** tab
3. Add **ArgodeSystem**:
   - **Path**: `res://addons/argode/core/ArgodeSystem.gd`
   - **Node Name**: `ArgodeSystem`
   - Check **Enable**

![Autoload Setup](../images/autoload-setup.png)

## Set as Main Scene

1. Create a new scene (`Scene → New Scene`) if you haven't already, and save it (e.g., `Main.tscn`).
2. Go to **Project Settings** (`Project → Project Settings`).
3. Under the **Application → Run** section, set **Main Scene** to your `Main.tscn` (or whatever you named your main scene).

## Prepare Visual Layers

Argode utilizes Godot's `CanvasLayer` nodes to manage the visual depth and display of backgrounds, characters, and UI elements. While you can manually set up these layers, Argode provides a streamlined approach using the `ArgodeScreen` node.

### Recommended Approach: Using `ArgodeScreen` (Simplest)

The `ArgodeScreen` node (found at `res://addons/argode/ui/ArgodeScreen.tscn`) is a pre-configured `Control` node designed to simplify layer management. It automatically handles the creation and assignment of `CanvasLayer` nodes for common roles (background, characters, UI, effects) when its "Auto Layer Expansion" property is enabled (which is the default).

1.  In your main scene (`Main.tscn`), add an `ArgodeScreen` node as a direct child of your root node.
2.  Ensure the `ArgodeScreen` node's "Auto Layer Expansion" property is enabled in the Inspector (it's usually on by default).
3.  Your scene tree will look like this:

    ```
    - Main (Node2D or Control)
      - ArgodeScreen (Control)
        - Background (CanvasLayer)
        - Characters (CanvasLayer)
        - UI (CanvasLayer)
        - Effects (CanvasLayer)
    ```

    The `CanvasLayer` nodes created by `ArgodeScreen` will have their `Layer` properties automatically set to appropriate values for visual depth.

### Alternative: Manual `CanvasLayer` Setup (Advanced)

For advanced users or specific project needs, you can manually create and configure `CanvasLayer` nodes.

1.  In your main scene (`Main.tscn`), create the following `CanvasLayer` nodes as direct children of your root node:
    *   **Background Layer**: For displaying backgrounds. Set its `Layer` property to a low value (e.g., `0` or `1`).
    *   **Characters Layer**: For displaying characters. Set its `Layer` property higher than the background (e.g., `2` or `3`).
    *   **UI Layer**: For displaying user interface elements. Set its `Layer` property to a high value (e.g., `10` or `100`).
    *   **Effects Layer**: (Optional, but recommended) For displaying screen-wide effects. Set its `Layer` property to the highest value (e.g., `200`).

2.  Your scene tree might look something like this:

    ```
    - Main (Node2D or Control)
      - BackgroundLayer (CanvasLayer)
      - CharactersLayer (CanvasLayer)
      - UILayer (CanvasLayer)
      - EffectsLayer (CanvasLayer)
    ```

## Initialize ArgodeSystem

In the script attached to your main scene (`Main.tscn`), you need to initialize `ArgodeSystem` by mapping the `CanvasLayer` nodes you've prepared to their respective roles.

```gdscript
# Main.gd (attached to your Main scene's root node)
extends Node2D # Or Control, depending on your root node type

func _ready():
    # Map your CanvasLayer nodes to Argode's layer roles
    # If using ArgodeScreen, access its child CanvasLayers
    var layer_map = {
        "background": $ArgodeScreen/Background, # Or $BackgroundLayer if manual setup
        "character": $ArgodeScreen/Characters, # Or $CharactersLayer if manual setup
        "ui": $ArgodeScreen/UI,             # Or $UILayer if manual setup
        "effects": $ArgodeScreen/Effects    # Or $EffectsLayer if manual setup (Optional)
    }

    # Initialize ArgodeSystem
    if ArgodeSystem.initialize_game(layer_map):
        print("ArgodeSystem initialized successfully!")
        # Start your first RGD script
        ArgodeSystem.start_script("res://scenarios/main.rgd", "start")
    else:
        print("ArgodeSystem initialization failed.")
        # Handle initialization errors (e.g., display an error message)

```

## Run Your Project

Press **F5** to run your project. If everything is set up correctly, Argode will initialize, and your `res://scenarios/main.rgd` script will begin executing.
