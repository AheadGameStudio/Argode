# Ren'Py風ADVアドオン 設計書

Saitosさんと共に設計した、Godot Engineで動作するRen'Py風アドベンチャーゲームアドオン「Ren' Gd」の基本設計書です。

---

## 1. 📜 設計思想 (Design Philosophy)

本アドオンは、Ren'Pyの持つ「スクリプトの書きやすさ」と、Godotの持つ「柔軟なノードシステムと拡張性」の融合を目指します。

* **シナリオ記述:** 外部のテキストエディタで編集可能な、独自のスクリプトファイル (`.rgd`) を使用します。これにより、ライターはGodotエディタを深く知らなくてもシナリオ執筆に集中できます。

* **疎結合アーキテクチャ:** スクリプトの解析・実行を行うエンジン部 (`AdvScriptPlayer`) と、実際の描画処理（キャラクター表示、UI表示など）を行うマネージャー群を分離します。これにより、利用者はアドオンの内部を改造することなく、自身のゲームデザインに合わせて描画部分を自由に実装できます。

* **リソース指向:** キャラクター定義など、繰り返し利用するデータはGodotのカスタムリソース (`.tres`) として管理します。これにより、デザイナーはエディタ上で直感的にデータを編集でき、ライターとの分業が容易になります。

* **柔軟な式評価:** 変数操作や条件分岐には、Godot標準の`Expression`クラスを活用します。これにより、実装コストを抑えつつ、Ren'Pyのような柔軟な式記述を実現します。

## 2. 📝 シナリオスクリプト仕様 (`.rgd`)

シナリオは独自の拡張子`.rgd`を持つテキストファイルとして記述します。以下に、これまで議論した全ての機能を含んだサンプルを示します。

```
# sample.rgd

# ---------------------------
# キャラクター定義
# ---------------------------
# define <ID> = Character("<リソースパス>")
define y = Character("res://characters/yuko.tres")
define s = Character("res://characters/saitos.tres")


# ---------------------------
# メインシナリオ
# ---------------------------
label start:
    # 変数定義
    set score = 0
    set player_name = "Saitos"

    # シーン表示とトランジション
    scene classroom with fade

    # キャラクター表示とトランジション
    show y normal at center with dissolve

    y "こんにちは、{player_name}さん！" # セリフ内での変数展開
    s "やあ、優子さん。今日のスコアは {score} 点からスタートだ。"

    # 選択肢
    say "どうしますか？"
    menu:
        "話しかける":
            jump talk_to_yuko
        "スコアを稼ぐ":
            call earn_score
            s "よし、スコアが {score} 点になったぞ。"
            jump check_score
        "何もしない":
            pass # 何もせず次に進む

    jump check_score


label talk_to_yuko:
    y "何か御用ですか？"
    s "いや、別に……。"
    jump check_score


label check_score:
    # 条件分岐
    if score >= 50:
        s "スコアが50点を超えた！"
        jump ending_high_score
    else:
        s "まだスコアは足りないな……。"
        jump ending_normal


# ---------------------------
# サブルーチン
# ---------------------------
label earn_score:
    s "(何かをしてスコアを稼いだ)"
    set score = score + 50
    return # callされた場所に戻る


# ---------------------------
# エンディング
# ---------------------------
label ending_normal:
    say "平凡な一日が終わった。"
    # end # ゲーム終了コマンド（実装例）

label ending_high_score:
    say "素晴らしい成果を上げた！"
    # end

```

## 3. 🛠️ アーキテクチャとGDScriptサンプル

### 📁 プロジェクト構成（例）

```
res://
├─ addons/
│  └─ adv_engine/
│     ├─ AdvScriptPlayer.gd
│     ├─ CharacterData.gd
│     ├─ managers/
│     │  ├─ CharacterManager.gd
│     │  ├─ UIManager.gd
│     │  ├─ TransitionPlayer.gd
│     │  └─ VariableManager.gd
│     └─ plugin.cfg
├─ characters/
│  ├─ yuko.tres
│  └─ saitos.tres
├─ scenarios/
│  └─ sample.rgd
├─ images/
│  ├─ classroom.png
│  └─ yuko_normal.png
└─ MainScene.tscn

```

