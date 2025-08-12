# System Overview

Argode is a powerful and flexible visual novel framework for the Godot Engine, designed to streamline the creation of interactive stories. It emphasizes extensibility, developer convenience, and a script-centric approach to asset management.

## Core Architecture: The ArgodeSystem Singleton

At the heart of Argode is the `ArgodeSystem` singleton, the sole global node introduced into your Godot project. This design ensures minimal global namespace pollution and provides a clean, predictable structure for all framework components.

All other core functionalities are managed as child nodes of `ArgodeSystem`, creating a clear hierarchy that simplifies debugging and integration. Key managers include:

*   **`ScriptPlayer`**: Responsible for parsing and executing `.rgd` script files, driving the narrative flow.
*   **`UIManager`**: Handles the display and management of user interface scenes.
*   **`VariableManager`**: Manages all game variables, including complex data types like arrays and dictionaries.

*   **`CharacterManager`**: Oversees character definitions, expressions, and display.
*   **`LayerManager`**: Provides a flexible system for mapping visual elements to Godot's CanvasLayers, allowing for custom scene layouts.
*   **`CustomCommandHandler`**: The gateway for Argode's powerful extensibility, forwarding unknown commands as signals for custom game logic.
*   **`LabelRegistry`**: Indexes and manages labels within `.rgd` scripts for navigation and flow control.
*   **`DefinitionLoader`**: Processes asset and character definitions declared within `.rgd` files.

## Script-Centric Workflow with RGD Files

Argode leverages its custom `.rgd` (Argode Script) file format for defining game logic, dialogue, and assets. This script-centric approach allows writers and developers to work primarily with plain text files, simplifying version control and batch operations.

Key features of RGD files:

*   **Narrative Flow**: Define dialogue, choices, and scene transitions.
*   **Asset Definitions**: Declare characters, images, audio, and shaders directly within scripts.
*   **Commands**: Utilize a rich set of built-in commands for timing, UI manipulation, and variable management.
*   **Extensibility**: Easily integrate custom game logic through user-defined commands.

For enhanced development experience, a dedicated [VS Code extension](https://github.com/AheadGameStudio/Argode-rgd-syntax-highlighter) provides syntax highlighting and IntelliSense support for `.rgd` files.

## Predictive Asset Management

Argode incorporates an intelligent asset management system that analyzes your entire script structure at startup. By building a control flow graph, it performs reachability analysis to predict which assets will be needed, enabling smart preloading and optimizing memory usage. This ensures faster loading times and a smoother player experience without manual optimization.

## Flexible UI and Layer System

The framework offers an advanced UI system built around `AdvScreen` nodes, allowing for complex, interactive user interfaces that seamlessly integrate with the script. Coupled with a flexible `LayerManager`, developers can define custom CanvasLayer roles, adapting Argode to existing Godot projects and unique visual requirements.

## Development Experience

Designed for rapid iteration, Argode supports hot-reloading of scripts and real-time inspection of game state. This focus on developer convenience, combined with robust error detection and IDE integration, significantly accelerates the visual novel development workflow.

---

[Learn About Design Philosophy →](design-philosophy.md){ .md-button }
[View Core Components →](core-components.md){ .md-button }