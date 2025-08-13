# Managers API Reference

Argode's modular architecture is built upon a collection of specialized managers, each handling a specific domain within your visual novel project. These managers are accessible as properties of the central `ArgodeSystem` singleton, allowing for organized and efficient interaction with the framework's functionalities.

This document provides an overview of the primary managers and their roles. For detailed API specifications of individual managers, refer to their respective documentation (if available) or the source code.

## Accessing Managers

All managers are child nodes of `ArgodeSystem` and can be accessed via its properties:

```gdscript
var argode_system = get_node("/root/ArgodeSystem") # Or ArgodeSystem if globally set
var ui_manager = argode_system.UIManager
var variable_manager = argode_system.VariableManager
# ... and so on for other managers
```

## Core Managers Overview

### `UIManager`

The `UIManager` is responsible for all aspects of the user interface. It handles the loading, displaying, and freeing of UI scenes (`.tscn` files), managing elements like dialogue boxes, choice menus, and other interactive UI components. It works closely with the `LayerManager` to ensure UI elements are correctly positioned on the screen.

**Key Responsibilities:**
*   Displaying dialogue and character names.
*   Presenting choice menus and handling user selections.
*   Loading and managing custom UI scenes (e.g., inventory, settings screens).
*   Controlling the visibility and state of the message window.

### `VariableManager`

The `VariableManager` is the central repository for all game-related variables and data. It supports various data types, including primitive types, arrays, and dictionaries, enabling complex and dynamic story states. It provides methods for setting, retrieving, and evaluating variables and conditions directly from `.rgd` scripts and GDScript.

**Key Responsibilities:**
*   Storing and managing global and local variables.
*   Evaluating conditional expressions (`if` statements).
*   Handling character definitions and their associated data.
*   Managing array and dictionary data structures.

### `CharacterManager`

The `CharacterManager` is dedicated to managing characters within your visual novel. It handles character definitions (names, display names, colors), expressions, and their visual presentation on the screen. It works with the `LayerManager` to display characters on designated layers.

**Key Responsibilities:**
*   Registering and retrieving character definitions.
*   **Integrates with `CharacterDefinitionManager` to manage detailed character data and expressions (v2 feature).**
*   Displaying and hiding characters with characters with specified expressions and positions.
*   Managing character-specific visual effects.

**Important Notes:**
*   **`show_scene` Deprecation:** The `show_scene` method within `CharacterManager` is deprecated. For displaying characters on screen, it is now recommended to use the `LayerManager`'s functionalities, which provide more flexible and robust control over visual layers.
*   **Legacy Script Compatibility:** For compatibility with older scripts, Argode provides a fallback mechanism for previous `CharacterManager` methods. However, it is highly recommended to update your scripts to use the latest `LayerManager` functionalities for character display.

### `LayerManager`

The `LayerManager` provides a flexible system for organizing and displaying visual elements across different `CanvasLayer` nodes in your Godot project. Instead of a rigid scene structure, it allows you to define "roles" for your layers (e.g., "background", "character", "ui", "effects") and maps them to your actual `CanvasLayer` nodes.

**Key Responsibilities:**
*   Mapping layer roles to `CanvasLayer` nodes.
*   Handling background changes with transitions.
*   Managing character and UI element placement on their respective layers.
*   Providing a structured way to control visual depth.

### `CustomCommandHandler`

The `CustomCommandHandler` is the gateway to Argode's powerful extensibility. It allows you to integrate custom GDScript or C# logic directly into your `.rgd` scripts. When the `ScriptPlayer` encounters a command it doesn't recognize, the `CustomCommandHandler` emits a signal, enabling you to execute any custom functionality you define.

**Key Responsibilities:**
*   Registering custom commands (via `BaseCustomCommand` instances or `Callable`s).
*   Dispatching custom command calls from `.rgd` scripts to your GDScript functions.
*   Managing synchronous and asynchronous custom command execution.

### `LabelRegistry`

The `LabelRegistry` is responsible for scanning your `.rgd` script files and building an index of all defined `label`s. This enables efficient cross-file jumps and calls, supporting complex branching narratives and modular script organization.

**Key Responsibilities:**
*   Scanning specified directories for `.rgd` files.
*   Parsing `.rgd` files to identify and register labels.
*   Providing lookup functionality for labels across multiple script files.

### `TransitionPlayer`

The `TransitionPlayer` manages visual transitions between scenes, characters, and other visual elements. It provides a centralized system for applying various transition effects (e.g., fades, dissolves, custom shaders) to enhance the visual flow of your visual novel.

**Key Responsibilities:**
*   Executing predefined transition effects.
*   Applying transitions to background changes, character appearances/disappearances, and other visual events.

## Definition Managers

Argode employs several specialized definition managers to handle the parsing and registration of assets declared within your `.rgd` script files. These managers ensure that your assets are correctly recognized, preloaded (if configured), and readily available for use by the framework.

*   **`AudioDefinitionManager`**: Manages definitions for background music (BGM) and sound effects (SFX).
*   **`CharacterDefinitionManager`**: Manages detailed definitions for characters, including their expressions and associated resources.

*   **`ImageDefinitionManager`**: Manages definitions for images, such as backgrounds, character sprites, and other visual assets.
*   **`ShaderDefinitionManager`**: Manages definitions for custom shader resources used for visual effects.
*   **`UISceneDefinitionManager`**: Manages definitions for UI scenes (`.tscn` files) that can be displayed using the `ui` command.

---

[Learn About ArgodeSystem API →](argode-system.md){ .md-button }
[Learn About ScriptPlayer API →](script-player.md){ .md-button }