# RGD Script Syntax Reference

RGD (Ren'Py-like Godot) Script is the core language for writing your visual novel stories in Argode. It's designed to be simple, human-readable, and intuitive for visual novel creators.

## Basic Structure

RGD scripts are plain text files with a `.rgd` extension. They are parsed line by line, and indentation is used to define blocks of code.

### Comments

Lines starting with `#` are treated as comments and are ignored by the parser.

```rgd
# This is a single-line comment

label start: # You can also add comments at the end of a line
    narrator "Hello, world!"
```

### Labels

Labels define points in your script that you can jump to. They are declared with the `label` keyword followed by the label name and a colon (`:`).

```rgd
label start:
    narrator "This is the beginning of the story."
    jump chapter_one

label chapter_one:
    narrator "Welcome to chapter one!"
```

### Indentation

Indentation (using spaces, typically 4 spaces) is crucial in RGD scripts to define blocks of code, such as within `label` blocks, `menu` blocks, or conditional statements.

```rgd
label example_block:
    # This line is part of 'example_block'
    narrator "Indentation defines code blocks."
    
    menu:
        "Option A":
            # This line is part of 'Option A' block
            narrator "You chose A."
        "Option B":
            # This line is part of 'Option B' block
            narrator "You chose B."
```

## Dialogue

Dialogue is the most common element in a visual novel script. RGD supports both character dialogue and narrator dialogue.

### Character Dialogue

To make a character speak, simply type the character's name (as defined by a `character` statement) followed by their dialogue in quotes.

```rgd
character alice "Alice" # Define Alice first

alice "Hello there!"
alice "It's a beautiful day, isn't it?"
```

### Narrator Dialogue

For narration or internal thoughts, simply type the dialogue in quotes without a character name.

```rgd
narrator "The sun rose slowly over the horizon."
"A new day had begun."
```

## Commands

Commands are special instructions that tell Argode to perform actions, such as showing characters, changing backgrounds, playing sounds, or controlling the UI. Commands are typically a single line.

```rgd
show alice happy at center with fade
scene forest_day with dissolve
play_music "bgm_peaceful.ogg"
ui show "res://ui/main_menu.tscn"
```

For a complete list of available commands and their usage, refer to the [Commands Reference](commands.md).

## Flow Control

Flow control statements allow you to direct the narrative flow, create branching paths, and manage subroutines.

### `jump`

The `jump` command transfers control unconditionally to a specified label. The script will continue execution from that label.

```rgd
label start:
    narrator "Welcome to the story."
    jump chapter_one

label chapter_one:
    narrator "This is chapter one."
    # ... script continues here
```

### `call` and `return`

The `call` command is used to execute a subroutine. It jumps to a label, and when that label's block finishes (or encounters a `return` statement), control returns to the line immediately after the `call`.

```rgd
label start:
    narrator "Calling a subroutine."
    call my_subroutine
    narrator "Returned from subroutine."

label my_subroutine:
    narrator "Inside the subroutine."
    # ... some actions
    return # Optional, control returns automatically at end of block
```

### `menu`

The `menu` statement presents the player with a list of choices. The script pauses until the player makes a selection, and then executes the block of code associated with that choice.

```rgd
label make_a_choice:
    narrator "What will you do?"
    menu:
        "Go left":
            narrator "You went left."
            jump path_left
        "Go right":
            narrator "You went right."
            jump path_right
        "Stay here":
            narrator "You decided to stay."
            jump stay_here
```

## Variables and Expressions

Argode supports variables to store game state, player choices, and other dynamic data. Variables can be embedded directly into dialogue using curly braces `{}`.

```rgd
set player_name = "Hero"
narrator "Hello, {player_name}!"

if player_level >= 10:
    narrator "You are a powerful adventurer."
```

For more details on variables and expressions, refer to the [Variables & Expressions Reference](variables.md).

## Definitions

Definitions allow you to pre-define characters, images, audio, and shaders, making them easily accessible throughout your script. Definitions are typically placed at the beginning of your `.rgd` files or in dedicated definition files (e.g., `definitions/characters.rgd`).

```rgd
character alice "Alice" color=#ff69b4
image bg forest_day "res://assets/images/backgrounds/forest_day.png"
audio music peaceful "res://assets/audio/music/peaceful.ogg"
```

For a comprehensive guide on definitions, refer to the [Definitions Reference](definitions.md).
