# ArgodeUIScene 使用ガイド

## 概要

`ArgodeUIScene` は、UICommandで表示されるControlシーンがArgodeシステムと連携するための基底クラスです。

## 基本的な使い方

### 1. シーンファイルの作成

1. Godotエディタで新しいシーンを作成
2. ルートノードを `Control` に設定
3. スクリプトを作成し、`ArgodeUIScene` を継承

```gdscript
extends ArgodeUIScene  # または "res://addons/argode/ui/ArgodeUIScene.gd"

func _ready():
    super._ready()  # 必須：親クラスの初期化を呼び出し
    # ここにカスタム初期化処理
```

### 2. ゲームコマンドの実行

```gdscript
# ラベルにジャンプ
execute_argode_command("jump", {"label": "main_menu"})

# 別ファイルのラベルを呼び出し
execute_argode_command("call", {"label": "shop_scene", "file": "res://scenarios/shop.rgd"})

# 変数を設定
execute_argode_command("set", {"name": "player_name", "value": "太郎"})

# 戻る
execute_argode_command("return", {})
```

### 3. メッセージウィンドウとの連携

```gdscript
# メッセージを表示
show_message("ナレーター", "ようこそ、冒険の世界へ！")

# 選択肢を表示
var choices = ["はい", "いいえ", "わからない"]
var result = await show_choices(choices)

# メッセージウィンドウを隠す/表示
hide_message_window()
show_message_window()
```

### 4. 変数の操作

```gdscript
# 変数を取得
var player_level = get_variable("player_level")

# 変数を設定
set_variable("current_scene", "title")

# フラグをチェック
if is_flag_set("tutorial_completed"):
    # チュートリアル完了済みの処理

# フラグを設定
set_flag("first_visit", true)
```

### 5. call_screenとしての使用

```gdscript
# 結果を返して閉じる
func _on_ok_pressed():
    return_result({"status": "ok", "data": input_text})

# 結果なしで閉じる
func _on_cancel_pressed():
    return_result(null)

# 自分自身を閉じる
func _on_close_pressed():
    close_self()
```

## 実装例

### タイトル画面

```gdscript
extends ArgodeUIScene

@export var start_button: Button
@export var exit_button: Button

func _ready():
    super._ready()
    start_button.pressed.connect(_on_start_pressed)
    exit_button.pressed.connect(_on_exit_pressed)

func _on_start_pressed():
    # ゲーム開始
    set_variable("game_started", true)
    show_message_window()
    execute_argode_command("jump", {"label": "prologue_start"})
    close_self()

func _on_exit_pressed():
    # 終了確認
    var choice = await show_choices(["はい", "いいえ"])
    if choice == 0:
        execute_argode_command("jump", {"label": "game_exit"})
        close_self()
```

### セーブ/ロード画面

```gdscript
extends ArgodeUIScene

func _on_save_slot_pressed(slot_number: int):
    # セーブデータを保存
    execute_argode_command("save", {"slot": slot_number})
    show_message("システム", "セーブしました")
    
    # 結果を返して閉じる
    return_result({"action": "saved", "slot": slot_number})

func _on_load_slot_pressed(slot_number: int):
    # セーブデータをロード
    execute_argode_command("load", {"slot": slot_number})
    
    # 結果を返して閉じる
    return_result({"action": "loaded", "slot": slot_number})
```

### 設定画面

```gdscript
extends ArgodeUIScene

@export var bgm_slider: Slider
@export var se_slider: Slider

func _ready():
    super._ready()
    # 現在の設定値を取得
    bgm_slider.value = get_variable("bgm_volume")
    se_slider.value = get_variable("se_volume")

func _on_bgm_slider_changed(value: float):
    set_variable("bgm_volume", value)
    # 実際の音量も更新
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("BGM"), linear_to_db(value))

func _on_apply_pressed():
    # 設定を保存
    show_message("システム", "設定を保存しました")
    return_result({"status": "applied"})
```

## シナリオからの使用方法

```rgd
# 通常の表示
@ui show res://screens/title/Title.tscn center with fade

# モーダルとして呼び出し（結果待ち）
@ui call res://screens/save_load/SaveLoad.tscn center with fade

# 非表示
@ui hide res://screens/title/Title.tscn center with fade

# 削除
@ui free res://screens/title/Title.tscn
```

## 利用可能なシグナル

- `screen_result(result: Variant)`: call_screenの結果を返す
- `close_screen()`: 自分自身を閉じる要求
- `argode_command_requested(command_name: String, parameters: Dictionary)`: カスタムコマンド実行要求

## 自動設定される参照

- `argode_system`: ArgodeSystemへの参照
- `adv_screen`: メッセージウィンドウ（AdvScreen）への参照

これらの参照により、Argodeシステムの全機能にアクセス可能です。
