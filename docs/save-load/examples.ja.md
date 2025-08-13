# セーブ・ロード実例

このページでは、Argodeプロジェクトでセーブ・ロード機能を実装する実践的な例を提供します。

## 基本的なセーブ・ロード実装

### シンプルなセーブポイント

ストーリーの重要な場面でセーブポイントを作成：

```renpy
# .rgdスクリプト内
label chapter_1_start:
    "第1章へようこそ！"
    "ここはセーブに良い場所のようですね。"
    save 0 "第1章開始"
    
    "ストーリーが続きます..."
    
label important_choice:
    "重要な決断が近づいています..."
    save 1 "重要な選択前"
    
    menu:
        "道を選んでください":
        "道A":
            jump path_a
        "道B":
            jump path_b
```

### オートセーブ統合

重要なポイントで自動セーブを実装：

```gdscript
# カスタムコマンドまたはゲームロジック内
extends BaseCustomCommand

func _init():
    command_name = "auto_checkpoint"
    description = "オートセーブチェックポイントを作成"

func execute(params: Dictionary, adv_system: Node) -> bool:
    # 現在の状態をオートセーブ
    var success = adv_system.SaveLoadManager.auto_save()
    
    if success:
        # 簡単なセーブ通知を表示
        adv_system.UIManager.show_notification("ゲームがセーブされました")
    
    return success
```

## セーブメニューの実装

### カスタムセーブ・ロードUI

カスタムセーブ・ロードインターフェースを作成：

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
    # 既存のスロットをクリア
    for child in save_slots.get_children():
        child.queue_free()
    
    # スロット0-8を作成（9はオートセーブ用に予約）
    for i in range(9):
        var slot_button = _create_slot_button(i)
        save_slots.add_child(slot_button)

