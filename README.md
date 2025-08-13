# Argode

![Argode](ArgodeLogo.png)

A powerful and flexible visual novel framework for Godot Engine, designed to make creating interactive narratives simple and enjoyable.

## 🌟 Features

### 📖 Visual Novel Framework
- **RGD Script Language**: Easy-to-learn custom scripting language for visual novels
- **Character System**: Define characters with multiple sprites, expressions, and voice sets
- **Scene Management**: Seamless transitions between backgrounds, characters, and UI elements
- **Text Animation**: Beautiful typewriter effects and text animations
- **Audio Integration**: Background music, sound effects, and voice acting support

### 💾 Advanced Save System
- **Screenshot Thumbnails**: Automatic Base64-encoded screenshot thumbnails for save slots
- **Temporary Screenshots**: Capture UI-free game scenes for clean save thumbnails
- **Auto-Save**: Automatic saves at key story points (slot 0)
- **Manual Save**: Player-controlled saves in slots 1 and above
- **Encrypted Data**: AES encryption for save data security

### 🎨 Customizable UI
- **AdvScreen**: Advanced screen management system
- **Custom Themes**: Fully customizable visual themes
- **Responsive Design**: Adaptive UI that works on different screen sizes
- **Menu Integration**: Built-in game menus and settings screens

### 🔧 Developer-Friendly
- **Custom Commands**: Extend functionality with GDScript integration
- **Asset Management**: Efficient resource loading and management
- **Debug Tools**: Built-in debugging and testing utilities
- **Documentation**: Comprehensive bilingual documentation

## 🚀 Quick Start

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/AheadGameStudio/Argode.git
   cd Argode
   ```

2. **Open in Godot**:
   - Launch Godot Engine (4.x required)
   - Click "Import" and select the `project.godot` file
   - Wait for the project to import and compile

3. **Run the demo**:
   - Press F5 or click the play button
   - Select the main scene when prompted (or create a new scene for your game)

### Basic Usage

1. **Create your first scenario**:
   ```rgd
   # scenarios/my_story.rgd
   character yuko "Yuko" color:#4A90E2
   
   label start:
   
       scene bg common/bg_room.png
       
       yuko happy "Hello! Welcome to Argode!"
       yuko normal "This is your first visual novel scene."
       
       menu:
           "Continue the story":
               yuko excited "Great! Let's explore more features..."
               jump next_scene
           "Save the game":
               save 1
               yuko normal "Game saved! You can load it anytime."
               jump next_scene
   
   label next_scene:
   
       yuko normal "Thanks for trying Argode!"
       return
   ```

2.  **Load the scenario**:
    ```gdscript
    # Call this in your Main scene.
    
    # Specify the message window that inherits from ArgodeScreen and was added to the scene
    @onready var argode_gui: ArgodeScreen = %ArgodeGui

    func _ready() -> void:
        # Wait for the message window to be ready
        await argode_gui.screen_ready

        # Ensure both ArgodeSystem and UIManager exist to avoid errors
        if ArgodeSystem and ArgodeSystem.UIManager:
            # Jump to the 'start' label to begin
            argode_gui.jump_to("start")
        else:
            print("❌ ArgodeSystem or UIManager not found")
    ```

## 📚 Documentation

- **English**: [Full Documentation](https://aheadgamestudio.github.io/Argode/)
- **日本語**: [完全なドキュメント](https://aheadgamestudio.github.io/Argode/ja/)

### Key Topics
Visit our online documentation for detailed guides:
- [Getting Started](https://aheadgamestudio.github.io/Argode/getting-started/quick-start/)
- [RGD Script Reference](https://aheadgamestudio.github.io/Argode/script/rgd-syntax/)
- [Save & Load System](https://aheadgamestudio.github.io/Argode/save-load/index/)
- [Custom Commands](https://aheadgamestudio.github.io/Argode/custom-commands/overview/)
- [API Reference](https://aheadgamestudio.github.io/Argode/api/argode-system/)

## 🎮 Core Commands

### Basic Commands
- `character` - Defines a character with sprites and properties
- `scene` - Sets the background image and scene
- `audio` - Plays audio data
- `menu` - Creates interactive choices

### Save System Commands
- `save [slot]` - Saves the game to a specified slot (1 or higher)
- `load [slot]` - Loads the game from a specified slot (0 or higher)
- `capture` - Takes a temporary screenshot for the save thumbnail

### Advanced Commands
- `fade` - Screen transitions and effects
- `wait` - Pauses execution for timing control
- `set` - Creates variables, arrays, and dictionaries

## 🛠️ Development

### Requirements
- Godot Engine 4.x
- Basic knowledge of GDScript (for custom commands)

### Development Tools

#### VS Code RGD Syntax Highlighter
For the best development experience, install our official VS Code extension:

**[Argode RGD Syntax Highlighter](https://github.com/AheadGameStudio/Argode-rgd-syntax-highlighter)**

✨ **Features:**
- **Syntax Highlighting**: Full support for RGD script syntax with beautiful color themes
- **Smart Indentation**: Automatic indentation for labels, menus, and choices
- **Code Folding**: Collapsible label blocks for better organization

📦 **Installation:**
1. Download the `.vsix` file from the [releases page](https://github.com/AheadGameStudio/Argode-rgd-syntax-highlighter)
2. Open VS Code → Extensions (Ctrl+Shift+X)
3. Click "..." → "Install from VSIX"
4. Select the downloaded file

### Project Structure
If you create definition files with a `.rgd` extension inside the `definitions` directory, ArgodeSystem will automatically load them first.
Similarly, `.gd` files in `custom/commands` that inherit from `BaseCustomCommand` are also automatically loaded as user-defined custom commands.

```
addons/argode/          # Core framework files
├── core/               # Main system components
├── builtin/            # Built-in commands
├── commands/           # Command handling system
└── managers/           # Game state managers

custom/                 # Your custom commands (optional)
└── commands/          # Custom command implementations

definitions/            # Asset and character definitions (optional)
├── assets.rgd          # Image, audio, and UI definitions
├── characters.rgd      # Character definitions
└── variables.rgd       # Global variable definitions

scenarios/              # Story scripts (.rgd files)
└── main.rgd            # Scenario file

Root files:
├── project.godot       # Godot project file
└── README.md           # This file
```

**Documentation:** Full documentation is available online at [https://aheadgamestudio.github.io/Argode/](https://aheadgamestudio.github.io/Argode/)

**Note:** Development files (test/, tools/, assets/, scenes/, docs/, etc.) are excluded from distribution to keep the framework clean and focused.

### Creating Custom Commands
```gdscript
# custom/commands/MyCommand.gd
extends BaseCustomCommand

func _init():
    command_name = "mycommand"
    description = "My custom command"

func execute(args: Array, context: Dictionary) -> Dictionary:
    # Your custom logic here
    return {"success": true}
```

## 🤝 Contributing

We welcome contributions! Please read our [Contributing Guidelines](CONTRIBUTING.md) before submitting pull requests.

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- **Documentation**: https://aheadgamestudio.github.io/Argode/
- **VS Code Extension**: https://github.com/AheadGameStudio/Argode-rgd-syntax-highlighter
- **Issues**: https://github.com/AheadGameStudio/Argode/issues
- **Discussions**: https://github.com/AheadGameStudio/Argode/discussions

## 🙏 Acknowledgements

Thank you to all contributors who help make Argode better for the visual novel development community.

---

**Made with ❤️ for visual novel creators using Godot Engine**
