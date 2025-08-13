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

これらのコマンドを使用すると、変数と配列や辞書などの複雑なデータ型をスクリプトから直接作成および変更できます。これらは`VariableManager`と連携して動作します。

### `set`
変数に値を割り当てます。基本的な変数代入と、自動辞書作成機能付きの辞書キー代入のための**ドット記法**の両方をサポートします。

**基本構文**
```rgd
set <variable_name> = <value>
```

**ドット記法構文**
```rgd
set <dict_name>.<key> = <value>
set <dict_name>.<nested_key>.<sub_key> = <value>
```

**パラメータ**
- `<variable_name>` (string): 設定する変数の名前。
- `<dict_name>.<key>` (string): ドット記法を使用した辞書キーのパス。
- `<value>`: 代入する値（文字列、数値、ブール値を自動検出）。

**例**
```rgd
# 基本的な変数代入
set player_name = "ヒーロー"
set player_level = 1
set game_started = true

# 辞書のドット記法（新機能！）
set player.name = "ヒーロー"
set player.level = 1
set player.stats.hp = 100
set player.stats.mp = 50

# 自動ネスト辞書作成
set character.inventory.weapons.sword = "鋼の剣"
set character.inventory.items.potions = 5

# 値へのアクセス
narrator "ようこそ、{player.name}！あなたのHP: {player.stats.hp}"
narrator "武器: {character.inventory.weapons.sword}"
```

**利点**
- **事前定義不要**: 辞書が自動的に作成される
- **直感的な構文**: 辞書キーを代入する自然な方法
- **後方互換性**: 既存の`set_dict`コマンドと併用可能
- **型検出**: 文字列、数値、ブール値を自動検出

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

---

## ⚙️ ゲーム設定

これらのコマンドは、セッション間で永続化されるゲーム全体の設定を管理します。設定は`user://argode_settings.cfg`に自動保存されます。

### `settings`
ゲーム設定を管理する包括的なコマンドです。

**構文**
```rgd
settings <アクション> [カテゴリ] [キー] [値]
```

**アクション**
- `get <カテゴリ> <キー>` - 設定値を取得して表示
- `set <カテゴリ> <キー> <値>` - 設定値を変更
- `reset` - 全設定をデフォルト値にリセット
- `save` - 現在の設定をファイルに保存
- `load` - ファイルから設定を再読み込み
- `print` - 全ての現在設定を表示

**設定カテゴリ**
- `audio` - 音量とサウンド設定
- `display` - 画面と表示設定
- `text` - テキスト表示と速度設定
- `ui` - ユーザーインターフェース設定
- `accessibility` - アクセシビリティオプション
- `system` - システムと言語設定

**例**
```rgd
# 音声設定の確認と変更
settings get audio master_volume
settings set audio bgm_volume 0.7
settings set audio se_volume 0.9

# テキスト表示の調整
settings set text text_speed 1.5
settings set text auto_play_speed 2.0

# 表示設定
settings set display fullscreen true
settings set display window_size "(1920, 1080)"

# 全設定リセット
settings reset
```

### `volume`
音量調整のための便利コマンドです。

**構文**
```rgd
volume [タイプ] [値]
```

**パラメータ**
- `タイプ` (省略可): 音量タイプ - `master`, `bgm`, `se`, `voice`
- `値` (省略可): 音量レベル (0.0-1.0)

**例**
```rgd
# 全音量レベルを表示
volume

# 特定の音量を確認
volume master
volume bgm

# 音量レベルを設定
volume master 0.8
volume bgm 0.6
volume se 0.9
```

### `textspeed`
テキスト表示速度の便利な調整コマンドです。

**構文**
```rgd
textspeed [速度]
```

**パラメータ**
- `速度` (省略可): テキスト速度倍率 (0.1-5.0)
  - `1.0` = 通常速度
  - `2.0` = 2倍速
  - `0.5` = 半分の速度

**例**
```rgd
# 現在のテキスト速度を確認
textspeed

# テキスト速度を設定
textspeed 1.5    # 1.5倍速
textspeed 0.8    # 0.8倍速