# シンプルなビジュアルノベルの例

この例は、基本的なビジュアルノベルストーリーを提示することで、Argodeのコア機能を示します。キャラクター定義、ダイアログ、背景変更、キャラクター表示、選択肢メニュー、および基本的なフロー制御をカバーしています。

## 実演される機能

-   **キャラクター定義:** 名前と色を持つキャラクターの定義。
-   **ダイアログシステム:** キャラクターダイアログとナレーターテキストの表示。
-   **背景管理:** トランジションを伴うシーンの変更。
-   **キャラクター表示:** 表情と位置を持つキャラクターの表示と非表示。
-   **選択肢メニュー:** 分岐パスにつながるプレイヤーの選択肢の提示。
-   **フロー制御:** `jump`を使用してストーリーセクション間を移動。

## プロジェクト構造

この例を実行するには、通常、以下が必要です。

-   `ArgodeSystem`がオートロードとして設定されていること。
-   Argodeを初期化し、スクリプトを開始するメインのGodotシーン（例: `Main.tscn`）。
-   この例のRGDスクリプトファイル（例: `scenarios/simple_vn.rgd`）。
-   必要なアセット（背景とキャラクターの画像）。

## コード例: `scenarios/simple_vn.rgd`

```rgd
# --- 定義（別の定義ファイルにすることも可能） ---
character narrator "ナレーター" color=#ffffff
character alice "アリス" color=#ff69b4
character bob "ボブ" color=#87ceeb

image bg forest_day "res://assets/images/backgrounds/forest_day.png"
image bg forest_night "res://assets/images/backgrounds/forest_night.png"

# これらのパスにキャラクターのスプライトが存在すると仮定
image char alice_normal "res://assets/images/characters/alice_normal.png"
image char alice_happy "res://assets/images/characters/alice_happy.png"
image char bob_normal "res://assets/images/characters/bob_normal.png"

# --- ストーリー開始 ---
label start:
    narrator "シンプルなビジュアルノベルの例へようこそ！"
    narrator "このストーリーはArgodeの基本的な機能を示します。"

    # 背景シーンを変更
    scene forest_day with fade

    # キャラクターを表示
    show alice_normal at center with dissolve
    alice "こんにちは！私はアリスです。"
    alice "森は美しい日ですね？"

    # 選択肢メニューを提示
    menu:
        "森を探検する":
            jump explore_forest
        "アリスともっと話す":
            jump talk_to_alice
        "ストーリーを終了する":
            jump end_story

# --- 分岐: 森を探検する ---
label explore_forest:
    narrator "あなたは森を探検することにしました。"
    hide alice_normal with fade
    scene forest_night with dissolve
    narrator "夜が更け、あなたは新しい誰かに遭遇します..."

    show bob_normal at left with fade
    bob "旅人よ、ごきげんよう。道に迷いましたか？"

    menu:
        "助けを求める":
            jump ask_for_help
        "逃げる":
            jump run_away

# --- 分岐: アリスと話す ---
label talk_to_alice:
    alice "何について話したいですか？"
    menu:
        "世界について尋ねる":
            alice "この世界は驚きに満ちています！"
            jump continue_alice_talk
        "彼女の一日について尋ねる":
            alice "私の今日は素敵でした、ありがとう！"
            jump continue_alice_talk

label continue_alice_talk:
    alice "他に何かありますか？"
    menu:
        "ボブについて尋ねる":
            alice "ボブ？ああ、彼は良い友達です。後で会うかもしれませんね。"
            jump end_story # 簡単にするため、終了にジャンプ
        "さようならを言う":
            jump end_story

# --- Explore Forestからのサブ分岐 ---
label ask_for_help:
    bob "もちろんです。私についてきてください、安全な道を知っています。"
    narrator "あなたはボブについて行き、安堵感を覚えました。"
    jump end_story

label run_away:
    narrator "あなたは振り返って走り去り、ボブを置き去りにしました。"
    hide bob_normal with fade
    narrator "最終的に道を見つけましたが、何を見逃したのか疑問に思いました。"
    jump end_story

# --- ストーリーの終わり ---
label end_story:
    hide alice_normal with dissolve
    hide bob_normal with dissolve
    scene black with fade # 'black'が定義された黒い背景だと仮定
    narrator "シンプルなビジュアルノベルの例をプレイしていただきありがとうございます！"
    narrator "このスクリプトを自由に修正し、Argodeの機能を探索してください。"
    # スクリプトの終わり
```

## この例の実行方法

1.  **Argodeがインストールされており**、`ArgodeSystem`がGodotプロジェクトでオートロードとして設定されていることを確認します。
2.  プロジェクトルートに`scenarios`フォルダがない場合は**作成します**。
3.  上記のRGDスクリプトをプロジェクトの`scenarios/simple_vn.rgd`として**保存します**。
4.  **アセットを準備:** `res://assets/images/backgrounds/forest_day.png`、`forest_night.png`、`res://assets/images/characters/alice_normal.png`、`alice_happy.png`、`bob_normal.png`、および黒い背景画像（例: `res://assets/images/backgrounds/black.png`）のプレースホルダー画像ファイルを作成します。これらはテスト用のシンプルな色付きの四角形でも構いません。
5.  **メインシーンを作成:** ルートに`Control`ノードを持つ新しいGodotシーン（例: `Main.tscn`）を作成します。この`Control`ノードにスクリプトをアタッチします。

    ```gdscript
    # Main.gd
    extends Control

    func _ready():
        if ArgodeSystem:
            # シンプルなビジュアルノベルスクリプトを開始
            ArgodeSystem.start_script("res://scenarios/simple_vn.rgd", "start")
        else:
            print("ArgodeSystemが見つかりません！オートロードに設定されているか確認してください。")
    ```
6.  **メインシーンを設定:** `プロジェクト → プロジェクト設定 → アプリケーション → 実行`で、`Main.tscn`を**メインシーン**として設定します。
7.  **実行:** `F5`を押してプロジェクトを実行し、シンプルなビジュアルノベルを体験してください。

## 次のステップ

-   `simple_vn.rgd`スクリプトを変更して、ダイアログを変更したり、選択肢を追加したり、新しいキャラクターを導入したりします。
-   ドキュメントに記載されている他のArgodeコマンドや機能を探索します。
-   独自の[カスタムコマンド](../custom-commands/creating.ja.md)を作成して、ユニークなエフェクトを作成する方法を学びます。

---

この例は、Argodeでより複雑で魅力的なビジュアルノベルを構築するための強固な基盤を提供します。
