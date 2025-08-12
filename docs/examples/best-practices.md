# Best Practices

Developing visual novels with Argode can be a smooth and efficient process when following certain best practices. This guide provides recommendations to help you build maintainable, performant, and scalable projects.

## Project Structure

A well-organized project structure is crucial for long-term maintainability. While Argode is flexible, consider these suggestions:

*   **Separate Assets**: Keep your `assets/` directory clean, categorizing images, audio, and other media.
*   **Organize RGD Scripts**: Place your `.rgd` script files in a dedicated `scenarios/` directory, possibly with subfolders for chapters or routes.
*   **Custom Commands**: Store your custom GDScript commands in `custom/commands/` or a similar dedicated folder.
*   **UI Scenes**: Keep your `.tscn` UI scenes in a `ui/` or `scenes/ui/` directory.
*   **Definitions**: Centralize your `character`, `image`, `audio`, etc., definitions in dedicated `.rgd` files (e.g., `definitions/characters.rgd`, `definitions/assets.rgd`).

## RGD Scripting

Writing clean and efficient `.rgd` scripts is key to a manageable project:

*   **Use Labels for Flow Control**: Utilize `label` and `jump` commands for clear navigation between story segments.
*   **Modularize Scripts**: Break down long narratives into smaller, manageable `.rgd` files (e.g., one file per scene or chapter). Use `call` or `jump` to link them.
*   **Consistent Naming Conventions**: Establish and stick to clear naming conventions for labels, variables, and assets.
*   **Comments**: Use `#` for single-line comments and `/* ... */` for multi-line comments to explain complex logic or temporary notes.
*   **Variable Usage**: Leverage the `VariableManager` and its `set_array`, `set_dict` commands for structured data.
*   **Avoid Hardcoding**: Whenever possible, use variables or definitions instead of hardcoding values directly in the narrative.

## Asset Management

Argode's script-centric asset definition simplifies management. Follow these tips:

*   **Define Assets Centrally**: Declare all your `character`, `image`, `audio`, `shader`, and `ui_scene` definitions in dedicated `.rgd` definition files. This makes them easy to find and modify.
*   **Consistent Paths**: Use consistent `res://` paths for all your assets.
*   **Optimize Assets**: Ensure your image, audio, and video assets are optimized for size and format to improve loading times and reduce memory usage (refer to [Performance Optimization](../advanced/performance.md)).

## UI Development

Argode's UI system is powerful. Here are some best practices:

*   **Use `AdvScreen`**: For complex UI elements that interact with the script, extend `AdvScreen` in your GDScript.
*   **Layer Roles**: Clearly define and use `LayerManager` roles for your `CanvasLayer` nodes to maintain visual order.
*   **Modular UI Scenes**: Break down complex UIs into smaller, reusable `.tscn` components.
*   **Responsive Design**: Design your UI scenes to adapt well to different screen resolutions and aspect ratios using Godot's Control nodes and anchors.

## Extensibility with Custom Commands

Argode's extensibility is a major strength. Use it wisely:

*   **Encapsulate Logic**: When creating custom commands, encapsulate specific game logic or visual effects within them.
*   **Clear Parameters**: Design your custom commands with clear and intuitive parameters.
*   **Signal-Based Communication**: Leverage the `CustomCommandHandler`'s signals to trigger GDScript functions from your `.rgd` scripts.
*   **Documentation**: Document your custom commands thoroughly, including their purpose, parameters, and examples.

## Performance and Debugging

Refer to the dedicated sections for in-depth guidance:

*   [Performance Optimization](../advanced/performance.md): Learn about Argode's built-in optimizations and general Godot performance tips.
*   [Debugging](../advanced/debugging.md): Explore Argode's real-time debugging features and Godot's powerful debugging tools.

## Version Control

Always use a version control system (like Git) for your project. This allows you to:

*   **Track Changes**: Keep a history of all modifications to your code and assets.
*   **Collaborate**: Work effectively with a team.
*   **Experiment Safely**: Create branches for new features or bug fixes without affecting the main project.
*   **Revert Changes**: Easily roll back to previous versions if something goes wrong.

By adopting these best practices, you can harness the full power of Argode to create engaging and high-quality visual novels.

---

[Learn About Simple VN Example →](simple-vn.md){ .md-button }
[Learn About Custom Features Example →](custom-features.md){ .md-button }