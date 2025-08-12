# ビルトインコマンド

Argodeには、すぐに使える強力なコマンド群が付属しています。これらは、ゲームのロジックを構築し、変数を管理し、インタラクティブなUIを作成するための基本的なツールです。

すべてのビルトインコマンドは自動的に登録され、`.rgd`スクリプトファイルで使用できます。これらは`addons/argode/builtin/commands/`ディレクトリにあります。

## 🕐 タイミング

### `wait`
指定された期間、スクリプトの実行を一時停止します。これは非同期コマンドであり、待機中にゲームがフリーズすることはありません。

**構文**
```rgd
wait <duration>
```

**パラメータ**
- `<duration>` (float): 待機する時間（秒単位）。

**例**
```rgd
narrator "何かが起こりそうだ..."
wait 2.5
narrator "来た！"
```

---

## 🖥️ ユーザーインターフェース

### `ui`
`ui`コマンドは、UIシーン（ルートが`Control`ノードである`.tscn`ファイル）を制御するための多機能ツールです。メニュー、HUD、選択ボタンなどの複雑なUI要素を表示、非表示、管理するために使用できます。

`ui`コマンドは`LayerManager`と連携し、「ui」用に指定されたレイヤーにUI要素を追加します。

#### `ui show`
UIシーンをロードして表示します。

**構文**
```rgd
ui show <scene_path> [at <position>] [with <transition>]
```

**パラメータ**
- `<scene_path>` (string): `.tscn`ファイルへのフルパス（例: `"res://scenes/ui/my_menu.tscn"`）。
- `at <position>` (string, オプション): UIを配置する場所。一般的な値は`center`、`left`、`right`、`top`、`bottom`です。デフォルトは`center`です。
- `with <transition>` (string, オプション): シーンを表示するときに使用するトランジション効果（例: `fade`、`dissolve`）。デフォルトはトランジションなしです。

**例**
```rgd
# 画面上部にHUDをフェードインで表示
ui show "res://ui/hud.tscn" at top with fade
```

#### `ui free`
以前に表示されたUIシーンを削除（解放）します。

**構文**
```rgd
ui free <scene_path>
ui free all
```

**パラメータ**
- `<scene_path>` (string): 削除するシーンのパス。
- `all`: 指定した場合、現在アクティブなすべてのUIシーンが削除されます。

**例**
```rgd
# HUDを削除
ui free "res://ui/hud.tscn"
```

#### `ui call`
UIシーンを **モーダル画面** として表示します。この画面が閉じられるまで（画面自体または`ui close`によって）、スクリプトは一時停止して待機します。これは、メニュー、確認ダイアログ、またはストーリーを進める前にユーザーの操作が必要なUIに最適です。

**構文**
```rgd
ui call <scene_path> [at <position>] [with <transition>]
```

**例**
```rgd
# 選択メニューを表示し、プレイヤーが決定するまで待機
ui call "res://ui/choice_menu.tscn"
# 選択メニューが閉じられた後にのみスクリプトが続行されます。
narrator "あなたは選択をしました。"
```

#### `ui close`
`ui call`で開かれたUIシーンを閉じます。複数の画面が呼び出された場合、最も新しい画面が閉じられます。

**構文**
```rgd
ui close
ui close <scene_path>
```

**パラメータ**
- `<scene_path>` (string, オプション): 閉じる特定のシーン。省略した場合、最後に呼び出された画面が閉じられます。

**例**
```gdscript
# choice_menu.tscnスクリプト内で、ボタンが押されたとき:
func _on_Button_pressed():
    # これによりメニューが閉じられ、rgdスクリプトが再開されます
    emit_signal("close_screen") 
```
```rgd
# または、スクリプト内の別のイベントから
ui close "res://ui/choice_menu.tscn"
```

#### `ui list`
現在アクティブなすべてのUIシーンのリストをコンソールに出力します。これは便利なデバッグツールです。

**構文**
```rgd
ui list
```

---

## 📦 変数管理

これらのコマンドを使用すると、スクリプトから直接、配列や辞書などの複雑なデータ型を作成および変更できます。これらは`VariableManager`と連携します。

### `set_array`
新しい配列で変数を新規作成または上書きします。配列はGodotのような配列リテラル形式を使用して定義されます。

**構文**
```rgd
set_array <variable_name> [value1, value2, "string_value", ...]
```

**パラメータ**
- `<variable_name>` (string): 設定する変数の名前（例: `inventory`、`quest_flags`）。
- 2番目の引数は、配列を表す`[]`で囲まれた文字列リテラルである必要があります。

**例**
```rgd
# プレイヤーのインベントリを初期化
set_array inventory ["剣", "盾", "ポーション"]

# その後、標準の変数構文を使用してアクセスできます
narrator "あなたは{inventory[0]}を持っています。"
```

### `set_dict`
新しい辞書で変数を新規作成または上書きします。辞書はGodotのような辞書リテラル形式を使用して定義されます。

**構文**
```rgd
set_dict <variable_name> {key1: value1, "key2": "string_value", ...}
```

**パラメータ**
- `<variable_name>` (string): 設定する変数の名前（例: `player_stats`、`item_properties`）。
- 2番目の引数は、辞書を表す`{}`で囲まれた文字列リテラルである必要があります。

**例**
```rgd
# キャラクターのステータスを定義
set_dict player_stats {"name": "ユウコ", "level": 5, "hp": 100, "mp": 50}

# ステータスにアクセス
narrator "キャラクター: {player_stats.name}、レベル: {player_stats.level}"
```
