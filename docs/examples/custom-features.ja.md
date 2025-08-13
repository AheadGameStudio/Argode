# 高度な機能の例

この例では、複雑なUIインタラクション、変数操作、条件ロジック、同期および非同期カスタムコマンドの使用など、Argodeのより高度な機能を紹介します。

## 実演される機能

-   **複雑なUIインタラクション:** モーダル画面に`ui call`を使用し、`screen_result`を介して結果を返します。
-   **変数操作:** 構造化データに`set_array`と`set_dict`を、基本的な変数に`set`を使用します。
-   **条件ロジック:** `if`、`elif`、`else`を使用して変数に基づいてストーリーパスを分岐させます。
-   **同期カスタムコマンド:** 完了するまでスクリプトを一時停止するコマンド（例: カスタム画面エフェクト）。
-   **非同期カスタムコマンド:** スクリプトをブロックせずにバックグラウンドで実行されるコマンド（例: サウンドの再生）。
-   **定義の使用:** 事前定義されたキャラクター、画像、オーディオを活用します。

## プロジェクト構造

この例を実行するには、以下が必要です。

-   `ArgodeSystem`がオートロードとして設定されていること。
-   スクリプトを開始するためのメインのGodotシーン（例: `Main.tscn`）。
-   この例のRGDスクリプトファイル（例: `scenarios/advanced_demo.rgd`）。
-   カスタムコマンドの`.gd`ファイル（例: `res://custom/commands/ScreenEffectCommand.gd`、`res://custom/commands/PlaySoundCommand.gd`）。
-   カスタムUIの`.tscn`ファイル（例: `res://ui/choice_dialog.tscn`、`res://ui/inventory_screen.tscn`）。
-   必要なアセット（画像、オーディオ）。

## コード例: `scenarios/advanced_demo.rgd`

```rgd
# --- 定義（別ファイルにすることも可能） ---
character narrator "ナレーター" color=#ffffff
character alice "アリス" color=#ff69b4

image bg laboratory "res://assets/images/backgrounds/laboratory.png"
image char alice_shocked "res://assets/images/characters/alice_shocked.png"

audio sfx alarm "res://assets/audio/sfx/alarm.ogg"

# --- ストーリー開始 ---
label start:
    narrator "高度な機能デモへようこそ！"
    narrator "このデモでは、Argodeの強力な機能の一部を紹介します。"

    scene laboratory with fade
    show alice_shocked at center with dissolve

    # --- 複雑なUIインタラクション（モーダルダイアログ） ---
    narrator "アラームが鳴り響く！どうしますか？"
    play_sound sfx alarm # 非同期コマンド

    # カスタムUIシーンを呼び出し（モーダル）て結果を取得
    ui call "res://ui/choice_dialog.tscn" # このUIが結果を返すと仮定

    # choice_dialog.tscnがscreen_resultまたはclose_screenを発行するまでスクリプトはここで一時停止
    # screen_resultからの結果はUICommandによって内部的に保存されます
    # この例では、選択結果がアクセス可能であるか、カスタムコマンドによって処理されると仮定します

    # --- 仮定されたUI結果に基づく条件ロジック（デモンストレーション用） ---
    # 実際のシナリオでは、UICommandによって返された結果をチェックします
    # ここでは、分岐のための選択結果をシミュレートします
    set player_choice = "investigate"

    if player_choice == "investigate":
        narrator "あなたは勇敢にもアラームの発生源を調査することにしました。"
        jump investigate_alarm
    elif player_choice == "hide":
        narrator "あなたは隠れてやり過ごすことにしました。"
        jump hide_and_wait
    else:
        narrator "あなたはためらい、どうすべきか迷っています。"
        jump hesitate

# --- 分岐: アラームを調査する ---
label investigate_alarm:
    narrator "あなたは慎重に音源に近づきます。"
    # 同期カスタムコマンド（custom/commands/ScreenEffectCommand.gdに実装されていると仮定）
    screen_effect type="flash" color=#FF0000 duration=0.5 # このコマンドはブロックします
    narrator "まばゆい光が噴き出す！"

    # 配列による変数操作
    set_array discovered_items ["奇妙な装置", "光るクリスタル"]
    narrator "あなたは{discovered_items[0]}と{discovered_items[1]}を発見しました！"

    jump end_demo

# --- 分岐: 隠れて待つ ---
label hide_and_wait:
    narrator "あなたは良い隠れ場所を見つけ、アラームが止まるのを待ちます。"
    wait 3.0 # ビルトイン同期コマンド
    narrator "アラームは最終的に止まりました。あなたは慎重に姿を現します。"

    # 辞書による変数操作
    set_dict player_status {"safe": true, "curiosity": "low"}
    narrator "あなたのステータス: 安全 ({player_status.safe})、好奇心: {player_status.curiosity}。"

    jump end_demo

# --- 分岐: ためらう ---
label hesitate:
    narrator "あなたの優柔不断が仇となりました。アラームは鳴り続け、あなたは恐怖を感じます。"
    jump end_demo

# --- デモの終わり ---
label end_demo:
    hide alice_shocked with dissolve
    scene black with fade # 'black'が定義された黒い背景だと仮定
    narrator "これで高度な機能デモは終了です。"
    narrator "コードとドキュメントを探索して、さらに学びましょう！"
    # スクリプトの終わり
```

