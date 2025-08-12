# GDScriptからのカスタムコマンド実行

GDScript側からArgodeのカスタムコマンド（ui call、audioコマンドなど）を直接実行する方法について説明します。

## 🚀 基本的な実行方法

### 1. ArgodeSystemとCustomCommandHandlerの取得

```gdscript
extends Node

func _ready():
    # ArgodeSystemを取得
    var argode_system = get_node("/root/ArgodeSystem")
    if not argode_system:
        push_error("ArgodeSystem not found")
        return
    
    # CustomCommandHandlerを取得
    var custom_handler = argode_system.get_custom_command_handler()
    if not custom_handler:
        push_error("CustomCommandHandler not found")
        return
    
    # コマンド実行
    execute_ui_command(custom_handler)
```

### 2. パラメータ辞書の構築

カスタムコマンドはRGDスクリプトと同じ形式のパラメータ辞書を使用します：

```gdscript
func build_command_params(command_line: String) -> Dictionary:
    # 例: "call res://ui/menu.tscn at center with fade"
    var args = command_line.split(" ")
    var params = {
        "_raw": command_line,
        "_count": args.size()
    }
    
    # 各引数をarg0, arg1, ...として格納
    for i in range(args.size()):
        params["arg" + str(i)] = args[i]
    
    return params
```

### 3. コマンドの実行

```gdscript
func execute_ui_command_example(custom_handler: CustomCommandHandler):
    # ui callコマンドの実行
    var ui_params = {
        "_raw": "call res://ui/choice_menu.tscn at center with fade",
        "_count": 6,
        "arg0": "call",
        "arg1": "res://ui/choice_menu.tscn",
        "arg2": "at",
        "arg3": "center", 
        "arg4": "with",
        "arg5": "fade"
    }
    
    print("🎯 Executing ui call command from GDScript")
    
    # 登録されたUICommandを取得して直接実行
    var ui_command = custom_handler.registered_commands.get("ui")
    if ui_command:
        await custom_handler._execute_registered_command(ui_command, ui_params)
    else:
        push_error("UI command not found in registered commands")
```

## 🎯 UIコマンドの便利メソッド

### ui callコマンド（モーダル表示）

```gdscript
func call_ui_scene(scene_path: String, position: String = "center", transition: String = "fade"):
    """ui callコマンドの簡単実行 - スクリプトはシーンが閉じるまで待機"""
    var argode_system = get_node("/root/ArgodeSystem")
    var custom_handler = argode_system.get_custom_command_handler()
    
    var params = {
        "_raw": "call " + scene_path + " at " + position + " with " + transition,
        "_count": 6,
        "arg0": "call",
        "arg1": scene_path,
        "arg2": "at",
        "arg3": position,
        "arg4": "with",
        "arg5": transition
    }
    
    # 登録されたUICommandを取得して実行
    var ui_command = custom_handler.registered_commands.get("ui")
    if ui_command:
        await custom_handler._execute_registered_command(ui_command, params)
    else:
        push_error("UI command not found")

# 使用例
func _on_choice_button_pressed():
    await call_ui_scene("res://ui/player_choice.tscn", "center", "fade")
    print("プレイヤーが選択を完了しました")  # 選択後に実行される
```

### ui showコマンド（通常表示）

```gdscript
func show_ui_scene(scene_path: String, position: String = "center", transition: String = "none"):
    """ui showコマンドの簡単実行 - スクリプトは継続実行"""
    var argode_system = get_node("/root/ArgodeSystem")
    var custom_handler = argode_system.get_custom_command_handler()
    
    var params = {
        "_raw": "show " + scene_path + " at " + position + " with " + transition,
        "_count": 6,
        "arg0": "show",
        "arg1": scene_path,
        "arg2": "at",
        "arg3": position,
        "arg4": "with",
        "arg5": transition
    }
    
    # 登録されたUICommandを取得して実行
    var ui_command = custom_handler.registered_commands.get("ui")
    if ui_command:
        ui_command.execute(params, argode_system)
    else:
        push_error("UI command not found")

# 使用例
func _on_status_button_pressed():
    show_ui_scene("res://ui/status_panel.tscn", "right", "slide")
    print("ステータス画面を表示しました")  # 即座に実行される
```

