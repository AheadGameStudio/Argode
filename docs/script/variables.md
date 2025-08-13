# Variables and Expressions Reference

Variables in Argode allow you to store and manage dynamic data throughout your visual novel. This includes player choices, character stats, game flags, and any other information that changes during gameplay.

## Basic Variable Usage

Variables are declared and assigned values using the `set` command.

### `set` Command

The `set` command assigns a value to a variable. If the variable doesn't exist, it will be created. The `set` command also supports **dot notation** for dictionary key assignment, making it easier to work with nested data structures.

**Basic Syntax:**
```rgd
set <variable_name> = <value>
```

**Dot Notation Syntax:**
```rgd
set <dict_name>.<key> = <value>
set <dict_name>.<nested_key>.<sub_key> = <value>
```

**Examples:**

```rgd
# Setting different data types
set player_name = "Alice"
set player_level = 1
set game_progress = 0.5
set tutorial_completed = true

# Variables can be updated
set player_level = player_level + 1

# Dot notation for dictionary keys (NEW!)
set player.name = "Alice"
set player.level = 1
set player.stats.hp = 100
set player.stats.mp = 50

# Automatic dictionary creation - no need to pre-define dictionaries
set character.info.age = 25
set character.info.gender = "female"
```

### Supported Data Types

Argode variables support common data types:

-   **String:** Text enclosed in double quotes (`""`).
-   **Integer:** Whole numbers (e.g., `1`, `100`, `-5`).
-   **Float:** Decimal numbers (e.g., `1.5`, `3.14`, `0.0`).
-   **Boolean:** `true` or `false`.

## Accessing Variables

Variables can be accessed in dialogue and as parameters for commands.

### In Dialogue

To display a variable's value directly within dialogue, enclose the variable name in curly braces `{}` or square brackets `[]`. Both notations are supported.

```rgd
narrator "Welcome, {player_name}! You are level {player_level}."
narrator "Welcome, [player_name]! You are level [player_level]."

# Accessing dictionary values with dot notation
narrator "Hello, {player.name}! Your HP is {player.stats.hp}."

# Array access is also supported
narrator "Your first item is {inventory[0]}."
```

### In Commands

Variables can be used as values for command parameters. The variable's current value will be substituted.

```rgd
set target_x = 500
show character_name at x={target_x} y=200
```

## Complex Data Types: Arrays and Dictionaries

Argode also supports more complex data structures: arrays and dictionaries, using dedicated commands.

### Arrays (`set_array`)

Arrays are ordered collections of values. Use the `set_array` command to create or update an array variable.

**Syntax:**
```rgd
set_array <variable_name> [value1, value2, ...]
```

**Example:**

```rgd
set_array inventory ["sword", "shield", "potion"]
narrator "Your first item is {inventory[0]}."
```

### Dictionaries (`set_dict` and dot notation)

Dictionaries (or maps/hash tables) are collections of key-value pairs. You can create dictionaries using either the traditional `set_dict` command or the more intuitive dot notation with the `set` command.

**Traditional Syntax:**
```rgd
set_dict <variable_name> {key1: value1, key2: value2, ...}
```

**Dot Notation Syntax (Recommended):**
```rgd
set <dict_name>.<key> = <value>
```

**Examples:**

```rgd
# Traditional method (still supported)
set_dict player_stats {"name": "Hero", "hp": 100, "mp": 50}

# New dot notation method (recommended)
set player.name = "Hero"
set player.hp = 100
set player.mp = 50

# Automatic nested dictionary creation
set player.stats.strength = 15
set player.stats.agility = 12
set player.inventory.weapons.sword = "Steel Sword"

narrator "{player.name} has {player.hp} HP."
narrator "Weapon: {player.inventory.weapons.sword}"
```

**Benefits of Dot Notation:**
- **No pre-definition required**: Dictionaries and nested structures are created automatically
- **Intuitive syntax**: More natural way to assign individual dictionary keys
- **Backward compatible**: Existing `set_dict` commands continue to work
- **Flexible nesting**: Supports arbitrary levels of nested dictionaries

## Conditional Logic

You can control the flow of your story based on variable values using `if`, `elif`, and `else` statements.

### `if`, `elif`, `else`

```rgd
if player_level >= 10:
    narrator "You are a seasoned adventurer!"
elif player_level >= 5:
    narrator "You are making good progress."
else:
    narrator "You are just starting your journey."
```

### Comparison Operators

-   `==` (equal to)
-   `!=` (not equal to)
-   `<` (less than)
-   `>` (greater than)
-   `<=` (less than or equal to)
-   `>=` (greater than or equal to)

### Logical Operators

-   `and`
-   `or`
-   `not`

```rgd
if player_level >= 5 and has_sword:
    narrator "You are ready for the next challenge."
```

## Best Practices

-   **Descriptive Names:** Use clear and descriptive names for your variables (e.g., `player_health` instead of `hp`).
-   **Consistency:** Maintain consistent naming conventions throughout your project.
-   **Avoid Conflicts:** Be mindful of variable names to avoid accidentally overwriting important data.

---

Understanding variables is key to creating dynamic and responsive visual novels in Argode.
