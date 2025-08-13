# Save & Load Examples

This page provides practical examples of implementing save/load functionality in your Argode projects.

## Basic Save/Load Implementation

### Simple Save Points

Create save points at key moments in your story:

```renpy
# In your .rgd script
label chapter_1_start:
    "Welcome to Chapter 1!"
    "This looks like a good place to save."
    save 0 "Chapter 1 Start"
    
    "The story continues..."
    
label important_choice:
    "An important decision approaches..."
    save 1 "Before Important Choice"
    
    menu:
        "Choose your path":
        "Path A":
            jump path_a
        "Path B":
            jump path_b
```

### Auto-Save Integration

Implement automatic saving at key points:

```gdscript
# In your custom command or game logic
extends BaseCustomCommand

func _init():
    command_name = "auto_checkpoint"
    description = "Create an auto-save checkpoint"

func execute(params: Dictionary, adv_system: Node) -> bool:
    # Auto-save the current state
    var success = adv_system.SaveLoadManager.auto_save()
    
    if success:
        # Show brief save notification
        adv_system.UIManager.show_notification("Game Saved")
    
    return success
```

## Save Menu Implementation

### Custom Save/Load UI

Create a custom save/load interface:

```gdscript
# SaveLoadMenu.gd
extends Control
class_name SaveLoadMenu

@onready var save_slots = $VBoxContainer/SaveSlots
@onready var load_button = $VBoxContainer/LoadButton
@onready var save_button = $VBoxContainer/SaveButton

var selected_slot = -1

func _ready():
    _refresh_save_slots()
    
func _refresh_save_slots():
    # Clear existing slots
    for child in save_slots.get_children():
        child.queue_free()
    
    # Create slots 0-8 (reserve 9 for auto-save)
    for i in range(9):
        var slot_button = _create_slot_button(i)
        save_slots.add_child(slot_button)

func _create_slot_button(slot_index: int) -> Button:
    var button = Button.new()
    var save_info = ArgodeSystem.get_save_info(slot_index)
    
    if save_info.is_empty():
        button.text = "Slot %d - Empty" % (slot_index + 1)
    else:
        var date_str = save_info.get("save_date", "Unknown")
        button.text = "Slot %d - %s\n%s" % [
            slot_index + 1,
            save_info.get("save_name", "Unnamed Save"),
            date_str
        ]
    
    button.pressed.connect(_on_slot_selected.bind(slot_index))
    return button

func _on_slot_selected(slot_index: int):
    selected_slot = slot_index
    load_button.disabled = ArgodeSystem.get_save_info(slot_index).is_empty()
    save_button.disabled = false

func _on_save_pressed():
    if selected_slot >= 0:
        var save_name = "Save %d" % (selected_slot + 1)
        var success = ArgodeSystem.save_game(selected_slot, save_name)
        if success:
            _refresh_save_slots()

func _on_load_pressed():
    if selected_slot >= 0:
        ArgodeSystem.load_game(selected_slot)
```

### Integration with RGD Scripts

Use the save menu from scripts:

```renpy
# Show save menu command
save_menu

# Show load menu command  
load_menu

# Quick save to specific slot
save 0 "Quick Save"
```

## Advanced Save Features

### Save Data Validation

Implement save data validation:

```gdscript
# SaveValidator.gd
extends RefCounted
class_name SaveValidator

static func validate_save_data(save_data: Dictionary) -> bool:
    # Check required fields
    var required_fields = ["version", "variables", "save_time"]
    for field in required_fields:
        if not save_data.has(field):
            push_error("Save data missing required field: " + field)
            return false
    
    # Validate version compatibility
    var save_version = save_data.get("version", "1.0")
    if not _is_version_compatible(save_version):
        push_error("Incompatible save version: " + save_version)
        return false
    
    return true

static func _is_version_compatible(version: String) -> bool:
    # Define version compatibility rules
    var compatible_versions = ["2.0", "2.1"]
    return version in compatible_versions
```

### Custom Save Data Extension

Add custom data to saves:

```gdscript
# CustomSaveExtension.gd
extends Node

func _ready():
    # Connect to save system
    ArgodeSystem.SaveLoadManager.connect("game_saved", _on_game_saved)
    ArgodeSystem.SaveLoadManager.connect("game_loaded", _on_game_loaded)

func _on_game_saved(slot: int):
    # This is called after the main save is complete
    _save_additional_data(slot)

func _on_game_loaded(slot: int):
    # This is called after the main load is complete
    _load_additional_data(slot)

func _save_additional_data(slot: int):
    var additional_data = {
        "achievements": GameData.unlocked_achievements,
        "statistics": GameData.play_statistics,
        "settings": GameData.user_preferences
    }
    
    var file_path = "user://saves/slot_%d_extra.dat" % slot
    var file = FileAccess.open(file_path, FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(additional_data))
        file.close()

func _load_additional_data(slot: int):
    var file_path = "user://saves/slot_%d_extra.dat" % slot
    if FileAccess.file_exists(file_path):
        var file = FileAccess.open(file_path, FileAccess.READ)
        if file:
            var json_string = file.get_as_text()
            file.close()
            
            var json = JSON.new()
            if json.parse(json_string) == OK:
                var data = json.data
                GameData.unlocked_achievements = data.get("achievements", [])
                GameData.play_statistics = data.get("statistics", {})
                GameData.user_preferences = data.get("settings", {})
```