### ui closeコマンド（call_screen終了）

```gdscript
func close_ui_call_screen(scene_path: String = ""):
    """ui closeコマンドの簡単実行"""
    var argode_system = get_node("/root/ArgodeSystem")
    var custom_handler = argode_system.get_custom_command_handler()
    
    var params = {}
    if scene_path.is_empty():
        # 最後のcall_screenを閉じる
        params = {
            "_raw": "close",
            "_count": 1,
            "arg0": "close"
        }
    else:
        # 指定されたシーンを閉じる
        params = {
            "_raw": "close " + scene_path,
            "_count": 2,
            "arg0": "close",
            "arg1": scene_path
        }
    
    # 登録されたUICommandを取得して実行
    var ui_command = custom_handler.registered_commands.get("ui")
    if ui_command:
        ui_command.execute(params, argode_system)
    else:
        push_error("UI command not found")

# 使用例
func _on_cancel_button_pressed():
    close_ui_call_screen()  # 最後のcall_screenを閉じる
    close_ui_call_screen("res://ui/specific_menu.tscn")  # 特定のシーンを閉じる
```

## 🔍 UI状態確認メソッド

### call_screenの表示状況を確認

```gdscript
func is_call_screen_active(scene_path: String = "") -> bool:
    """指定されたcall_screenが表示中かどうかを確認"""
    var argode_system = get_node("/root/ArgodeSystem")
    var custom_handler = argode_system.get_custom_command_handler()
    var ui_command = custom_handler.registered_commands.get("ui")
    
    if not ui_command:
        push_error("UI command not found")
        return false
    
    if scene_path.is_empty():
        # 何らかのcall_screenが表示中かを確認
        return not ui_command.call_screen_stack.is_empty()
    else:
        # 指定されたシーンがcall_screen_stackにあるかを確認
        return scene_path in ui_command.call_screen_stack

func get_active_call_screens() -> Array[String]:
    """表示中のcall_screen一覧を取得"""
    var argode_system = get_node("/root/ArgodeSystem")
    var custom_handler = argode_system.get_custom_command_handler()
    var ui_command = custom_handler.registered_commands.get("ui")
    
    if not ui_command:
        push_error("UI command not found")
        return []
    
    return ui_command.call_screen_stack.duplicate()

func get_current_call_screen() -> String:
    """現在表示中の最上位call_screenを取得"""
    var argode_system = get_node("/root/ArgodeSystem")
    var custom_handler = argode_system.get_custom_command_handler()
    var ui_command = custom_handler.registered_commands.get("ui")
    
    if not ui_command:
        push_error("UI command not found")
        return ""
    
    if ui_command.call_screen_stack.is_empty():
        return ""
    
    return ui_command.call_screen_stack[-1]  # 最後の要素（最上位）

func is_ui_scene_active(scene_path: String) -> bool:
    """指定されたUIシーンが表示中かどうかを確認（call/show問わず）"""
    var argode_system = get_node("/root/ArgodeSystem")
    var custom_handler = argode_system.get_custom_command_handler()
    var ui_command = custom_handler.registered_commands.get("ui")
    
    if not ui_command:
        push_error("UI command not found")
        return false
    
    return scene_path in ui_command.active_ui_scenes

func get_all_active_ui_scenes() -> Array[String]:
    """表示中のすべてのUIシーン一覧を取得"""
    var argode_system = get_node("/root/ArgodeSystem")
    var custom_handler = argode_system.get_custom_command_handler()
    var ui_command = custom_handler.registered_commands.get("ui")
    
    if not ui_command:
        push_error("UI command not found")
        return []
    
    return ui_command.active_ui_scenes.keys()
```

### 使用例