func _create_slot_button(slot_index: int) -> Button:
    var button = Button.new()
    var save_info = ArgodeSystem.get_save_info(slot_index)
    
    if save_info.is_empty():
        button.text = "スロット %d - 空" % (slot_index + 1)
    else:
        var date_str = save_info.get("save_date", "不明")
        button.text = "スロット %d - %s\n%s" % [
            slot_index + 1,
            save_info.get("save_name", "無名のセーブ"),
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
        var save_name = "セーブ %d" % (selected_slot + 1)
        var success = ArgodeSystem.save_game(selected_slot, save_name)
        if success:
            _refresh_save_slots()

func _on_load_pressed():
    if selected_slot >= 0:
        ArgodeSystem.load_game(selected_slot)
```

### RGDスクリプトとの統合

スクリプトからセーブメニューを使用：

```renpy
# セーブメニューを表示
save_menu

# ロードメニューを表示
load_menu

# 特定スロットにクイックセーブ
save 0 "クイックセーブ"
```

## 高度なセーブ機能

### セーブデータ検証

セーブデータ検証を実装：

```gdscript
# SaveValidator.gd
extends RefCounted
class_name SaveValidator

static func validate_save_data(save_data: Dictionary) -> bool:
    # 必須フィールドをチェック
    var required_fields = ["version", "variables", "save_time"]
    for field in required_fields:
        if not save_data.has(field):
            push_error("セーブデータに必須フィールドがありません: " + field)
            return false
    
    # バージョン互換性を検証
    var save_version = save_data.get("version", "1.0")
    if not _is_version_compatible(save_version):
        push_error("互換性のないセーブバージョン: " + save_version)
        return false
    
    return true

static func _is_version_compatible(version: String) -> bool:
    # バージョン互換性ルールを定義
    var compatible_versions = ["2.0", "2.1"]
    return version in compatible_versions
```

### カスタムセーブデータ拡張

セーブにカスタムデータを追加：

```gdscript
# CustomSaveExtension.gd
extends Node

func _ready():
    # セーブシステムに接続
    ArgodeSystem.SaveLoadManager.connect("game_saved", _on_game_saved)
    ArgodeSystem.SaveLoadManager.connect("game_loaded", _on_game_loaded)

func _on_game_saved(slot: int):
    # メインセーブ完了後に呼び出される
    _save_additional_data(slot)

func _on_game_loaded(slot: int):
    # メインロード完了後に呼び出される
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

## セーブシステムイベント

### 進行状況追跡

長時間の操作でセーブ・ロードの進行状況を追跡：

```gdscript
# SaveProgressTracker.gd
extends Control

@onready var progress_bar = $ProgressBar
@onready var status_label = $StatusLabel

func _ready():
    # セーブシステムシグナルに接続
    var save_manager = ArgodeSystem.SaveLoadManager
    save_manager.save_started.connect(_on_save_started)
    save_manager.save_progress.connect(_on_save_progress)
    save_manager.save_completed.connect(_on_save_completed)

func _on_save_started():
    show()
    progress_bar.value = 0
    status_label.text = "セーブデータを準備中..."

func _on_save_progress(percentage: float, status: String):
    progress_bar.value = percentage
    status_label.text = status

func _on_save_completed(success: bool):
    if success:
        status_label.text = "セーブ完了！"
        await get_tree().create_timer(1.0).timeout
    else:
        status_label.text = "セーブに失敗しました！"
        await get_tree().create_timer(2.0).timeout
    
    hide()
```

### エラー回復

セーブ操作のエラー回復を実装：

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
        print("セーブに失敗、再試行中... 試行 %d/%d" % [retry_count, MAX_RETRY_ATTEMPTS])
        
        # 少し待ってから再試行
        await get_tree().create_timer(1.0).timeout
        ArgodeSystem.save_game(slot, "再試行セーブ")
    else:
        retry_count = 0
        _show_save_error_dialog(error)

func _on_load_failed(slot: int, error: String):
    _show_load_error_dialog(slot, error)

func _show_save_error_dialog(error: String):
    var dialog = AcceptDialog.new()
    dialog.dialog_text = "ゲームのセーブに失敗しました: " + error
    get_tree().current_scene.add_child(dialog)
    dialog.popup_centered()
    dialog.confirmed.connect(dialog.queue_free)

func _show_load_error_dialog(slot: int, error: String):
    var dialog = ConfirmationDialog.new()
    dialog.dialog_text = "セーブスロット %d のロードに失敗しました: %s\n\n別のスロットを試しますか？" % [slot, error]
    get_tree().current_scene.add_child(dialog)
    dialog.popup_centered()
    dialog.confirmed.connect(_show_load_menu)
    dialog.get_cancel_button().pressed.connect(dialog.queue_free)

func _show_load_menu():
    # ユーザーが別のスロットを選択できるようにセーブ・ロードメニューを表示
    pass
```

## パフォーマンス最適化

### 非同期セーブ操作

ノンブロッキングセーブ操作を実装：

```gdscript
# AsyncSaveManager.gd
extends Node

signal save_completed(success: bool)

func save_game_async(slot: int, save_name: String):
    # 非同期セーブ操作を開始
    _perform_async_save.call_deferred(slot, save_name)

func _perform_async_save(slot: int, save_name: String):
    var success = true
    
    # ブロッキングを避けるためチャンク単位でセーブを実行
    for i in range(10):  # チャンク操作をシミュレート
        await get_tree().process_frame
        # 部分的なセーブ操作を実行
        
    # セーブを完了
    var final_success = ArgodeSystem.save_game(slot, save_name)
    save_completed.emit(final_success)
```

### セーブデータ圧縮

圧縮でセーブファイルサイズを削減：

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
        push_error("セーブファイルの作成に失敗: " + file_path)
        return false
    
    file.store_32(compressed_data.size())  # 元のサイズを保存
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

これらの例は、基本機能からエラー回復やパフォーマンス最適化などの高度な機能まで、Argodeフレームワークで堅牢なセーブ・ロードシステムを実装するさまざまな側面を実演しています。
