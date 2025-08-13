# Debugging

Argode is designed to provide a smooth and efficient development experience, with several features aimed at simplifying the debugging process. This section outlines the tools and practices that can help you identify and resolve issues in your visual novel.

## Real-time Debugging Features

Argode integrates seamlessly with Godot's development environment to offer real-time debugging capabilities:

*   **Script Hot Reloading**: Make changes to your `.rgd` script files and see them reflected instantly in the running game without needing to restart. This significantly speeds up iteration and testing.
*   **Variable Inspection**: Argode's `VariableManager` allows for real-time inspection of all game variables. You can monitor their values as the script executes, helping to track down logic errors related to data manipulation.
*   **Label Registry Updates**: As you add or modify labels in your `.rgd` scripts, Argode's `LabelRegistry` automatically updates, ensuring that jumps and calls to labels remain valid.
*   **Command Validation**: The framework provides immediate feedback on syntax errors within your `.rgd` commands, helping to catch issues early in development.

## Godot's Debugging Tools

Argode projects benefit from Godot Engine's comprehensive suite of debugging tools:

*   **Remote Debugging**: Connect to a running game instance (even on a separate device) to inspect nodes, variables, and execute code in real-time.
*   **Profiler**: Use Godot's built-in profiler to identify performance bottlenecks in your game logic, rendering, or physics.
*   **Monitor**: Track various performance metrics like FPS, memory usage, and network activity.
*   **Debugger**: Set breakpoints in your GDScript code, step through execution, and inspect the call stack.
*   **Remote Scene Tree**: View and modify the live scene tree of your running game, allowing you to inspect node properties and hierarchy.

## IDE Integration (VS Code)

For `.rgd` script development, the dedicated [VS Code extension](https://github.com/AheadGameStudio/Argode-rgd-syntax-highlighter) significantly enhances the debugging experience:

*   **Syntax Highlighting**: Clearly visualize the structure of your `.rgd` scripts with proper syntax highlighting.
*   **IntelliSense Support**: Get auto-completion suggestions for Argode commands, variables, and labels, reducing typos and speeding up coding.
*   **Error Detection**: Real-time validation of script syntax helps you identify and fix errors as you type.

## Debugging Practices

To effectively debug your Argode project, consider the following practices:

*   **Use `print` Statements**: Temporarily add `print` commands in your `.rgd` scripts to output variable values or execution flow messages to the console.
*   **Isolate Issues**: When encountering a bug, try to isolate the problematic section of your script or scene to narrow down the cause.
*   **Version Control**: Regularly commit your changes to a version control system (like Git) to easily revert to previous working states if a bug is introduced.
*   **Test Thoroughly**: Implement a testing strategy for your `.rgd` scripts and custom GDScript logic to catch regressions.

By leveraging Argode's built-in features and Godot's powerful debugging tools, you can efficiently troubleshoot and refine your visual novel, ensuring a polished final product.

---

[Learn About Performance Optimization →](performance.md){ .md-button }
[Learn About Best Practices →](../examples/best-practices.md){ .md-button }