# ArgodeController.gd
extends Node

class_name ArgodeController

## フレームワーク全体のプレイヤー入力を一元管理する
## このクラスは、Godotのプロジェクト設定で定義された入力アクションを使い、
## 入力イベントを他のマネージャーやサービスに伝達する。

# 入力が現在許可されているかどうか
var _is_input_enabled: bool = true

# 入力アクションが押されたときに送信されるシグナル
signal input_action_pressed(action_name)
# 入力アクションが離されたときに送信されるシグナル
signal input_action_released(action_name)

# フレームが処理されるたびに入力をチェックする
func _process(delta):
    if not _is_input_enabled:
        return

    # 全ての入力アクションをチェック
    for action in InputMap.get_actions():
        if Input.is_action_just_pressed(action):
            _on_action_just_pressed(action)
        if Input.is_action_just_released(action):
            _on_action_just_released(action)

func _on_action_just_pressed(action_name: String):
    # 特定のアクションが押されたときの処理
    # 例: "ui_accept"アクションが押された場合、対話マネージャーに通知
    # ArgodeSystem.get_manager("DialogueManager").process_input("accept")
    
    # input_action_pressedシグナルを送信
    ArgodeSystem.log("Input action pressed: %s" % action_name)
    emit_signal("input_action_pressed", action_name)

func _on_action_just_released(action_name: String):
    # 特定のアクションが離されたときの処理
    
    # input_action_releasedシグナルを送信
    emit_signal("input_action_released", action_name)

## 入力を有効にする
func enable_input():
    _is_input_enabled = true

## 入力を無効にする
func disable_input():
    _is_input_enabled = false

## === InputMap動的管理機能 ===

## 新しい入力アクションを追加
func add_input_action(action_name: String, deadzone: float = 0.5) -> bool:
    if InputMap.has_action(action_name):
        ArgodeSystem.log("⚠️ Input action '%s' already exists" % action_name)
        return false
    
    InputMap.add_action(action_name, deadzone)
    ArgodeSystem.log("✅ Added input action: %s (deadzone: %.2f)" % [action_name, deadzone])
    return true

## 入力アクションを削除
func remove_input_action(action_name: String) -> bool:
    if not InputMap.has_action(action_name):
        ArgodeSystem.log("⚠️ Input action '%s' does not exist" % action_name)
        return false
    
    InputMap.erase_action(action_name)
    ArgodeSystem.log("🗑️ Removed input action: %s" % action_name)
    return true

## 入力アクションにキーバインドを追加
func add_key_to_action(action_name: String, keycode: Key, physical: bool = false) -> bool:
    if not InputMap.has_action(action_name):
        ArgodeSystem.log("❌ Input action '%s' does not exist" % action_name)
        return false
    
    var event = InputEventKey.new()
    event.keycode = keycode
    event.physical_keycode = keycode if physical else KEY_NONE
    
    InputMap.action_add_event(action_name, event)
    ArgodeSystem.log("🎮 Added key %s to action '%s'" % [OS.get_keycode_string(keycode), action_name])
    return true

## 入力アクションにマウスボタンを追加
func add_mouse_button_to_action(action_name: String, button: MouseButton) -> bool:
    if not InputMap.has_action(action_name):
        ArgodeSystem.log("❌ Input action '%s' does not exist" % action_name)
        return false
    
    var event = InputEventMouseButton.new()
    event.button_index = button
    
    InputMap.action_add_event(action_name, event)
    ArgodeSystem.log("🖱️ Added mouse button %d to action '%s'" % [button, action_name])
    return true

## 入力アクションにジョイパッドボタンを追加
func add_joypad_button_to_action(action_name: String, button: JoyButton, device: int = -1) -> bool:
    if not InputMap.has_action(action_name):
        ArgodeSystem.log("❌ Input action '%s' does not exist" % action_name)
        return false
    
    var event = InputEventJoypadButton.new()
    event.button_index = button
    event.device = device
    
    InputMap.action_add_event(action_name, event)
    ArgodeSystem.log("🎮 Added joypad button %d to action '%s'" % [button, action_name])
    return true

