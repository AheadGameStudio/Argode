# Core Components

Argode's architecture is built around a set of specialized managers, each responsible for a distinct aspect of the visual novel experience. These managers operate as child nodes of the central `ArgodeSystem` singleton, ensuring a modular and organized codebase.

## ArgodeSystem

The `ArgodeSystem` is the central hub of the framework, acting as the single autoloaded singleton in your Godot project. It orchestrates the interactions between all other managers and provides global access to Argode's functionalities.

## ScriptPlayer

The `ScriptPlayer` is the engine that drives your narrative. It is responsible for parsing and executing `.rgd` script files, interpreting commands, managing the flow of the story, and handling script-related events.

## UIManager

The `UIManager` handles all aspects of the user interface. It manages the loading, displaying, and freeing of UI scenes (`.tscn` files), including menus, dialogue boxes, choice buttons, and other interactive elements. It works in conjunction with the `LayerManager` to place UI elements correctly.

## VariableManager

The `VariableManager` is responsible for managing all game-related variables. It supports various data types, including complex structures like arrays and dictionaries, allowing for rich and dynamic story states. It provides methods for setting, getting, and manipulating variables directly from `.rgd` scripts.

## CharacterManager

The `CharacterManager` oversees the definition and display of characters within your visual novel. It handles character names, display names, colors, and expressions, ensuring consistent presentation throughout the story.

## LayerManager

The `LayerManager` provides a flexible and adaptable system for managing visual layers. Instead of imposing a fixed scene structure, it allows you to define roles for Godot's `CanvasLayer` nodes (e.g., "background", "characters", "ui", "effects"). This enables seamless integration with existing Godot projects and supports highly customized visual layouts.

## CustomCommandHandler

The `CustomCommandHandler` is a key component for Argode's extensibility. It acts as a bridge between the `.rgd` script and your custom Godot game logic. When the `ScriptPlayer` encounters an unknown command in an `.rgd` file, the `CustomCommandHandler` emits a signal, allowing you to implement unique game mechanics and effects using GDScript or C#.

## LabelRegistry

The `LabelRegistry` is responsible for indexing and managing all labels defined within your `.rgd` script files. This enables efficient navigation and jumping between different sections of your story, supporting complex branching narratives.

## Definition Managers

Argode utilizes several specialized definition managers to handle the loading and management of various asset types declared in your `.rgd` scripts. These managers ensure that assets are correctly identified, preloaded (if configured), and made available to the framework.

*   **`AudioDefinitionManager`**: Manages audio assets (BGM, SFX).
*   **`CharacterDefinitionManager`**: Manages character definitions.
*   **`ImageDefinitionManager`**: Manages image assets (backgrounds, sprites).
*   **`ShaderDefinitionManager`**: Manages custom shader resources.
*   **`UISceneDefinitionManager`**: Manages UI scene definitions.

## TransitionPlayer

The `TransitionPlayer` handles visual transitions between scenes and other visual elements. It provides a centralized system for applying effects like fades, dissolves, and custom transitions, enhancing the visual appeal of your visual novel.

---

[Learn About System Overview →](system-overview.md){ .md-button }
[Learn About Design Philosophy →](design-philosophy.md){ .md-button }