```gdscript
# 特定のメニューが表示中かチェック
func _on_pause_button_pressed():
    if is_call_screen_active("res://ui/pause_menu.tscn"):
        print("ポーズメニューは既に表示中です")
        return
    
    # ポーズメニューを表示
    await call_ui_scene("res://ui/pause_menu.tscn")

# 現在のcall_screenを確認
func _on_check_current_menu():
    var current_menu = get_current_call_screen()
    if current_menu.is_empty():
        print("現在表示中のcall_screenはありません")
    else:
        print("現在のメニュー: " + current_menu)

# 複数のcall_screenが開いている場合の処理
func _on_back_button_pressed():
    var call_screens = get_active_call_screens()
    if call_screens.size() > 1:
        print("メニューが" + str(call_screens.size()) + "層重なっています")
        # 最上位のメニューのみ閉じる
        close_ui_call_screen()
    elif call_screens.size() == 1:
        print("メニューを閉じます: " + call_screens[0])
        close_ui_call_screen()
    else:
        print("閉じるメニューがありません")

# すべてのUIの状態を確認
func _on_debug_ui_status():
    var call_screens = get_active_call_screens()
    var all_ui_scenes = get_all_active_ui_scenes()
    
    print("=== UI状態デバッグ ===")
    print("Call Screens: " + str(call_screens.size()) + " 個")
    for i in range(call_screens.size()):
        print("  " + str(i + 1) + ". " + call_screens[i])
    
    print("All UI Scenes: " + str(all_ui_scenes.size()) + " 個")
    for scene_path in all_ui_scenes:
        var is_call = scene_path in call_screens
        var type_str = " [call]" if is_call else " [show]"
        print("  - " + scene_path + type_str)
```

## 🎯 UIコールバック機能（注意点あり）

⚠️ **重要**: UIコールバック機能を使用するには、LayerManagerが適切に初期化されている必要があります。

UICommandには、call_screenで表示されたUIシーンからの結果を受け取るコールバック機能があります。

### 必要な前提条件

UIコールバックが正常に動作するためには、以下の条件が満たされている必要があります：

1. **LayerManagerの初期化**: `LayerManager.initialize_layers(bg_layer, char_layer, ui_layer)`が実行済み
2. **シーン環境**: 適切なゲームシーンでの実行（headlessモードでは制限があります）
3. **UIレイヤー**: ui_layerが正しく設定されている

### 前提条件の確認方法

```gdscript
func check_ui_callback_requirements() -> bool:
    """UIコールバック機能の前提条件を確認"""
    var argode_system = get_node("/root/ArgodeSystem")
    if not argode_system:
        print("❌ ArgodeSystem not found")
        return false
    
    if not argode_system.LayerManager:
        print("❌ LayerManager not found")
        return false
    
    if not argode_system.LayerManager.ui_layer:
        print("❌ UI layer not initialized")
        print("💡 LayerManager.initialize_layers()を実行してください")
        return false
    
    print("✅ UIコールバック機能の前提条件が満たされています")
    return true
```

### call_screenで使用可能なシグナル

call_screenで表示されるUIシーンは、以下のシグナルを定義できます：

```gdscript
# UIシーン側（例：choice_menu.gd）
extends Control
class_name ChoiceMenu

# 結果を返すシグナル
signal screen_result(result: Variant)
# 自分自身を閉じるシグナル  
signal close_screen()

func _ready():
    # ボタンの設定など
    $YesButton.pressed.connect(_on_yes_pressed)
    $NoButton.pressed.connect(_on_no_pressed)
    $CancelButton.pressed.connect(_on_cancel_pressed)

func _on_yes_pressed():
    # 選択結果を返して自動的に閉じる
    screen_result.emit("yes")

func _on_no_pressed():
    # 選択結果を返して自動的に閉じる
    screen_result.emit("no")

func _on_cancel_pressed():
    # 結果なしで閉じる
    close_screen.emit()
```

### UIコールバックを受け取る方法

#### 1. 動的シグナルを使用（推奨）

