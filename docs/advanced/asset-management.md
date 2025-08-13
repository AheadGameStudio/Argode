# Asset Management

Argode provides a robust and intelligent system for managing game assets, designed to simplify the developer's workflow while optimizing performance. The core philosophy revolves around script-centric definitions and predictive preloading.

## Script-Centric Asset Definition

Unlike traditional game development workflows that often require manual asset import and configuration in an editor, Argode allows you to define most of your game assets directly within your `.rgd` script files. This approach offers several benefits:

*   **Version Control Friendly**: All asset definitions are plain text, making them easy to track, diff, and merge in version control systems.
*   **Writer-Friendly**: Writers can declare assets alongside their narrative, reducing the need to switch between different tools.
*   **Batch Operations**: Renaming, reorganizing, or duplicating assets becomes straightforward through simple text manipulation.
*   **Self-Documenting**: Asset definitions serve as inline documentation within your scripts.

You define assets using specific statements in your `.rgd` files:

*   **`character`**: Defines characters with names, display names, and colors.
    ```rgd
    character alice "Alice" color=#ff69b4
    ```
*   **`image`**: Defines images, typically backgrounds and character sprites, with smart path resolution.
    ```rgd
    image bg_forest "backgrounds/forest_day.jpg"
    image alice_happy "characters/alice/happy.png"
    ```
*   **`audio`**: Defines audio files for background music (BGM) and sound effects (SFX), with options for preloading.
    ```rgd
    audio bgm_main "music/main_theme.ogg" preload=true
    audio sfx_door "sounds/door_open.wav"
    ```
*   **`shader`**: Defines custom shader resources for visual effects.
    ```rgd
    shader screen_blur "shaders/blur.gdshader"
    ```
*   **`ui_scene`**: Defines UI scenes (`.tscn` files) for use with the `ui` command.
    ```rgd
    ui_scene main_menu "ui/main_menu.tscn"
    ```

These definitions are processed by dedicated **Definition Managers** (e.g., `AudioDefinitionManager`, `ImageDefinitionManager`, `CharacterDefinitionManager`, `ShaderDefinitionManager`, `UISceneDefinitionManager`), which ensure assets are correctly registered and prepared for use.

## Predictive Asset Preloading

One of Argode's most powerful features is its intelligent, predictive asset preloading system. At startup, Argode performs a static analysis of your entire `.rgd` script structure to build a comprehensive control flow graph.

This graph allows Argode to:

*   **Analyze Reachability**: Determine which assets are reachable from any given point in the script.
*   **Anticipate Needs**: Predict which assets will likely be required next based on the narrative flow and potential player choices.
*   **Optimize Loading**: Automatically preload assets just before they are needed, minimizing loading screens and ensuring a seamless player experience.
*   **Manage Memory**: Efficiently unload assets that are no longer reachable, optimizing memory usage.

This automatic optimization means you typically don't need to manually manage asset loading or unloading, allowing you to focus on storytelling.

## Asset Paths and Resolution

Argode uses Godot's resource path system (e.g., `res://`) for asset paths. When defining assets, you provide paths relative to your project's `res://` root. Argode's definition managers handle the resolution and loading of these resources.

---

[Learn About System Overview →](system-overview.md){ .md-button }
[View Core Components →](core-components.md){ .md-button }