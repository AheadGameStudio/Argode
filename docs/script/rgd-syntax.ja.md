# RGDスクリプト構文リファレンス

RGD（Ren'Py-like Godot）スクリプトは、Argodeでビジュアルノベルのストーリーを記述するためのコア言語です。シンプルで人間が読める、ビジュアルノベルクリエイターにとって直感的な設計になっています。

## 基本構造

RGDスクリプトは、`.rgd`拡張子を持つプレーンテキストファイルです。行ごとに解析され、インデントを使用してコードブロックを定義します。

### コメント

`#`で始まる行はコメントとして扱われ、パーサーによって無視されます。

```rgd
# これは単一行コメントです

label start: # 行末にコメントを追加することもできます
    narrator "こんにちは、世界！"
```

### ラベル

ラベルは、スクリプト内でジャンプできるポイントを定義します。`label`キーワードの後にラベル名とコロン（`:`）を付けて宣言します。

```rgd
label start:
    narrator "これは物語の始まりです。"
    jump chapter_one

label chapter_one:
    narrator "第1章へようこそ！"
```

### インデント

インデント（通常4スペースを使用）は、`label`ブロック、`menu`ブロック、条件文などのコードブロックを定義するためにRGDスクリプトで非常に重要です。

```rgd
label example_block:
    # この行は'example_block'の一部です
    narrator "インデントはコードブロックを定義します。"
    
    menu:
        "オプションA":
            # この行は'オプションA'ブロックの一部です
            narrator "あなたはAを選びました。"
        "オプションB":
            # この行は'オプションB'ブロックの一部です
            narrator "あなたはBを選びました。"
```

## ダイアログ

ダイアログは、ビジュアルノベルスクリプトで最も一般的な要素です。RGDは、キャラクターダイアログとナレーターダイアログの両方をサポートしています。

### キャラクターダイアログ

キャラクターに話させるには、キャラクターの名前（`character`ステートメントで定義されたもの）の後に、引用符で囲まれたダイアログを入力するだけです。

```rgd
character alice "アリス" # まずアリスを定義

alice "こんにちは！"
alice "良い天気ですね？"
```

### ナレーターダイアログ

ナレーションや内なる思考の場合、キャラクター名なしで引用符で囲まれたダイアログを入力するだけです。

```rgd
narrator "太陽はゆっくりと地平線から昇った。"
"新しい一日が始まった。"
```

## コマンド

コマンドは、キャラクターの表示、背景の変更、サウンドの再生、UIの制御など、Argodeにアクションを実行させるための特別な命令です。コマンドは通常1行です。

```rgd
show alice happy at center with fade
scene forest_day with dissolve
play_music "bgm_peaceful.ogg"
ui show "res://ui/main_menu.tscn"
```

利用可能なコマンドとその使用法の完全なリストについては、[コマンドリファレンス](commands.ja.md)を参照してください。

## フロー制御

フロー制御ステートメントを使用すると、物語の流れを指示し、分岐パスを作成し、サブルーチンを管理できます。

### `jump`

`jump`コマンドは、指定されたラベルに無条件に制御を転送します。スクリプトはそのラベルから実行を続行します。

```rgd
label start:
    narrator "物語の始まりです。"
    jump chapter_one

label chapter_one:
    narrator "これは第1章です。"
    # ... スクリプトはここから続行
```

### `call`と`return`

`call`コマンドはサブルーチンを実行するために使用されます。ラベルにジャンプし、そのラベルのブロックが終了するか（または`return`ステートメントに遭遇すると）、制御は`call`の直後の行に戻ります。

```rgd
label start:
    narrator "サブルーチンを呼び出しています。"
    call my_subroutine
    narrator "サブルーチンから戻りました。"

label my_subroutine:
    narrator "サブルーチン内です。"
    # ... いくつかのアクション
    return # オプション、ブロックの終わりで自動的に制御が戻ります
```

### `menu`

`menu`ステートメントは、プレイヤーに選択肢のリストを提示します。スクリプトはプレイヤーが選択するまで一時停止し、その選択肢に関連付けられたコードブロックを実行します。

```rgd
label make_a_choice:
    narrator "どうしますか？"
    menu:
        "左に行く":
            narrator "あなたは左に行きました。"
            jump path_left
        "右に行く":
            narrator "あなたは右に行きました。"
            jump path_right
        "ここに留まる":
            narrator "あなたはここに留まることにしました。"
            jump stay_here
```

## 変数と式

Argodeは、ゲームの状態、プレイヤーの選択、その他の動的なデータを保存するための変数をサポートしています。変数は、中括弧`{}`を使用してダイアログに直接埋め込むことができます。

```rgd
set player_name = "ヒーロー"
narrator "こんにちは、{player_name}！"

if player_level >= 10:
    narrator "あなたは強力な冒険者です。"
```

変数と式の詳細については、[変数と式のリファレンス](variables.ja.md)を参照してください。

## 定義

定義を使用すると、キャラクター、画像、オーディオ、シェーダーを事前に定義でき、スクリプト全体で簡単にアクセスできます。定義は通常、`.rgd`ファイルの先頭または専用の定義ファイル（例: `definitions/characters.rgd`）に配置されます。

```rgd
character alice "アリス" color=#ff69b4
image bg forest_day "res://assets/images/backgrounds/forest_day.png"
audio music peaceful "res://assets/audio/music/peaceful.ogg"
```

定義に関する包括的なガイドについては、[定義リファレンス](definitions.ja.md)を参照してください。