```gdscript
func setup_ui_callbacks():
    """UIコールバックのセットアップ"""
    var argode_system = get_node("/root/ArgodeSystem")
    var custom_handler = argode_system.get_custom_command_handler()
    
    # UI関連のシグナルに接続
    custom_handler.connect_to_dynamic_signal("ui_call_screen_result", _on_ui_call_screen_result)
    custom_handler.connect_to_dynamic_signal("ui_call_screen_shown", _on_ui_call_screen_shown)
    custom_handler.connect_to_dynamic_signal("ui_call_screen_closed", _on_ui_call_screen_closed)

func _on_ui_call_screen_result(args: Array):
    """call_screenから結果が返ってきた時の処理"""
    var scene_path = args[0] as String
    var result = args[1]
    
    print("UIコールバック結果:", scene_path, "->", result)
    
    # シーンごとの結果処理
    match scene_path:
        "res://ui/choice_menu.tscn":
            _handle_choice_result(result)
        "res://ui/save_dialog.tscn":
            _handle_save_result(result)
        _:
            print("未処理のUI結果:", scene_path, result)

func _on_ui_call_screen_shown(args: Array):
    """call_screenが表示された時の処理"""
    var scene_path = args[0] as String
    var position = args[1] as String
    var transition = args[2] as String
    print("UIが表示されました:", scene_path)

func _on_ui_call_screen_closed(args: Array):
    """call_screenが閉じられた時の処理"""
    var scene_path = args[0] as String
    print("UIが閉じられました:", scene_path)

func _handle_choice_result(result: Variant):
    """選択メニューの結果処理"""
    match result:
        "yes":
            print("プレイヤーは「はい」を選択しました")
            continue_yes_path()
        "no":
            print("プレイヤーは「いいえ」を選択しました")
            continue_no_path()
        _:
            print("不明な選択:", result)
```

#### 2. call_screen_resultsから直接取得

```gdscript
func show_choice_and_get_result() -> Variant:
    """選択メニューを表示して結果を取得"""
    var scene_path = "res://ui/choice_menu.tscn"
    
    # メニューを表示（awaitで終了を待機）
    await call_ui_scene(scene_path)
    
    # 結果を取得
    var argode_system = get_node("/root/ArgodeSystem")
    var custom_handler = argode_system.get_custom_command_handler()
    var ui_command = custom_handler.registered_commands.get("ui")
    
    if ui_command and scene_path in ui_command.call_screen_results:
        var result = ui_command.call_screen_results[scene_path]
        print("取得された結果:", result)
        return result
    else:
        print("結果なし")
        return null

# 使用例
func _on_show_choice_button_pressed():
    var choice_result = await show_choice_and_get_result()
    
    if choice_result == "yes":
        print("はいが選択されました")
    elif choice_result == "no":
        print("いいえが選択されました")
    else:
        print("キャンセルまたは結果なし")
```

### 高度なUIコールバック例

```gdscript
# PlayerChoiceManager.gd - プレイヤー選択管理クラス
extends Node
class_name PlayerChoiceManager

var pending_choices: Dictionary = {}
var choice_callbacks: Dictionary = {}

func _ready():
    setup_ui_callbacks()

func setup_ui_callbacks():
    var argode_system = get_node("/root/ArgodeSystem")
    var custom_handler = argode_system.get_custom_command_handler()
    custom_handler.connect_to_dynamic_signal("ui_call_screen_result", _on_ui_result)

func show_choice_with_callback(scene_path: String, callback: Callable, options: Dictionary = {}):
    """コールバック付きで選択画面を表示"""
    # コールバックを保存
    choice_callbacks[scene_path] = callback
    
    # 選択肢の設定を保存
    pending_choices[scene_path] = options
    
    # UI表示
    await call_ui_scene(scene_path)

func _on_ui_result(args: Array):
    var scene_path = args[0] as String
    var result = args[1]
    
    # 保存されたコールバックを実行
    if scene_path in choice_callbacks:
        var callback = choice_callbacks[scene_path] as Callable
        callback.call(result, pending_choices.get(scene_path, {}))
        
        # クリーンアップ
        choice_callbacks.erase(scene_path)
        pending_choices.erase(scene_path)

# 使用例
func _on_battle_start():
    """戦闘開始時の選択"""
    show_choice_with_callback(
        "res://ui/battle_choice.tscn",
        _on_battle_choice_made,
        {"enemy": "スライム", "player_hp": 100}
    )

func _on_battle_choice_made(choice: String, context: Dictionary):
    """戦闘選択の結果処理"""
    var enemy = context.get("enemy", "unknown")
    match choice:
        "attack":
            print(enemy + "を攻撃します")
            execute_attack()
        "defend":
            print("防御します")
            execute_defend()
        "escape":
            print("逃げます")
            execute_escape()
```

### 利用可能な動的シグナル

UICommandから発行される主要なシグナル：

- `ui_call_screen_shown` - call_screenが表示された時
- `ui_call_screen_closed` - call_screenが閉じられた時
- `ui_call_screen_result` - call_screenから結果が返った時
- `ui_scene_shown` - UIシーンが表示された時（show含む）
- `ui_scene_freed` - UIシーンが解放された時

