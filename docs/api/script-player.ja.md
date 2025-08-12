# ScriptPlayer APIリファレンス

`ScriptPlayer`は、`.rgd`スクリプトファイルを解釈および実行するコアコンポーネントです。物語の流れを管理し、コマンドを処理し、他のArgodeマネージャーとの相互作用を処理します。`ScriptPlayer`は`ArgodeSystem`の内部コンポーネントですが、その主要な機能は使いやすさのために`ArgodeSystem`の公開APIを通じて公開されています。

## コア機能

### スクリプトのロードと開始

`ScriptPlayer`は`.rgd`ファイルをロードし、指定されたポイントから実行を開始します。

#### `load_script(path: String)`

`.rgd`スクリプトファイルを`ScriptPlayer`にロードします。これにより、スクリプトは実行準備が整いますが、すぐに開始されるわけではありません。

*   **`path` (String)**: `.rgd`スクリプトファイルへの`res://`パス（例：`"res://scenarios/chapter1.rgd"`）。

**例:**

```gdscript
ArgodeSystem.Player.load_script("res://scenarios/my_story.rgd")
```

#### `play_from_label(label_name: String)`

現在ロードされているスクリプト内の特定の`label`からスクリプトの実行を開始または再開します。ラベルが別の`.rgd`ファイルにある場合、`ScriptPlayer`は`LabelRegistry`を使用してクロスファイルジャンプを試行します。

*   **`label_name` (String)**: ジャンプする`label`の名前（例：`"start"`、`"chapter_2_intro"`）。

**例:**

```gdscript
# スクリプトをロードした後
ArgodeSystem.Player.play_from_label("start")

# または、ArgodeSystemの公開APIの一部として
ArgodeSystem.start_script("res://scenarios/my_story.rgd", "start")
```

### スクリプトの進行

#### `next()`

スクリプトを次の行に進めます。このメソッドは通常、ユーザー入力（例：ダイアログを進めるためのマウスクリック）に応答して`ArgodeSystem.next_line()`によって呼び出されます。

**例:**

```gdscript
# 入力ハンドラー内
func _input(event):
    if event.is_action_pressed("ui_accept"):
        ArgodeSystem.next_line() # これは内部的にScriptPlayer.next()を呼び出します
```

### スクリプトの状態

#### `is_playing() -> bool`

`ScriptPlayer`が現在`.rgd`スクリプトを実行中であれば`true`を、そうでなければ`false`を返します。

## フロー制御

`ScriptPlayer`は、`jump`、`call`、`return`、`if`/`else`、`menu`など、`.rgd`スクリプトで定義されたさまざまなフロー制御コマンドを処理します。

### `on_choice_selected(choice_index: int)`

このメソッドは、ユーザーが`menu`コマンドから選択を行ったときに`UIManager`によって呼び出されます。選択されたオプションに基づいて、`ScriptPlayer`をスクリプトの適切なブランチに誘導します。

*   **`choice_index` (int)**: 選択された選択肢の0ベースのインデックス。

**例（内部呼び出し）:**

```gdscript
# UIManagerは選択が行われた後にこれを呼び出します
ArgodeSystem.Player.on_choice_selected(selected_index)
```

### 外部呼び出し/戻り（UI統合用）

これらのメソッドは、一時的にスクリプトフローを制御し、その後戻る必要がある`AdvScreen`ノードまたはその他のカスタムGodotシーンによって主に使用されます。

#### `call_label(label_name: String)`

現在のスクリプト位置をコールスタックにプッシュし、指定された`label`にジャンプします。これは`.rgd`の`call`コマンドに似ていますが、GDScriptからトリガーできます。

*   **`label_name` (String)**: 呼び出す`label`の名前。

**例:**

```gdscript
# AdvScreenスクリプトから
ArgodeSystem.Player.call_label("game_over_scene")
```

#### `return_from_call()`

コールスタックから最後の位置をポップし、その時点からスクリプトの実行を再開します。これは`.rgd`の`return`コマンドに似ています。

**例:**

```gdscript
# AdvScreenスクリプトから、モーダル画面が閉じられた後
ArgodeSystem.Player.return_from_call()
```

## シグナル

`ScriptPlayer`は、その状態の変化やイベントについてシステムの他の部分に通知するためにシグナルを発行します。

### `script_finished`

`ScriptPlayer`が現在ロードされているスクリプトの終わりに達したときに発行されます。

### `custom_command_executed(command_name: String, parameters: Dictionary, line: String)`

`ScriptPlayer`が`.rgd`スクリプト内で組み込みコマンドではないコマンドを検出したときに発行されます。このシグナルは、主に`CustomCommandHandler`によってカスタムGDScriptロジックにディスパッチするために使用されます。

*   **`command_name` (String)**: カスタムコマンドの名前。
*   **`parameters` (Dictionary)**: カスタムコマンドの解析されたパラメータを含む辞書。

*   **`line` (String)**: `.rgd`スクリプトからの元の完全な行。

---

[ArgodeSystem APIについて学ぶ →](argode-system.md){ .md-button }
[マネージャーAPIについて学ぶ →](managers.md){ .md-button }