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
