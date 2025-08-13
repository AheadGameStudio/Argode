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
   - Select `scenes/ui/base_ui.tscn` as the main scene when prompted

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

2. **Load your scenario**:
   ```gdscript
   # In your GDScript code
   ArgodeSystem.load_scenario("res://scenarios/my_story.rgd")
   ```

## 📚 Documentation

- **English**: [Full Documentation](https://aheadgamestudio.github.io/Argode/)
- **日本語**: [完全なドキュメント](https://aheadgamestudio.github.io/Argode/ja/)

### Key Topics
- [Getting Started](docs/getting-started/quick-start.md)
- [RGD Script Reference](docs/script/rgd-syntax.md)
- [Save & Load System](docs/save-load/index.md)
- [Custom Commands](docs/custom-commands/overview.md)
- [API Reference](docs/api/argode-system.md)

## 🎮 Core Commands

### Basic Commands
- `character` - Define characters with sprites and properties
- `scene` - Set background images and scenes
- `music` - Play background music
- `sound` - Play sound effects
- `menu` - Create interactive choices

### Save System Commands
- `save [slot]` - Save game to specified slot (1+)
- `load [slot]` - Load game from specified slot (0+)
- `capture` - Take temporary screenshot for clean save thumbnails

### Advanced Commands
- `fade` - Screen transitions and effects
- `wait` - Pause execution for timing
- `define` - Create reusable definitions
- `variable` - Manage game variables

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
- **Ren'Py-like Experience**: Familiar syntax highlighting for visual novel developers

📦 **Installation:**
1. Download the `.vsix` file from the [releases page](https://github.com/AheadGameStudio/Argode-rgd-syntax-highlighter)
2. Open VS Code → Extensions (Ctrl+Shift+X)
3. Click "..." → "Install from VSIX"
4. Select the downloaded file

### Project Structure
```
addons/argode/          # Core framework files
scenarios/              # Your story scripts (.rgd files)
characters/             # Character definitions
assets/                 # Images, audio, and other resources
custom/                 # Custom commands and extensions
docs/                   # Documentation source
```

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

## 🙏 Acknowledgments

Special thanks to all contributors who help make Argode better for the visual novel development community.

---

**Made with ❤️ for visual novel creators using Godot Engine**