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
func execute_custom_command_example(custom_handler: CustomCommandHandler):
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
    
    custom_handler.execute_custom_command("ui", ui_params, "")
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
    
    custom_handler.execute_custom_command("ui", params, "")

# 使用例
func _on_choice_button_pressed():
    call_ui_scene("res://ui/player_choice.tscn", "center", "fade")
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
    
    custom_handler.execute_custom_command("ui", params, "")

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
    
    custom_handler.execute_custom_command("ui", params, "")

# 使用例
func _on_cancel_button_pressed():
    close_ui_call_screen()  # 最後のcall_screenを閉じる
    close_ui_call_screen("res://ui/specific_menu.tscn")  # 特定のシーンを閉じる
```

## 🎵 AudioManagerとの組み合わせ

```gdscript
func _on_menu_button_pressed():
    """音声とUI制御の組み合わせ例"""
    var argode_system = get_node("/root/ArgodeSystem")
    
    # SE再生
    argode_system.AudioManager.play_se("menu_open", 0.8)
    
    # メニューをモーダル表示（プレイヤーの選択を待つ）
    call_ui_scene("res://ui/game_menu.tscn", "center", "fade")
    
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
    call_ui_scene("res://ui/main_menu.tscn")

func show_pause_menu():
    """ポーズメニュー表示"""
    audio_manager.set_bgm_volume(0.3)  # BGM音量を下げる
    audio_manager.play_se("pause", 0.7)
    call_ui_scene("res://ui/pause_menu.tscn")

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
    custom_handler.execute_custom_command("ui", params, "")

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
    custom_handler.execute_custom_command("ui", params, "")

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
    custom_handler.execute_custom_command("ui", params, "")
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