### UIシーン側のベストプラクティス

```gdscript
# 汎用的なcall_screen基底クラス
extends Control
class_name BaseCallScreen

signal screen_result(result: Variant)
signal close_screen()

var _result_sent: bool = false

func send_result(result: Variant):
    """結果を送信（重複送信防止）"""
    if not _result_sent:
        _result_sent = true
        screen_result.emit(result)

func close_without_result():
    """結果なしで閉じる"""
    if not _result_sent:
        _result_sent = true
        close_screen.emit()

func _on_tree_exiting():
    """シーンが破棄される前に結果未送信の場合は自動で閉じる"""
    if not _result_sent:
        close_without_result()
```

## 🔧 トラブルシューティング

### UIコールバックが動作しない場合

**症状**: `🎯 [ui] Emitted signal: ui_call_screen_closed`がログに出力されるが、コールバック関数が呼ばれない

**原因と解決策**:

1. **LayerManagerが未初期化**
   ```gdscript
   # 解決方法：LayerManagerを手動で初期化
   func setup_layer_manager():
       var argode_system = get_node("/root/ArgodeSystem")
       var layer_manager = argode_system.LayerManager
       
       # UIレイヤーを作成して初期化
       var ui_layer = Control.new()
       ui_layer.name = "UILayer"
       ui_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
       get_tree().current_scene.add_child(ui_layer)
       
       # LayerManagerに設定
       layer_manager.initialize_layers(null, null, ui_layer)
       print("✅ LayerManager initialized manually")
   ```

2. **コールバック関数が正しく接続されていない**
   ```gdscript
   # 確認方法
   func verify_callback_connection():
       var custom_handler = get_node("/root/ArgodeSystem").get_custom_command_handler()
       var connections = custom_handler.signal_connections.get("ui_call_screen_closed", [])
       print("接続されているコールバック数:", connections.size())
       
       if connections.size() == 0:
           print("⚠️ コールバックが接続されていません")
           # 再接続を試行
           custom_handler.connect_to_dynamic_signal("ui_call_screen_closed", _on_ui_closed)
   ```

3. **UIシーンでシグナルが発行されていない**
   ```gdscript
   # UIシーン側で確認
   func _on_close_button_pressed():
       print("🔍 Closing call_screen with signal...")
       if has_signal("close_screen"):
           close_screen.emit()
           print("✅ close_screen signal emitted")
       else:
           print("❌ close_screen signal not found")
   ```

### デバッグ用のログ確認

```gdscript
func enable_ui_callback_debug():
    """UIコールバックのデバッグ情報を有効化"""
    var argode_system = get_node("/root/ArgodeSystem")
    var custom_handler = argode_system.get_custom_command_handler()
    
    # 動的シグナルの汎用デバッグ接続
    if not custom_handler.dynamic_signal_emitted.is_connected(_debug_signal_emission):
        custom_handler.dynamic_signal_emitted.connect(_debug_signal_emission)
        print("✅ Dynamic signal debug enabled")

func _debug_signal_emission(signal_name: String, args: Array, source_command: String):
    """すべての動的シグナル発行をログ出力"""
    print("📡 [DEBUG] Signal:", signal_name)
    print("  Args:", args)
    print("  Source:", source_command)
```

## 🎵 AudioManagerとの組み合わせ

```gdscript
func _on_menu_button_pressed():
    """音声とUI制御の組み合わせ例"""
    var argode_system = get_node("/root/ArgodeSystem")
    
    # SE再生
    argode_system.AudioManager.play_se("menu_open", 0.8)
    
    # メニューをモーダル表示（プレイヤーの選択を待つ）
    await call_ui_scene("res://ui/game_menu.tscn", "center", "fade")
    
    # メニューが閉じられた後に実行
    argode_system.AudioManager.play_se("menu_close", 0.8)
    print("メニュー操作が完了しました")

func _on_notification_needed():
    """非同期通知の例"""
    var argode_system = get_node("/root/ArgodeSystem")
    
    # 通知音
    argode_system.AudioManager.play_se("notification", 0.6)
    
    # 通知パネルを表示（スクリプトは継続）
    show_ui_scene("res://ui/notification_panel.tscn", "top", "slide")
    
    # すぐに次の処理に進む
    continue_game_logic()
```