### ⚙️ 実行エンジン (`AdvScriptPlayer.gd`)

スクリプトの解析とフロー制御の心臓部。シングルトン（オートロード）として登録することを推奨。

```
# AdvScriptPlayer.gd
extends Node

# --- Signals ---
signal script_finished

# --- State ---
var script_lines: PackedStringArray = []
var label_map: Dictionary = {}
var call_stack: Array[Dictionary] = []
var current_line_index: int = -1
var is_playing: bool = false
var is_waiting_for_choice: bool = false

# --- Regex Definitions (一部) ---
const REGEX_LABEL = RegEx.new("^label\\s+(?<name>\\w+):")
const REGEX_SAY = RegEx.new("^(?:(?<char_id>\\w+)\\s+)?(?<message>\\".*\\")")
const REGEX_SET = RegEx.new("^set\\s+(?<var_name>\\w+)\\s*=\\s*(?<expression>.+)")
# ... 他の正規表現も同様に定義 ...

func load_script(path: String):
    # スクリプトを読み込み、プリパスでラベルを解析
    var file = FileAccess.open(path, FileAccess.READ)
    if not file:
        push_error("🚫 Script file not found: " + path)
        return
    
    script_lines = file.get_as_text().split("\n")
    _preparse_labels()
    current_line_index = -1
    print("📖 Script loaded: ", path)

func play_from_label(label_name: String):
    if label_map.has(label_name):
        current_line_index = label_map[label_name]
        is_playing = true
        _tick()
    else:
        push_error("🚫 Label not found: " + label_name)

func next():
    # ユーザー入力（クリックなど）で呼ばれる
    if is_playing and not is_waiting_for_choice:
        _tick()

func _tick():
    # 実行ポインタを1つ進めて、行を処理する
    current_line_index += 1
    if current_line_index >= script_lines.size():
        is_playing = false
        script_finished.emit()
        print("📜 Script finished.")
        return

    var line = script_lines[current_line_index].strip_edges()

    # 空行やコメントなどはスキップして次のtickへ
    if line.is_empty() or line.begins_with("#"):
        _tick()
        return

    # 1行を解析・実行
    var stop_execution = _parse_and_execute(line)

    # sayやmenuなど、ユーザーの入力を待つコマンドでなければ、次の行へ
    if not stop_execution:
        _tick()

func _parse_and_execute(line: String) -> bool:
    # 正規表現でコマンドを判定し、各Managerに処理を委任する
    # 返り値: trueなら実行を中断（クリック待ち）、falseなら継続
    var match: RegExMatch

    # say
    match = REGEX_SAY.search(line)
    if match:
        var char_id = match.get_string("char_id")
        var message = match.get_string("message")
        # ToDo: Call UIManager.show_message(char_id, message)
        return true # セリフ表示後はクリック待ち

    # set
    match = REGEX_SET.search(line)
    if match:
        # ToDo: Call VariableManager.set_variable(...)
        return false # 変数代入は即時実行

    # ... 他のコマンド処理 ...
    
    return false


func _preparse_labels():
    label_map.clear()
    for i in range(script_lines.size()):
        var match = REGEX_LABEL.search(script_lines[i].strip_edges())
        if match:
            label_map[match.get_string("name")] = i

```

### 👤 キャラクター管理

#### `CharacterData.gd`

キャラクター情報を保持するカスタムリソース。

```
# CharacterData.gd
@tool
extends Resource

@export var display_name: String = ""
@export var name_color: Color = Color.WHITE

```

#### `CharacterManager.gd`

`show`コマンドに応じてキャラクターのスプライトなどを管理する。シングルトン。

```
# CharacterManager.gd
extends Node

@export var character_container: Node2D # シーン内のキャラクター置き場

func show_character(char_id: String, expression: String, position: String, transition: String):
    print(f"🧍‍♀️ Showing: {char_id} ({expression}) at {position} with {transition}")
    # ToDo:
    # 1. VariableManagerからchar_idに対応するリソースパスを取得
    # 2. リソースをloadし、キャラクター画像パスを決定
    # 3. character_container内にSprite2Dなどを生成/更新
    # 4. 必要ならTransitionPlayerにトランジションを要求

```

