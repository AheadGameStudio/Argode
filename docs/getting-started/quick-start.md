# Quick Start Guide

Get up and running with Argode in just a few minutes! This guide will help you create your first visual novel scene.

## Prerequisites

- **Godot Engine 4.0+** ([Download here](https://godotengine.org/))
- **Basic familiarity** with Godot projects

## Step 1: Install Argode

### Option A: From AssetLib (Recommended)
1. Open Godot Engine
2. Go to **AssetLib** tab
3. Search for **"Argode"**
4. Click **Download** and **Install**

### Option B: Manual Installation
1. Download the latest release from [GitHub](https://github.com/AheadGameStudio/Argode)
2. Extract the `addons/argode/` folder to your project's `addons/` directory
3. Enable the plugin in **Project Settings → Plugins**

## Step 2: Setup Autoload

1. Open **Project Settings** (`Project → Project Settings`)
2. Go to **Autoload** tab
3. Add **ArgodeSystem**:
   - **Path**: `res://addons/argode/core/ArgodeSystem.gd`
   - **Node Name**: `ArgodeSystem`
   - Check **Enable**

![Autoload Setup](../images/autoload-setup.png)

## Step 3: Create Your First Script

Create a new file `scenarios/story.rgd`:

```gdscript
# story.rgd - Your first visual novel script

# Define characters
character narrator "Narrator" color=#ffffff
character alice "Alice" color=#ff69b4  

label start:
    narrator "Welcome to your first Argode visual novel!"
    
    show alice happy at center with fade
    alice "Hello! I'm Alice, your guide to this new world."
    alice "What would you like to do first?"
    
    menu:
        "Learn about the story":
            jump learn_story
        "Explore the world":
            jump explore_world
        "Meet other characters":
            jump meet_characters

label learn_story:
    alice "This is where your amazing story begins!"
    alice "You can create complex narratives with branching paths."
    narrator "Use 'jump' to move between story sections."
    jump continue_story

label explore_world:
    scene background_forest with fade
    alice "Welcome to our magical forest!"
    alice "Scenes can change backgrounds with smooth transitions."
    jump continue_story

label meet_characters:
    hide alice with fade
    show bob normal at left with fade
    bob "Hi there! I'm Bob, Alice's friend."
    
    show alice happy at right with fade
    alice "Characters can appear and disappear as needed!"
    jump continue_story

label continue_story:
    narrator "This is just the beginning of your visual novel journey."
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
        ArgodeSystem.load_and_play_script("res://scenarios/story.rgd", "start")
    else:
        print("ArgodeSystem not found! Make sure it's in autoload.")
```

## Step 5: Set as Main Scene

1. Go to **Project Settings**
2. Set **Main Scene** to your `Main.tscn`
3. Press **F5** to run your visual novel!

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

[Continue to Installation Details →](installation.md){ .md-button }
[View Script Reference →](../script/rgd-syntax.md){ .md-button }
