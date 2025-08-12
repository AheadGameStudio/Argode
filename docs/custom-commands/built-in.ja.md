# 組み込みコマンド

Argodeには、すぐに使える強力なコマンド群が標準で付属しています。これらは、ゲームのロジックを構築し、変数を管理し、インタラクティブなUIを作成するための基本的なツールです。

すべての組み込みコマンドは自動的に登録され、`.rgd`スクリプトファイル内で利用可能です。これらのコマンドは`addons/argode/builtin/commands/`ディレクトリにあります。

## 🕐 タイミング

### `wait`
指定された時間、スクリプトの実行を一時停止します。これは非同期コマンドであり、待機中にゲームがフリーズすることはありません。

**構文**
```rgd
wait <duration>
```

**パラメータ**
- `<duration>` (float): 待機する時間（秒）。

**例**
```rgd
narrator "何かが起ころうとしています..."
wait 2.5
narrator "起きました！"
```

---

## 🖥️ ユーザーインターフェース

### `ui`
`ui`コマンドは、ユーザーインターフェースシーン（ルートノードが`Control`である`.tscn`ファイル）を管理するための多機能ツールです。メニュー、HUD、選択肢ボタンなどの複雑なUI要素を表示、非表示、管理するために使用できます。

`ui`コマンドは`LayerManager`と連携して動作し、UI要素を「ui」用に指定されたレイヤーに追加します。

#### `ui show`
UIシーンをロードして表示します。

**構文**
```rgd
ui show <scene_path> [at <position>] [with <transition>]
```

**パラメータ**
- `<scene_path>` (string): `.tscn`ファイルへのフルパス（例: `"res://scenes/ui/my_menu.tscn"`）。
- `at <position>` (string, optional): UIを配置する場所。一般的な値は`center`、`left`、`right`、`top`、`bottom`です。デフォルトは`center`です。
- `with <transition>` (string, optional): シーンを表示する際に使用するトランジション効果（例: `fade`、`dissolve`）。デフォルトはトランジションなしです。

**例**
```rgd
# 画面上部にステータスHUDをフェードインで表示
ui show "res://ui/hud.tscn" at top with fade
```

#### `ui free`
以前に表示したUIシーンを削除（解放）します。

**構文**
```rgd
ui free <scene_path>
ui free all
```

**パラメータ**
- `<scene_path>` (string): 削除するシーンのパス。
- `all`: 指定された場合、現在アクティブなすべてのUIシーンが削除されます。

**例**
```rgd
# HUDを削除
ui free "res://ui/hud.tscn"
```

#### `ui call`
UIシーンを**モーダル画面**として表示します。スクリプトはこの画面が閉じられるまで（画面自体または`ui close`によって）、実行を一時停止します。これは、物語を進行させる前にユーザーの操作を必要とするメニューや確認ダイアログに最適です。

**構文**
```rgd
ui call <scene_path> [at <position>] [with <transition>]
```

**例**
```rgd
# 選択メニューを表示し、プレイヤーの決定を待つ
ui call "res://ui/choice_menu.tscn"
# スクリプトは選択メニューが閉じられた後にのみ続行されます。
narrator "あなたは選択をしました。"
```

#### `ui close`
`ui call`で開かれたUIシーンを閉じます。複数の画面が呼び出された場合、最も新しく呼び出されたものを閉じます。

**構文**
```rgd
ui close
ui close <scene_path>
```

**パラメータ**
- `<scene_path>` (string, optional): 閉じる特定のシーン。省略された場合、最後に呼び出された画面を閉じます。

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

これらのコマンドを使用すると、配列や辞書などの複雑なデータ型をスクリプトから直接作成および変更できます。これらは`VariableManager`と連携して動作します。

### `set_array`
新しい配列で変数を作成または上書きします。配列はGodotライクな配列リテラル形式を使用して定義されます。

**構文**
```rgd
set_array <variable_name> [value1, value2, "string_value", ...]
```

**パラメータ**
- `<variable_name>` (string): 設定する変数の名前（例: `inventory`, `quest_flags`）。
- 2番目の引数は、配列を表す`[]`で囲まれた文字列リテラルでなければなりません。

**例**
```rgd
# プレイヤーのインベントリを初期化
set_array inventory ["sword", "shield", "potion"]

# 標準の変数構文を使用してアクセス可能
narrator "あなたは{inventory[0]}を持っています。"
```

### `set_dict`
新しい辞書で変数を作成または上書きします。辞書はGodotライクな辞書リテラル形式を使用して定義されます。

**構文**
```rgd
set_dict <variable_name> {key1: value1, "key2": "string_value", ...}
```

**パラメータ**
- `<variable_name>` (string): 設定する変数の名前（例: `player_stats`, `item_properties`）。
- 2番目の引数は、辞書を表す`{}`で囲まれた文字列リテラルでなければなりません。

**例**
```rgd
# キャラクターのステータスを定義
set_dict player_stats {"name": "Yuko", "level": 5, "hp": 100, "mp": 50}

# ステータスにアクセス
narrator "キャラクター: {player_stats.name}, レベル: {player_stats.level}"
```