## Save System Events

### Progress Tracking

Track save/load progress for long operations:

```gdscript
# SaveProgressTracker.gd
extends Control

@onready var progress_bar = $ProgressBar
@onready var status_label = $StatusLabel

func _ready():
    # Connect to save system signals
    var save_manager = ArgodeSystem.SaveLoadManager
    save_manager.save_started.connect(_on_save_started)
    save_manager.save_progress.connect(_on_save_progress)
    save_manager.save_completed.connect(_on_save_completed)

func _on_save_started():
    show()
    progress_bar.value = 0
    status_label.text = "Preparing save data..."

func _on_save_progress(percentage: float, status: String):
    progress_bar.value = percentage
    status_label.text = status

func _on_save_completed(success: bool):
    if success:
        status_label.text = "Save completed!"
        await get_tree().create_timer(1.0).timeout
    else:
        status_label.text = "Save failed!"
        await get_tree().create_timer(2.0).timeout
    
    hide()
```

### Error Recovery

Implement error recovery for save operations:

```gdscript
# SaveErrorRecovery.gd
extends Node

const MAX_RETRY_ATTEMPTS = 3
var retry_count = 0

func _ready():
    ArgodeSystem.SaveLoadManager.save_failed.connect(_on_save_failed)
    ArgodeSystem.SaveLoadManager.load_failed.connect(_on_load_failed)

func _on_save_failed(slot: int, error: String):
    if retry_count < MAX_RETRY_ATTEMPTS:
        retry_count += 1
        print("Save failed, retrying... Attempt %d/%d" % [retry_count, MAX_RETRY_ATTEMPTS])
        
        # Wait a bit and retry
        await get_tree().create_timer(1.0).timeout
        ArgodeSystem.save_game(slot, "Retry Save")
    else:
        retry_count = 0
        _show_save_error_dialog(error)

func _on_load_failed(slot: int, error: String):
    _show_load_error_dialog(slot, error)

func _show_save_error_dialog(error: String):
    var dialog = AcceptDialog.new()
    dialog.dialog_text = "Failed to save game: " + error
    get_tree().current_scene.add_child(dialog)
    dialog.popup_centered()
    dialog.confirmed.connect(dialog.queue_free)

func _show_load_error_dialog(slot: int, error: String):
    var dialog = ConfirmationDialog.new()
    dialog.dialog_text = "Failed to load save slot %d: %s\n\nTry a different slot?" % [slot, error]
    get_tree().current_scene.add_child(dialog)
    dialog.popup_centered()
    dialog.confirmed.connect(_show_load_menu)
    dialog.get_cancel_button().pressed.connect(dialog.queue_free)

func _show_load_menu():
    # Show save/load menu for user to select different slot
    pass
```

## Performance Optimization

### Async Save Operations

Implement non-blocking save operations:

```gdscript
# AsyncSaveManager.gd
extends Node

signal save_completed(success: bool)

func save_game_async(slot: int, save_name: String):
    # Start async save operation
    _perform_async_save.call_deferred(slot, save_name)

func _perform_async_save(slot: int, save_name: String):
    var success = true
    
    # Perform save in chunks to avoid blocking
    for i in range(10):  # Simulate chunked operation
        await get_tree().process_frame
        # Perform partial save operation
        
    # Complete the save
    var final_success = ArgodeSystem.save_game(slot, save_name)
    save_completed.emit(final_success)
```

### Save Data Compression

Reduce save file size with compression:

```gdscript
# CompressedSaveManager.gd
extends SaveLoadManager

func save_game_compressed(slot: int, save_name: String) -> bool:
    var save_data = _collect_game_state()
    save_data["save_name"] = save_name
    save_data["save_date_string"] = Time.get_datetime_string_from_system()
    save_data["save_time"] = Time.get_unix_time_from_system()
    save_data["slot"] = slot
    save_data["version"] = SAVE_VERSION
    
    var json_string = JSON.stringify(save_data)
    var compressed_data = json_string.to_utf8_buffer().compress(FileAccess.COMPRESSION_GZIP)
    
    var file_path = SAVE_FOLDER + "slot_" + str(slot) + ".save"
    var file = FileAccess.open(file_path, FileAccess.WRITE)
    
    if file == null:
        push_error("Failed to create save file: " + file_path)
        return false
    
    file.store_32(compressed_data.size())  # Store original size
    file.store_buffer(compressed_data)
    file.close()
    
    return true

func load_game_compressed(slot: int) -> bool:
    var file_path = SAVE_FOLDER + "slot_" + str(slot) + ".save"
    if not FileAccess.file_exists(file_path):
        return false
    
    var file = FileAccess.open(file_path, FileAccess.READ)
    if file == null:
        return false
    
    var original_size = file.get_32()
    var compressed_data = file.get_buffer(file.get_length() - 4)
    file.close()
    
    var decompressed_data = compressed_data.decompress(original_size, FileAccess.COMPRESSION_GZIP)
    var json_string = decompressed_data.get_string_from_utf8()
    
    var json = JSON.new()
    if json.parse(json_string) != OK:
        return false
    
    var save_data = json.data
    return _restore_game_state(save_data)
```

These examples demonstrate various aspects of implementing a robust save/load system with the Argode framework, from basic functionality to advanced features like error recovery and performance optimization.
