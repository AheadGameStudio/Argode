# ArgodeSystem APIリファレンス

`ArgodeSystem`はArgodeフレームワークの中心的なシングルトンであり、コア機能を提供し、他のすべてのマネージャーのオーケストレーターとして機能します。これは、ArgodeをGodotプロジェクトに統合するための主要なエントリポイントです。

## ArgodeSystemへのアクセス

`ArgodeSystem`はオートロードされたシングルトンであるため、Godotプロジェクト内の任意のスクリプトからグローバルにアクセスできます。

```gdscript
# ArgodeSystemへのアクセス
var argode_system = get_node("/root/ArgodeSystem") # オートロードの名前を"ArgodeSystem"にした場合
# または、プロジェクト設定でグローバルシングルトンとして設定した場合
# var argode_system = ArgodeSystem
```

## 初期化

Argodeの機能を使用する前に、システムを初期化する必要があります。これは通常、ゲームの開始時、通常はメインシーンのスクリプトから一度だけ行われます。

### `initialize_game(layer_map: Dictionary) -> bool`

この関数は、Argodeフレームワークの包括的な初期化を実行します。視覚レイヤーを設定し、アセット定義を構築し、内部マネージャーを構成します。

*   **`layer_map` (Dictionary)**: レイヤーロール名（例：`"background"`、`"character"`、`"ui"`、`"effects"`）とそれに対応するGodotの`CanvasLayer`ノードをマッピングする辞書です。これにより、Argodeをカスタムシーン構造と統合できます。

**例:**

```gdscript
# メインシーンの_ready()関数内
func _ready():
    var layer_map = {
        "background": $CanvasLayer_Background,
        "character": $CanvasLayer_Characters,
        "ui": $CanvasLayer_UI,
        "effects": $CanvasLayer_Effects
    }
    if ArgodeSystem.initialize_game(layer_map):
        print("ArgodeSystemが正常に初期化されました！")
    else:
        print("ArgodeSystemの初期化に失敗しました。")
```

## スクリプト実行

`ArgodeSystem`は、`.rgd`スクリプトの実行を制御するためのメソッドを提供します。

### `start_script(script_path: String, label_name: String = "start")`

指定されたラベルから`.rgd`スクリプトファイルをロードし、実行を開始します。

*   **`script_path` (String)**: `.rgd`スクリプトファイルへの`res://`パス（例：`"res://scenarios/chapter1.rgd"`）。
*   **`label_name` (String)**: （オプション）実行を開始するスクリプト内のラベル名。デフォルトは`"start"`です。

**例:**

```gdscript
ArgodeSystem.start_script("res://scenarios/main_story.rgd", "prologue")
```

### `next_line()`

スクリプトを次の行に進めます。これは通常、ダイアログや物語を進めるためのユーザー入力（例：マウスクリックやキープレス）に応答して呼び出されます。

**例:**

```gdscript
func _input(event):
    if event.is_action_pressed("ui_accept"):
        ArgodeSystem.next_line()
```

### `is_playing() -> bool`

`.rgd`スクリプトが現在再生中であれば`true`を、そうでなければ`false`を返します。

## カスタムコマンド管理

`ArgodeSystem`は`CustomCommandHandler`と対話するためのAPIを提供し、カスタムGDScriptコマンドを登録および管理できます。

### `get_custom_command_handler() -> CustomCommandHandler`

`CustomCommandHandler`インスタンスを返し、高度な使用のためにそのメソッドに直接アクセスできます。

### `register_custom_command(custom_command: BaseCustomCommand) -> bool`

`BaseCustomCommand`のインスタンス（カスタムGDScriptコマンド）をフレームワークに登録します。

*   **`custom_command` (BaseCustomCommand)**: `BaseCustomCommand`を継承するカスタムコマンドスクリプトのインスタンス。

### `register_command_by_callable(command_name: String, callable: Callable, is_sync: bool = false) -> bool`

コマンド名を`Callable`（関数またはメソッド）に関連付けることで、カスタムコマンドを登録します。これは、GDScript関数を`.rgd`コマンドとして素早く公開する便利な方法です。

*   **`command_name` (String)**: `.rgd`スクリプトに表示されるコマンドの名前（例：`"my_effect"`）。
*   **`callable` (Callable)**: コマンドが検出されたときに実行される`Callable`（例：`my_node.my_function`）。
*   **`is_sync` (bool)**: （オプション）`true`の場合、スクリプトは`Callable`が完了するまで待機してから続行します。デフォルトは`false`（非同期）です。

### `list_custom_commands() -> Array[String]`

現在登録されているすべてのカスタムコマンドの名前を含む文字列の配列を返します。デバッグや動的なコマンドリスト表示に役立ちます。

## シグナル

`ArgodeSystem`は、カスタムロジックや監視のために接続できるいくつかのシグナルを発行します。

### `system_initialized`

`initialize_game()`関数がすべての初期化ステップを正常に完了したときに発行されます。

### `system_error(message: String)`

ArgodeSystemの初期化または操作中に致命的なエラーが発生したときに発行されます。`message`パラメータはエラーの詳細を提供します。

### `definition_loaded(results: Dictionary)`

すべての定義ファイル（例：`characters.rgd`、`assets.rgd`）がロードおよび処理された後に発行されます。`results`辞書には、ロードされた定義に関する情報が含まれています。

---

[ScriptPlayer APIについて学ぶ →](script-player.md){ .md-button }
[マネージャーAPIについて学ぶ →](managers.md){ .md-button }