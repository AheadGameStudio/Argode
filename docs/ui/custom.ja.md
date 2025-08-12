# カスタムUIの作成

ArgodeのAdvScreenはダイアログと選択肢のための堅牢な基盤を提供しますが、独自のゲームメカニクス、インベントリ画面、キャラクターのステータス表示、ミニゲーム、または標準のビジュアルノベル機能を超えるその他のインタラクティブな要素のために、カスタムUI要素を作成する必要があることがよくあります。

Argodeは、Godotのあらゆる`Control`シーンとシームレスに統合するように設計されており、高度にカスタマイズされたインターフェースを構築できます。

## UIシーン構造の要約

[インタラクティブなUIシーンの作成](argode-ui-scene.ja.md)ガイドで説明したように、カスタムUIシーンは次のようになります。

-   ルートに`Control`ノードを持つ。
-   オプションで、`ArgodeSystem`インスタンスと`AdvScreen`参照を注入するために`_setup_argode_references(system_node: Node, screen_node: Node = null)`メソッドを実装する。

## カスタムUIからArgodeとの相互作用

カスタムUIシーンは、主に特定のシグナルを発行することでArgodeシステムと通信できます。

### Argodeコマンドの実行

カスタムUIからArgodeコマンドをトリガーするには（例: ボタンクリックで新しいストーリーセクションにジャンプする、変数を設定する、別のUIを表示する）、`argode_command_requested`シグナルを発行します。

**シグナル:** `argode_command_requested(command_name: String, parameters: Dictionary)`

**例:**

```gdscript
# カスタムUIスクリプト内、例: ボタンの_pressed()関数
func _on_load_game_button_pressed():
    # Argodeに'load'コマンドの実行を要求
    emit_signal("argode_command_requested", "load", {"slot": 1})
    # コマンド要求後、このUIを閉じる
    emit_signal("close_screen")

func _on_show_map_button_pressed():
    # ArgodeにマップUIシーンの表示を要求
    emit_signal("argode_command_requested", "ui", {"_raw": "show res://ui/map_screen.tscn"})
```

### モーダルUIのクローズ（`ui call`）

`ui call`コマンドを使用してUIシーンを開いた場合（モーダルにする場合）、閉じるタイミングをArgodeに通知する必要があります。結果を返すこともできます。

-   **`close_screen()`**: 特定のデータを返さずにUIシーンを閉じます。
-   **`screen_result(result: Variant)`**: UIシーンを閉じ、`Variant`値をArgodeに返します。これは、選択画面やミニゲームが特定の結果を返す必要がある場合に便利です。

**例:**

```gdscript
# 選択メニューUIスクリプト内
func _on_choice_a_button_pressed():
    emit_signal("screen_result", "choice_A_selected")

func _on_cancel_button_pressed():
    emit_signal("close_screen")
```

### Argodeシステムマネージャーへのアクセス

`_setup_argode_references`を実装した場合、`argode_system`インスタンスにアクセスできます。これは、すべてのArgodeマネージャー（例: `VariableManager`、`UIManager`、`CharacterManager`）の中央ハブです。

**例:**

```gdscript
# カスタムUIスクリプト内
func _update_player_hp_display():
    if argode_system and argode_system.VariableManager:
        var current_hp = argode_system.VariableManager.get_variable("player_hp")
        $HPLabel.text = "HP: " + str(current_hp)

func _on_show_character_info_button_pressed():
    if argode_system and argode_system.CharacterManager:
        var character_data = argode_system.CharacterManager.get_character_data("alice")
        print("アリスのデータ: ", character_data)
```

## カスタムUIとRGDスクリプトの統合

カスタムUIシーンを作成したら、`ui`コマンドを使用して`.rgd`スクリプトから直接表示および管理できます。

```rgd
# 非モーダルなインベントリ画面を表示
ui show "res://ui/inventory_screen.tscn" at center

# モーダルなミニゲームを呼び出し、結果を待つ
ui call "res://ui/puzzle_game.tscn"

# カスタムUIを非表示
ui hide "res://ui/inventory_screen.tscn"

# カスタムUIを解放（メモリから削除）
ui free "res://ui/inventory_screen.tscn"
```

## 例のシナリオ

### インベントリ画面

インベントリ画面は、Argodeの配列変数（`set_array inventory [...]`）に保存されたアイテムを表示できます。各アイテムのボタンは、`use_item`または`equip_item`カスタムコマンドをトリガーするために`argode_command_requested`を発行できます。

### キャラクター状態画面

Argodeの辞書変数（`set_dict player_stats {...}`）に保存されたキャラクターのステータス（HP、MP、レベル）を表示します。UIは`argode_system.VariableManager.get_variable()`を介してこれらの変数を読み取ります。

### ミニゲームの統合

カスタムUIシーンはシンプルなミニゲームをホストできます。ミニゲームが終了すると、成功の場合は`screen_result(true)`、失敗の場合は`screen_result(false)`を発行し、`ui call`コマンドの後に`.rgd`スクリプトがそれに応じて分岐できるようにします。

---

Godotの強力なUIツールとArgodeのスクリプト機能を組み合わせることで、ビジュアルノベルに真にユニークでインタラクティブな体験を作成できます。