## 🔧 高度な使用例

### カスタムUIマネージャークラス

```gdscript
# UIManager.gd - プロジェクト専用のUIマネージャー
extends Node
class_name UIManager

var argode_system: Node
var custom_handler: CustomCommandHandler
var audio_manager: Node

func _ready():
    argode_system = get_node("/root/ArgodeSystem")
    custom_handler = argode_system.get_custom_command_handler()
    audio_manager = argode_system.AudioManager

func show_main_menu():
    """メインメニュー表示"""
    audio_manager.play_bgm("menu_theme", true, 0.8)
    await call_ui_scene("res://ui/main_menu.tscn")

func show_pause_menu():
    """ポーズメニュー表示"""
    audio_manager.set_bgm_volume(0.3)  # BGM音量を下げる
    audio_manager.play_se("pause", 0.7)
    await call_ui_scene("res://ui/pause_menu.tscn")

func close_pause_menu():
    """ポーズメニュー終了"""
    close_ui_call_screen()
    audio_manager.set_bgm_volume(1.0)  # BGM音量を戻す
    audio_manager.play_se("resume", 0.7)

func show_inventory():
    """インベントリ表示（非モーダル）"""
    audio_manager.play_se("inventory_open", 0.6)
    show_ui_scene("res://ui/inventory.tscn", "left", "slide")

# 便利メソッド
func call_ui_scene(scene_path: String, position: String = "center", transition: String = "fade"):
    var params = {
        "_raw": "call " + scene_path + " at " + position + " with " + transition,
        "_count": 6,
        "arg0": "call",
        "arg1": scene_path,
        "arg2": "at",
        "arg3": position,
        "arg4": "with",
        "arg5": transition
    }
    var ui_command = custom_handler.registered_commands.get("ui")
    if ui_command:
        await custom_handler._execute_registered_command(ui_command, params)

func show_ui_scene(scene_path: String, position: String = "center", transition: String = "none"):
    var params = {
        "_raw": "show " + scene_path + " at " + position + " with " + transition,
        "_count": 6,
        "arg0": "show",
        "arg1": scene_path,
        "arg2": "at",
        "arg3": position,
        "arg4": "with",
        "arg5": transition
    }
    var ui_command = custom_handler.registered_commands.get("ui")
    if ui_command:
        ui_command.execute(params, argode_system)

func close_ui_call_screen(scene_path: String = ""):
    var params = {}
    if scene_path.is_empty():
        params = {
            "_raw": "close",
            "_count": 1,
            "arg0": "close"
        }
    else:
        params = {
            "_raw": "close " + scene_path,
            "_count": 2,
            "arg0": "close",
            "arg1": scene_path
        }
    var ui_command = custom_handler.registered_commands.get("ui")
    if ui_command:
        ui_command.execute(params, argode_system)
```

## 📚 重要なポイント

### call vs show の使い分け

- **`ui call`**: モーダルダイアログ、選択メニュー、ポーズ画面など、ユーザーの操作を待つ必要がある場合
- **`ui show`**: ステータス表示、インベントリ、ミニマップなど、ゲームプレイと並行して表示したい場合

### パフォーマンス考慮事項

- UI表示時に必要に応じてBGM音量を調整
- 頻繁に表示/非表示するUIは事前にロードしておく
- 不要になったUIシーンは適切に解放する

### エラーハンドリング

```gdscript
func safe_call_ui_scene(scene_path: String, position: String = "center", transition: String = "fade") -> bool:
    """エラーハンドリング付きのUI表示"""
    var argode_system = get_node("/root/ArgodeSystem")
    if not argode_system:
        push_error("ArgodeSystem not found")
        return false
    
    var custom_handler = argode_system.get_custom_command_handler()
    if not custom_handler:
        push_error("CustomCommandHandler not found") 
        return false
    
    # シーンファイルの存在確認
    if not ResourceLoader.exists(scene_path):
        push_error("UI scene not found: " + scene_path)
        return false
    
    call_ui_scene(scene_path, position, transition)
    return true
```

この実装により、GDScript側からもArgodeのカスタムコマンドシステムを完全に活用できるようになります。