## 入力アクションにジョイパッド軸を追加
func add_joypad_axis_to_action(action_name: String, axis: JoyAxis, axis_value: float, device: int = -1) -> bool:
    if not InputMap.has_action(action_name):
        ArgodeSystem.log("❌ Input action '%s' does not exist" % action_name)
        return false
    
    var event = InputEventJoypadMotion.new()
    event.axis = axis
    event.axis_value = axis_value
    event.device = device
    
    InputMap.action_add_event(action_name, event)
    ArgodeSystem.log("🕹️ Added joypad axis %d (value: %.2f) to action '%s'" % [axis, axis_value, action_name])
    return true

## 入力アクションから特定のイベントを削除
func remove_event_from_action(action_name: String, event: InputEvent) -> bool:
    if not InputMap.has_action(action_name):
        ArgodeSystem.log("❌ Input action '%s' does not exist" % action_name)
        return false
    
    InputMap.action_erase_event(action_name, event)
    ArgodeSystem.log("🗑️ Removed event from action '%s'" % action_name)
    return true

## 入力アクションのすべてのイベントをクリア
func clear_action_events(action_name: String) -> bool:
    if not InputMap.has_action(action_name):
        ArgodeSystem.log("❌ Input action '%s' does not exist" % action_name)
        return false
    
    var events = InputMap.action_get_events(action_name)
    for event in events:
        InputMap.action_erase_event(action_name, event)
    
    ArgodeSystem.log("🧹 Cleared all events from action '%s'" % action_name)
    return true

## 入力アクションのデッドゾーンを設定
func set_action_deadzone(action_name: String, deadzone: float) -> bool:
    if not InputMap.has_action(action_name):
        ArgodeSystem.log("❌ Input action '%s' does not exist" % action_name)
        return false
    
    InputMap.action_set_deadzone(action_name, deadzone)
    ArgodeSystem.log("🎯 Set deadzone for action '%s' to %.2f" % [action_name, deadzone])
    return true

## === 便利な高レベル関数 ===

## キーバインドセットを一括で追加
func add_key_binding_set(bindings: Dictionary) -> bool:
    var success = true
    for action_name in bindings:
        var binding_data = bindings[action_name]
        
        # アクションを追加（存在しない場合）
        if not InputMap.has_action(action_name):
            var deadzone = binding_data.get("deadzone", 0.5)
            add_input_action(action_name, deadzone)
        
        # キーバインドを追加
        if binding_data.has("keys"):
            for key in binding_data.keys:
                if not add_key_to_action(action_name, key):
                    success = false
        
        # マウスボタンを追加
        if binding_data.has("mouse_buttons"):
            for button in binding_data.mouse_buttons:
                if not add_mouse_button_to_action(action_name, button):
                    success = false
        
        # ジョイパッドボタンを追加
        if binding_data.has("joypad_buttons"):
            for button in binding_data.joypad_buttons:
                if not add_joypad_button_to_action(action_name, button):
                    success = false
    
    return success

## Argode用デフォルトキーバインドを設定
## TODO: 本番では修正予定。
func setup_argode_default_bindings():
    var argode_bindings = {
        "argode_advance": {
            "keys": [KEY_SPACE, KEY_ENTER],
            "mouse_buttons": [MOUSE_BUTTON_LEFT],
            "joypad_buttons": [JOY_BUTTON_A],
            "deadzone": 0.2
        },
        "argode_skip": {
            "keys": [KEY_CTRL],
            "mouse_buttons": [MOUSE_BUTTON_RIGHT],
            "joypad_buttons": [JOY_BUTTON_B],
            "deadzone": 0.2
        },
        "argode_menu": {
            "keys": [KEY_ESCAPE, KEY_M],
            "joypad_buttons": [JOY_BUTTON_START],
            "deadzone": 0.2
        },
        "argode_save": {
            "keys": [KEY_S],
            "deadzone": 0.2
        },
        "argode_load": {
            "keys": [KEY_L],
            "deadzone": 0.2
        }
    }
    
    ArgodeSystem.log("🎮 Setting up Argode default key bindings...")
    return add_key_binding_set(argode_bindings)

