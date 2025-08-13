# Creating Custom Commands

This guide will walk you through the process of creating your own custom commands for Argode. Custom commands allow you to extend Argode's functionality and integrate it seamlessly with your Godot project's unique logic and features.

## The `BaseCustomCommand` Class

All custom commands in Argode are classes that extend `BaseCustomCommand`. This base class provides the necessary structure and methods for Argode to recognize and execute your commands.

### Key Properties and Methods

-   `command_name` (string): **Required.** The name of the command as it will be used in your `.rgd` scripts. This should be unique.
-   `description` (string): A short, descriptive text explaining what the command does. Useful for documentation and potential future tooling.
-   `help_text` (string): A more detailed explanation of the command's syntax, parameters, and usage.
-   `execute(parameters: Dictionary, adv_system: Node)`: **Required for asynchronous commands.** This method is called when your command is executed in an `.rgd` script. Use it for logic that doesn't need to block the script's execution (e.g., playing a sound, showing a non-modal UI).
    -   `parameters`: A dictionary containing all arguments passed to the command from the `.rgd` script.
    -   `adv_system`: A reference to the global `ArgodeSystem` instance, allowing you to access all Argode managers and functionalities.
-   `is_synchronous() -> bool`: Override this method and return `true` if your command needs to block the `.rgd` script's execution until it completes.
-   `execute_internal_async(parameters: Dictionary, adv_system: Node)`: **Required for synchronous commands.** If `is_synchronous()` returns `true`, Argode will call this method instead of `execute()`. Use `await` inside this method for asynchronous operations that need to complete before the script resumes.

## Step-by-Step: Creating a Simple Command

Let's create a simple `log_message` command that prints a custom message to Godot's output console.

### Step 1: Create the Command File

Create a new `.gd` file inside the `res://custom/commands/` directory. Name it something descriptive, like `LogMessageCommand.gd`.

### Step 2: Write the Command Code

Open `LogMessageCommand.gd` and add the following code:

```gdscript
# res://custom/commands/LogMessageCommand.gd
@tool
class_name LogMessageCommand # Use a unique class_name
extends BaseCustomCommand

func _init():
    # The name you'll use in your .rgd scripts
    command_name = "log_message"
    
    # A brief description
    description = "Prints a custom message to the Godot output console."
    
    # Help text for users
    help_text = "log_message <message=string>"

func execute(parameters: Dictionary, adv_system: Node) -> void:
    # Get the 'message' parameter. If not provided, default to an empty string.
    var message_to_log = parameters.get("message", "")
    
    if message_to_log.is_empty():
        log_warning("log_message command called without a message.")
        return
        
    # Print the message to Godot's output console
    print("ARGODE LOG: " + message_to_log)
    
    # Optionally, log to Argode's internal command log (visible via 'ui list' or debug tools)
    log_command("Logged message: " + message_to_log)
```

### Step 3: Use Your New Command in an `.rgd` Script

Now you can use your `log_message` command in any of your `.rgd` script files:

```rgd
label start:
    narrator "Welcome to the game!"
    log_message message="Player has started the game."
    
    narrator "Something important is about to happen."
    log_message "Preparing for critical event." # Positional parameter also works
```

When you run your game, you will see "ARGODE LOG: Player has started the game." and "ARGODE LOG: Preparing for critical event." in Godot's output console.

## Handling Parameters

Argode automatically parses parameters from your `.rgd` script and passes them to your command's `execute` (or `execute_internal_async`) method in the `parameters` dictionary.

### Key-Value Parameters

```rgd
my_command key1="value" key2=123
```
In your `execute` method:
```gdscript
func execute(parameters: Dictionary, adv_system: Node) -> void:
    var value1 = parameters.get("key1", "default_string") # "value"
    var value2 = parameters.get("key2", 0)               # 123
```

### Positional Parameters

```rgd
my_command "first_arg" 456
```
In your `execute` method:
```gdscript
func execute(parameters: Dictionary, adv_system: Node) -> void:
    var first_arg = parameters.get("arg0", "") # "first_arg"
    var second_arg = parameters.get("arg1", 0) # 456
```
Positional parameters are automatically assigned keys like `arg0`, `arg1`, `arg2`, and so on.

### Mixed Parameters

You can combine both key-value and positional parameters:
```rgd
my_command "positional_value" named_param="value" another_pos=789
```
In your `execute` method:
```gdscript
func execute(parameters: Dictionary, adv_system: Node) -> void:
    var pos_val = parameters.get("arg0", "")      # "positional_value"
    var named_val = parameters.get("named_param", "") # "value"
    var another_pos_val = parameters.get("arg1", 0) # 789
```

## Synchronous vs. Asynchronous Commands

By default, commands are asynchronous. This means the `.rgd` script will continue executing the next line immediately after your command's `execute` method is called.

If your command needs to perform an operation that takes time (e.g., waiting for an animation to finish, loading a resource, or a network request) and the `.rgd` script *must* wait for it to complete, you need to make your command **synchronous**.

To create a synchronous command:

1.  **Override `is_synchronous()`:**
    ```gdscript
    func is_synchronous() -> bool:
        return true
    ```
2.  **Implement `execute_internal_async()`:** Put your time-consuming logic inside this method. Use the `await` keyword for operations that yield control.

    ```gdscript
    func execute_internal_async(parameters: Dictionary, adv_system: Node) -> void:
        var duration = parameters.get("duration", 1.0)
        print("Waiting for " + str(duration) + " seconds...")
        await adv_system.get_tree().create_timer(duration).timeout
        print("Wait finished.")
    ```
    When `is_synchronous()` returns `true`, Argode will call `execute_internal_async()` and pause the `.rgd` script until this method completes (i.e., all `await` operations within it are resolved).

## Best Practices

-   **One Command, One File:** Keep each custom command in its own `.gd` file for better organization and modularity.
-   **Unique `command_name` and `class_name`:** Ensure these are unique across your project to avoid conflicts.
-   **Clear `description` and `help_text`:** These are invaluable for you and other developers using your commands.
-   **Validate Parameters:** Always check if required parameters are provided and if their values are of the expected type and range. Use `log_error()` or `log_warning()` to report issues gracefully.
-   **Use `log_command()`:** Call `log_command("Your message")` inside your command's `execute` or `execute_internal_async` method to print debug information to Argode's internal command log (visible via `ui list` or other debug tools).
-   **Access ArgodeSystem:** Use the `adv_system` parameter to access other Argode managers (e.g., `adv_system.VariableManager`, `adv_system.UIManager`).

---

By following these guidelines, you can create powerful and robust custom commands that seamlessly extend Argode's capabilities.