## カスタムコマンド/UIコードスニペット

### `res://custom/commands/ScreenEffectCommand.gd`（同期の例）

```gdscript
# 同期画面エフェクトコマンドの簡略化された例
extends BaseCustomCommand

func _init():
    command_name = "screen_effect"
    help_text = "screen_effect type=<type> color=<color> duration=<duration>"

func is_synchronous() -> bool:
    return true # このコマンドはスクリプトをブロックします

func execute_internal_async(parameters: Dictionary, adv_system: Node) -> void:
    var type = parameters.get("type", "flash")
    var color = parameters.get("color", Color.WHITE)
    var duration = parameters.get("duration", 0.1)

    # LayerManagerが画面エフェクトを処理するメソッドを持っていると仮定
    if adv_system.LayerManager:
        await adv_system.LayerManager.apply_screen_effect(type, color, duration)
    else:
        print("画面エフェクトにLayerManagerが利用できません。")
    log_command("画面エフェクト '" + type + "' が適用されました。")
```

### `res://ui/choice_dialog.tscn`（モーダルUIの例）

これは、`ui call`で開かれ、`screen_result`を発行するシンプルなUIシーンです。

**`choice_dialog.gd`（`choice_dialog.tscn`のControlノードにアタッチされたスクリプト）:**

```gdscript
extends Control

# ArgodeSystemと通信するためのシグナル
signal screen_result(result: Variant)
signal close_screen()

func _on_investigate_button_pressed():
    emit_signal("screen_result", "investigate")

func _on_hide_button_pressed():
    emit_signal("screen_result", "hide")

func _on_hesitate_button_pressed():
    emit_signal("screen_result", "hesitate")
```

## この例の実行方法

1.  **Argodeがインストールされており**、`ArgodeSystem`がオートロードとして設定されていることを確認します。
2.  `scenarios`フォルダを作成し、`advanced_demo.rgd`スクリプトをそこに保存します。
3.  `custom/commands`フォルダを作成し、`ScreenEffectCommand.gd`をそこに保存します。
4.  `ui`フォルダを作成し、`choice_dialog.tscn`とそのスクリプト`choice_dialog.gd`をそこに保存します。
5.  **アセットを準備:** 指定されたパスに`laboratory.png`と`alice_shocked.png`のプレースホルダー画像、および`alarm.ogg`のオーディオファイルがあることを確認します。
6.  **メインシーン:** シンプルなVNの例と同様に、`Main.tscn`を使用して`advanced_demo.rgd`を開始します。
7.  **実行:** `F5`を押してプロジェクトを実行します。

## 次のステップ

-   `screen_effect`のさまざまなパラメータを試します。
-   `PlaySoundCommand.gd`を非同期コマンドとして実装します。
-   Argode変数と連携するより複雑なUIシーンを作成します。

---

この例は、Argodeで高度にインタラクティブでダイナミックなビジュアルノベルを構築するための基盤を提供します。