### 🎨 UI管理 (`UIManager.gd`)

テキストボックスや選択肢の表示・管理を行う。シングルトン。

```
# UIManager.gd
extends CanvasLayer

# --- Scene References ---
@export var name_label: Label
@export var text_label: Label
@export var choice_container: VBoxContainer

func show_message(char_data: CharacterData, message: String):
    if char_data:
        name_label.text = char_data.display_name
        name_label.modulate = char_data.name_color
    else:
        name_label.text = "" # ナレーション

    text_label.text = message
    print(f"💬 Displaying: [{name_label.text}] {message}")

func show_choices(choices: Array[String]):
    print("🤔 Showing choices: ", choices)
    # ToDo:
    # 1. choice_container内にButtonを生成
    # 2. 各Buttonのpressedシグナルを接続
    # 3. プレイヤーが選択したら、AdvScriptPlayer.on_choice_selected(index)を呼ぶ

```

### 🎬 演出管理 (`TransitionPlayer.gd`)

`with`句で指定されたトランジションを実行する。シングルトン。

```
# TransitionPlayer.gd
extends CanvasLayer

signal transition_finished

@onready var color_rect: ColorRect = $ColorRect # シェーダーを適用するRect

func play(type: String, duration: float = 1.0):
    print(f"🎬 Playing transition: {type} over {duration}s")
    # ToDo:
    # 1. type名に応じてシェーダーをセット
    # 2. Tweenでシェーダーのprogressユニフォームを0->1へアニメーション
    # 3. Tween完了後にtransition_finishedシグナルを発行
    var tween = create_tween()
    # ... tween logic ...
    await tween.finished
    transition_finished.emit()

```

### 🧮 変数管理 (`VariableManager.gd`)

スクリプト内の変数を保持し、`Expression`による式評価を行う。シングルトン。

```
# VariableManager.gd
extends Node

var global_vars: Dictionary = {}
var character_defs: Dictionary = {} # {"y": "res://.../yuko.tres"}

func set_character_def(id: String, resource_path: String):
    character_defs[id] = resource_path

func set_variable(var_name: String, expression_str: String):
    var expression = Expression.new()
    var error = expression.parse(expression_str, _get_available_variable_names())
    if error != OK:
        push_error("🚫 Expression parse error: " + expression.get_error_text())
        return

    var result = expression.execute(global_vars)
    if not expression.has_execute_failed():
        global_vars[var_name] = result
        print(f"📊 Var set: {var_name} = {result}")
    else:
        push_error("🚫 Expression execute error.")

func evaluate_condition(expression_str: String) -> bool:
    # set_variableとほぼ同様の実装で、bool値を返す
    return false

func _get_available_variable_names() -> PackedStringArray:
    return PackedStringArray(global_vars.keys())

```

## 4. 🚀 導入と利用方法

1. **オートロード設定:**
   Godotの「プロジェクト設定」→「オートロード」タブで、以下のスクリプトをシングルトンとして登録します。

   * `AdvScriptPlayer`

   * `CharacterManager`

   * `UIManager`

   * `TransitionPlayer`

   * `VariableManager`

2. **シーン構築:**
   メインシーンに、各Managerが必要とするノード（`Label`, `VBoxContainer`, `Node2D`など）を配置し、インスペクターから参照をセットします。

3. **スクリプト実行:**
   ゲーム開始時に、メインシーンのスクリプトから以下のようにしてシナリオを開始します。

   ```
   # MainScene.gd
   func _ready():
       AdvScriptPlayer.load_script("res://scenarios/sample.rgd")
       AdvScriptPlayer.play_from_label("start")
   
   func _unhandled_input(event):
       if event.is_action_pressed("ui_accept"): # クリックや決定ボタン
           AdvScriptPlayer.next()
   
   `