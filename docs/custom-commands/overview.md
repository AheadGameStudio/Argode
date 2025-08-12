# Custom Commands Overview

One of Argode's most powerful features is its extensibility through custom commands. By creating simple script files, you can add new game-specific logic, integrate with other Godot systems, and expand the engine's capabilities to fit your project's unique needs.

Argode uses an **object-oriented, class-based** approach for custom commands. Each command is its own `.gd` file that extends the `BaseCustomCommand` class. This makes your commands modular, reusable, and easy to manage.

## 🚀 Command Auto-Discovery

The best part of the new command system is **auto-discovery**. You no longer need to manually connect signals or register your commands. Simply place your command's `.gd` file in the `res://custom/commands/` directory, and Argode will automatically detect and register it when the game starts.

```mermaid
graph TD
    A[Game Starts] --> B[ArgodeSystem Initializes]
    B --> C{Scans `custom/commands/`}
    C --> D[Finds YourCommand.gd]
    D --> E{Registers "your_command"}
    E --> F[Ready to use in scripts!]

    style C fill:#e1f5fe
    style E fill:#c8e6c9
```

## 🛠️ Creating a Custom Command

Let's create a simple `hello_world` command that prints a message to the console.

**Step 1: Create the File**

Create a new file named `HelloWorldCommand.gd` inside the `res://custom/commands/` directory.

**Step 2: Write the Code**

Open the file and add the following code:

```gdscript
# res://custom/commands/HelloWorldCommand.gd
@tool
class_name HelloWorldCommand
extends BaseCustomCommand

# Called when the command is first registered.
func _init():
    # The name used in your .rgd scripts.
    command_name = "hello_world"
    
    # A brief description for documentation or tools.
    description = "Prints a greeting to the console."
    
    # Help text for how to use the command.
    help_text = "hello_world [name=string]"

# Called when the command is executed in a script.
func execute(parameters: Dictionary, adv_system: Node) -> void:
    # Get a parameter named "name", with a default value of "World".
    var target_name = parameters.get("name", "World")
    
    # Print the message.
    print("Hello, " + target_name + "!")
    
    # Log to the in-game console for debugging.
    log_command("Printed greeting to " + target_name)
```

**Step 3: Use it in Your Script**

Now you can use your new command in any `.rgd` file:

```rgd
label start:
    # Prints "Hello, World!"
    hello_world

    # Prints "Hello, Yuko!"
    hello_world name="Yuko"
```

That's it! Argode handles the rest.

## ⚙️ The `BaseCustomCommand` Class

Your custom command classes inherit from `BaseCustomCommand` and can override several properties and methods:

- `command_name` (string): **Required.** The name of the command used in scripts.
- `description` (string): A short description of what the command does.
- `help_text` (string): A longer text explaining the syntax and parameters.
- `execute(parameters: Dictionary, adv_system: Node)`: **Required.** The main logic of your command.
- `is_synchronous() -> bool`: Override this to control script flow (see below).
- `execute_internal_async(parameters: Dictionary, adv_system: Node)`: The async version of your logic.

## ⚡ Synchronous vs. Asynchronous Commands

Commands can either be **asynchronous** (the script continues immediately) or **synchronous** (the script waits for the command to finish).

### Asynchronous (Default)

By default, commands are asynchronous. The `execute` method is called, and the script player moves to the next line right away. This is suitable for actions that shouldn't block the game flow, like playing a sound effect.

### Synchronous

To make a command synchronous, you need to do two things:

1.  Override `is_synchronous()` to return `true`.
2.  Put your logic inside `execute_internal_async(params, adv_system)`.

The `wait` command is a perfect example:

```gdscript
# A simplified look at the built-in WaitCommand.gd
@tool
class_name BuiltinWaitCommand
extends BaseCustomCommand

func _init():
    command_name = "wait"

# 1. Tell Argode this command should block the script.
func is_synchronous() -> bool:
    return true

# 2. Put the waiting logic in the async version of execute.
func execute_internal_async(params: Dictionary, adv_system: Node) -> void:
    var duration = params.get("duration", 1.0)
    
    # The 'await' keyword pauses this function, and because
    # is_synchronous() is true, it also pauses the script player.
    await adv_system.get_tree().create_timer(duration).timeout
    
    # Once the timer is done, the script will resume.
```

## 📥 Handling Parameters

The `execute` method receives a `parameters` dictionary containing all the arguments passed from the script.

**Script:**
```rgd
my_command "first_arg" 123 an_option="some_value"
```

**`parameters` Dictionary:**
```gdscript
{
  "_raw": "first_arg 123 an_option=some_value", # The raw string
  "arg0": "first_arg",
  "arg1": 123,
  "an_option": "some_value"
}
```
You can use the `.get(key, default_value)` method on the dictionary to safely access parameters.

## 📚 Best Practices

- **One Command, One File:** Keep each command in its own file for better organization.
- **Clear Naming:** Use descriptive names for your commands and parameters.
- **Use `log_command()`:** Call `log_command("My message")` inside `execute` to print debug information to the in-game console.
- **Fail Gracefully:** Check for required parameters and use `log_error()` or `log_warning()` to report issues without crashing.

---

With this powerful system, you can extend Argode to do almost anything you can imagine.

[View Built-in Commands →](built-in.md){ .md-button }