## 現在の入力マップをログ出力（デバッグ用）
func debug_print_input_map():
    ArgodeSystem.log("=== Current InputMap ===")
    for action in InputMap.get_actions():
        var events = InputMap.action_get_events(action)
        var deadzone = InputMap.action_get_deadzone(action)
        ArgodeSystem.log("Action: %s (deadzone: %.2f)" % [action, deadzone])
        for event in events:
            ArgodeSystem.log("  - %s" % event)
    ArgodeSystem.log("========================")

## === 使用例とヘルパー関数 ===

## シナリオ進行用のキーバインドを設定
func setup_story_mode_bindings():
    # 既存のバインドをクリア
    clear_action_events("argode_advance")
    clear_action_events("argode_skip")
    
    # ストーリーモード用のバインドを設定
    add_key_to_action("argode_advance", KEY_SPACE)
    add_key_to_action("argode_advance", KEY_ENTER)
    add_mouse_button_to_action("argode_advance", MOUSE_BUTTON_LEFT)
    
    add_key_to_action("argode_skip", KEY_CTRL)
    add_mouse_button_to_action("argode_skip", MOUSE_BUTTON_RIGHT)
    
    ArgodeSystem.log("📖 Story mode key bindings configured")

## ミニゲーム用のキーバインドを設定
## ※サンプル実装
func setup_minigame_bindings():
    # ミニゲーム用の一時的なアクションを追加
    add_input_action("minigame_up", 0.1)
    add_input_action("minigame_down", 0.1)
    add_input_action("minigame_left", 0.1)
    add_input_action("minigame_right", 0.1)
    add_input_action("minigame_action", 0.2)
    
    # WASD + Spaceバインド
    add_key_to_action("minigame_up", KEY_W)
    add_key_to_action("minigame_down", KEY_S)
    add_key_to_action("minigame_left", KEY_A)
    add_key_to_action("minigame_right", KEY_D)
    add_key_to_action("minigame_action", KEY_SPACE)
    
    # 矢印キーバインド
    add_key_to_action("minigame_up", KEY_UP)
    add_key_to_action("minigame_down", KEY_DOWN)
    add_key_to_action("minigame_left", KEY_LEFT)
    add_key_to_action("minigame_right", KEY_RIGHT)
    
    # ジョイパッドバインド
    add_joypad_button_to_action("minigame_action", JOY_BUTTON_A)
    add_joypad_axis_to_action("minigame_up", JOY_AXIS_LEFT_Y, -1.0)
    add_joypad_axis_to_action("minigame_down", JOY_AXIS_LEFT_Y, 1.0)
    add_joypad_axis_to_action("minigame_left", JOY_AXIS_LEFT_X, -1.0)
    add_joypad_axis_to_action("minigame_right", JOY_AXIS_LEFT_X, 1.0)
    
    ArgodeSystem.log("🎯 Minigame key bindings configured")

## ミニゲーム終了時にバインドを削除
func cleanup_minigame_bindings():
    remove_input_action("minigame_up")
    remove_input_action("minigame_down")
    remove_input_action("minigame_left")
    remove_input_action("minigame_right")
    remove_input_action("minigame_action")
    
    ArgodeSystem.log("🧹 Minigame key bindings cleaned up")

## カスタムキーコンフィグを適用
func apply_custom_key_config(config: Dictionary):
    for action_name in config:
        if InputMap.has_action(action_name):
            clear_action_events(action_name)
            var keys = config[action_name]
            for key in keys:
                add_key_to_action(action_name, key)
    
    ArgodeSystem.log("⚙️ Custom key configuration applied")
