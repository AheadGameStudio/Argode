# インタラクティブなUIシーンの作成

Argodeでは、カスタムのGodot UIシーン（ルートノードが`Control`ノードである`.tscn`ファイル）を`ui`コマンドを使用してビジュアルノベルのフローに直接統合できます。これらのシーンは、シンプルな表示から、メニュー、インベントリ画面、ミニゲームなどの複雑なインタラクティブ要素まで、多岐にわたります。

## 🎨 UIシーンの構造

UIシーンをArgodeとシームレスに連携させるには、以下のガイドラインに従ってください。

1.  **ルートノード:** シーンのルートノードは **`Control`ノードである必要があります**。
2.  **スクリプト:** ルートの`Control`ノードにスクリプトをアタッチします。
3.  **オプションの`_setup_argode_references`メソッド:** UIシーンのスクリプトにこのメソッドを実装します。`ui`コマンドはこのメソッドを呼び出し、`ArgodeSystem`インスタンスやその他の有用な参照（該当する場合は`adv_screen`など）を注入します。

```gdscript
# UIシーンのスクリプト（例: MyMenu.gd）
extends Control

# これらはUICommandによって自動的に設定されます
var argode_system: Node = null
var adv_screen: Node = null # メインメッセージウィンドウ（AdvScreen）への参照

# このメソッドはUICommandによってArgode参照を注入するために呼び出されます。
# ゲームの状態に基づいてUIを初期化するのに適した場所です。
func _setup_argode_references(system_node: Node, screen_node: Node = null):
    self.argode_system = system_node
    self.adv_screen = screen_node
    print("UIシーン: Argode参照が設定されました！")
    
    # 例: ゲームの状態から変数を取得
    var player_name = argode_system.VariableManager.get_variable("player_name")
    if player_name:
        print("こんにちは、" + player_name)

func _ready():
    # ここにUIの初期化ロジックを記述
    pass
```

## 📡 Argodeとの連携

UIシーンは、特定のシグナルを発行することでArgodeシステムと連携できます。`UICommand`はこれらのシグナルをリッスンし、それに応じて動作します。

### 1. UIからのArgodeコマンド実行

UIがArgodeコマンド（例: 新しいラベルへの`jump`、変数の`set`、キャラクターの`show`）をトリガーする必要がある場合は、`argode_command_requested`シグナルを発行します。

**シグナル:** `argode_command_requested(command_name: String, parameters: Dictionary)`

**例:**
```gdscript
# UIシーンのスクリプト内（例: ボタンの_pressed()関数）
func _on_start_game_button_pressed():
    # Argodeに'prologue'ラベルへジャンプするよう要求
    emit_signal("argode_command_requested", "jump", {"label": "prologue"})
    
    # Argodeに変数を設定するよう要求
    emit_signal("argode_command_requested", "set", {"name": "game_started", "value": true})
```

### 2. `ui call`画面のクローズと結果の返却

`ui call`を使用してモーダルUI（メニューや選択画面など）を表示すると、ArgodeスクリプトはそのUIが閉じるまで待機します。UIシーンは、完了したことを示すために2つのシグナルのいずれかを発行する必要があります。

-   **`close_screen()`**: 特定の結果を返さずにUIシーンを閉じます。Argodeスクリプトは単に再開されます。
-   **`screen_result(result: Variant)`**: UIシーンを閉じ、`Variant`値をArgodeシステムに返します。この結果は`.rgd`スクリプトでアクセスできます（ただし、`.rgd`での直接アクセスはまだ実装されていませんが、内部ロジックには有用です）。

**例:**
```gdscript
# UIシーンのスクリプト内（例: 選択ボタンの_pressed()関数）
func _on_choice_a_button_pressed():
    # UIを閉じ、文字列の結果を返す
    emit_signal("screen_result", "choice_A_made")

func _on_cancel_button_pressed():
    # 特定の結果を返さずにUIを閉じる
    emit_signal("close_screen")
```

## 📚 Argodeシステム機能へのアクセス

`_setup_argode_references`によって注入された`argode_system`参照を介して、UIシーンは様々なArgodeマネージャーや機能にアクセスできます。

```gdscript
# 例: VariableManagerへのアクセス
func _get_player_level():
    if argode_system and argode_system.VariableManager:
        return argode_system.VariableManager.get_variable("player_level")
    return 0

# 例: UIManagerを介したメッセージ表示（UIManagerがそのようなメソッドを公開している場合）
func _show_game_message(text: String):
    if argode_system and argode_system.UIManager:
        # UIManagerにshow_message_windowのようなメソッドがあると仮定
        argode_system.UIManager.show_message_window(text)
```

## 🎬 例: シンプルなタイトル画面

Argodeと連携するタイトル画面の基本的な例を以下に示します。

**シーン設定:**
- ルートノード: `Control`（`TitleScreen`と命名）にスクリプト`TitleScreen.gd`をアタッチ。
- 子ノード: `Button`（`StartButton`と命名）、`Button`（`ExitButton`と命名）。

**`TitleScreen.gd`:**
```gdscript
# res://scenes/ui/TitleScreen.gd
extends Control

var argode_system: Node = null

func _setup_argode_references(system_node: Node, _screen_node: Node = null):
    self.argode_system = system_node
    print("TitleScreen: ArgodeSystem参照が設定されました。")

func _ready():
    $StartButton.pressed.connect(_on_StartButton_pressed)
    $ExitButton.pressed.connect(_on_ExitButton_pressed)

func _on_StartButton_pressed():
    # Argodeに'start_game'ラベルへジャンプするよう要求
    emit_signal("argode_command_requested", "jump", {"label": "start_game"})
    # このタイトル画面を閉じるよう要求
    emit_signal("close_screen")

func _on_ExitButton_pressed():
    # Argodeにゲームを終了するよう要求（'quit'コマンドが存在すると仮定）
    emit_signal("argode_command_requested", "quit", {})
    # このタイトル画面を閉じるよう要求
    emit_signal("close_screen")
```

## 📜 スクリプトでのUIシーンの使用

UIシーンを設定したら、`ui`コマンドを使用して`.rgd`スクリプトでそれを使用できます。

```rgd
# UIシーンを表示（非モーダル）
ui show "res://scenes/ui/TitleScreen.tscn" at center with fade

# UIシーンを呼び出す（モーダル - スクリプトは閉じるまで待機）
ui call "res://scenes/ui/ChoiceMenu.tscn"

# UIシーンを非表示
ui hide "res://scenes/ui/TitleScreen.tscn"

# UIシーンを解放
ui free "res://scenes/ui/TitleScreen.tscn"
```

---

これらのガイドラインに従うことで、Argodeビジュアルノベルとシームレスに統合された、リッチでインタラクティブなユーザーインターフェースを作成できます。
