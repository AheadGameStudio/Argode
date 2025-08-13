# Quick Start Guide

Get up and running with Argode in just a few minutes! This guide will help you create your first visual novel scene.

## Prerequisites

- **Godot Engine 4.0+** ([Download here](https://godotengine.org/))
- **Basic familiarity** with Godot projects





## Step 3: Create Your First Script

Create a new file `scenarios/story.rgd`:

```gdscript
# story.rgd - Your first visual novel script

# Define characters
character narrator "Narrator" color=#ffffff
character alice "Alice" color=#ff69b4  

# Set up player variables using dot notation (NEW!)
set player.name = "Hero"
set player.level = 1
set player.stats.hp = 100

label start:
    narrator "Welcome to your first Argode visual novel!"
    
    show alice happy at center with fade
    alice "Hello! I'm Alice, your guide to this new world."
    alice "I can see you're {player.name}, level {player.level}!"
    alice "What would you like to do first?"
    
    menu:
        "Learn about the story":
            jump learn_story
        "Explore the world":
            jump explore_world
        "Check my stats":
            jump check_stats

label check_stats:
    alice "Let me check your status..."
    alice "Name: {player.name}"
    alice "Level: {player.level}"
    alice "HP: {player.stats.hp}"
    
    # Update stats with dot notation
    set player.stats.hp = player.stats.hp + 10
    alice "I've healed you! Your HP is now {player.stats.hp}."
    jump continue_story

label learn_story:
    alice "This is where your amazing story begins!"
    alice "You can create complex narratives with branching paths."
    narrator "Use 'jump' to move between story sections."
    jump continue_story

label explore_world:
    scene background_forest with fade
    alice "Welcome to our magical forest!"
    alice "Scenes can change backgrounds with smooth transitions."
    
    # Gain experience for exploring
    set player.level = player.level + 1
    alice "Exploring gained you experience! You're now level {player.level}!"
    jump continue_story

label continue_story:
    narrator "This is just the beginning of your visual novel journey."
    narrator "Variables make your story dynamic and personal!"
    narrator "Check out the documentation to learn more advanced features!"
```

## Step 4: Create the Main Scene

1. Create a new scene (`Scene → New Scene`)
2. Add a `Control` node as root and save as `Main.tscn`
3. Attach this script to the Control node:

```gdscript
extends Control

func _ready():
    # Initialize Argode and load the script
    if ArgodeSystem:
        ArgodeSystem.start_script("res://scenarios/story.rgd", "start")
    else:
        print("ArgodeSystem not found! Make sure it's in autoload.")
```



## What You Just Created

Congratulations! You've created a complete visual novel with:

- ✅ **Character definitions** with names and colors
- ✅ **Dialogue system** with character portraits
- ✅ **Choice menus** for player interaction
- ✅ **Scene transitions** and background changes
- ✅ **Branching narrative** with labels and jumps

## Next Steps

Ready to dive deeper? Explore these topics:

### 🎨 **Enhance Visuals**
- [Character expressions and positioning](../script/commands.md#show)
- [Background transitions and effects](../script/commands.md#scene)
- [Custom UI themes](../ui/themes.md)

### 🎯 **Add Interactivity**
- [Variables and conditional logic](../script/variables.md)
- [Save/Load system](../advanced/save-system.md)
- [Custom commands for effects](../custom-commands/creating.md)

### 📚 **Study Examples**
- [Simple Visual Novel](../examples/simple-vn.md)
- [Advanced Features Demo](../examples/custom-features.md)
- [Best Practices Guide](../examples/best-practices.md)

---

**Having trouble?** Check the [Troubleshooting Guide](../advanced/debugging.md) or join our Discord community!

For detailed setup instructions, refer to:

[Installation Guide →](installation.md){ .md-button }
[Basic Setup Guide →](basic-setup.md){ .md-button }
