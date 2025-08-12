# カスタムコマンドの作成

このガイドでは、Argode用の独自のカスタムコマンドを作成するプロセスを説明します。カスタムコマンドを使用すると、Argodeの機能を拡張し、Godotプロジェクト独自のロジックや機能とシームレスに統合できます。

## `BaseCustomCommand`クラス

Argodeのすべてのカスタムコマンドは、`BaseCustomCommand`を継承するクラスです。この基底クラスは、Argodeがコマンドを認識して実行するために必要な構造とメソッドを提供します。

### 主要なプロパティとメソッド

-   `command_name` (string): **必須。** `.rgd`スクリプトで使用されるコマンドの名前。これは一意である必要があります。
-   `description` (string): コマンドが何をするかを説明する短いテキスト。ドキュメントや将来のツールに役立ちます。
-   `help_text` (string): コマンドの構文、パラメータ、使用法に関するより詳細な説明。
-   `execute(parameters: Dictionary, adv_system: Node)`: **非同期コマンドに必須。** `.rgd`スクリプトでコマンドが実行されたときに呼び出されるメソッド。スクリプトの実行をブロックする必要がないロジック（例: サウンドの再生、モーダルではないUIの表示）に使用します。
    -   `parameters`: `.rgd`スクリプトからコマンドに渡されたすべての引数を含む辞書。
    -   `adv_system`: グローバルな`ArgodeSystem`インスタンスへの参照。これにより、すべてのArgodeマネージャーと機能にアクセスできます。
-   `is_synchronous() -> bool`: コマンドが完了するまで`.rgd`スクリプトの実行をブロックする必要がある場合に、このメソッドをオーバーライドして`true`を返します。
-   `execute_internal_async(parameters: Dictionary, adv_system: Node)`: **同期コマンドに必須。** `is_synchronous()`が`true`を返す場合、Argodeはこのメソッドを`execute()`の代わりに呼び出します。スクリプトが再開する前に完了する必要がある非同期操作には、このメソッド内で`await`キーワードを使用します。

## ステップバイステップ: シンプルなコマンドの作成

Godotの出力コンソールにカスタムメッセージを出力するシンプルな`log_message`コマンドを作成してみましょう。

### ステップ1: コマンドファイルの作成

`res://custom/commands/`ディレクトリ内に、`LogMessageCommand.gd`のような説明的な名前の新しい`.gd`ファイルを作成します。

### ステップ2: コマンドコードの記述

`LogMessageCommand.gd`を開き、以下のコードを追加します。

```gdscript
# res://custom/commands/LogMessageCommand.gd
@tool
class_name LogMessageCommand # 一意のclass_nameを使用
extends BaseCustomCommand

func _init():
    # .rgdスクリプトで使用する名前
    command_name = "log_message"
    
    # 簡単な説明
    description = "Godotの出力コンソールにカスタムメッセージを出力します。"
    
    # ユーザー向けのヘルプテキスト
    help_text = "log_message <message=string>"

func execute(parameters: Dictionary, adv_system: Node) -> void:
    # 'message'パラメータを取得します。指定されていない場合は空文字列をデフォルトとします。
    var message_to_log = parameters.get("message", "")
    
    if message_to_log.is_empty():
        log_warning("log_messageコマンドがメッセージなしで呼び出されました。")
        return
        
    # Godotの出力コンソールにメッセージを出力します
    print("ARGODE LOG: " + message_to_log)
    
    # オプションで、Argodeの内部コマンドログに記録します（'ui list'またはデバッグツールで表示可能）
    log_command("ログメッセージ: " + message_to_log)
```

### ステップ3: 新しいコマンドを`.rgd`スクリプトで使用する

これで、`log_message`コマンドを任意の`.rgd`スクリプトファイルで使用できます。

```rgd
label start:
    narrator "ゲームへようこそ！"
    log_message message="プレイヤーがゲームを開始しました。"
    
    narrator "何か重要なことが起こりそうです。"
    log_message "重要なイベントの準備中。" # 位置パラメータも機能します
```

ゲームを実行すると、Godotの出力コンソールに「ARGODE LOG: プレイヤーがゲームを開始しました。」と「ARGODE LOG: 重要なイベントの準備中。」が表示されます。

## パラメータの処理

Argodeは、`.rgd`スクリプトからパラメータを自動的に解析し、コマンドの`execute`（または`execute_internal_async`）メソッドの`parameters`辞書に渡します。

### キーと値のパラメータ

```rgd
my_command key1="value" key2=123
```
`execute`メソッド内:
```gdscript
func execute(parameters: Dictionary, adv_system: Node) -> void:
    var value1 = parameters.get("key1", "default_string") # "value"
    var value2 = parameters.get("key2", 0)               # 123
```

### 位置パラメータ

```rgd
my_command "first_arg" 456
```
`execute`メソッド内:
```gdscript
func execute(parameters: Dictionary, adv_system: Node) -> void:
    var first_arg = parameters.get("arg0", "") # "first_arg"
    var second_arg = parameters.get("arg1", 0) # 456
```
位置パラメータは、`arg0`、`arg1`、`arg2`などのキーが自動的に割り当てられます。

### 混合パラメータ

キーと値、および位置パラメータを組み合わせることができます。
```rgd
my_command "positional_value" named_param="value" another_pos=789
```
`execute`メソッド内:
```gdscript
func execute(parameters: Dictionary, adv_system: Node) -> void:
    var pos_val = parameters.get("arg0", "")      # "positional_value"
    var named_val = parameters.get("named_param", "") # "value"
    var another_pos_val = parameters.get("arg1", 0) # 789
```

## 同期コマンドと非同期コマンド

デフォルトでは、コマンドは非同期です。これは、コマンドの`execute`メソッドが呼び出された直後に、`.rgd`スクリプトが次の行の実行を続行することを意味します。

コマンドが時間のかかる操作（例: アニメーションの終了を待つ、リソースのロード、ネットワークリクエスト）を実行する必要があり、`.rgd`スクリプトがその完了を**待つ**必要がある場合は、コマンドを**同期**にする必要があります。

同期コマンドを作成するには：

1.  **`is_synchronous()`をオーバーライド:**
    ```gdscript
    func is_synchronous() -> bool:
        return true
    ```
2.  **`execute_internal_async()`を実装:** 時間のかかるロジックをこのメソッド内に記述します。制御を譲る操作には`await`キーワードを使用します。

    ```gdscript
    func execute_internal_async(parameters: Dictionary, adv_system: Node) -> void:
        var duration = parameters.get("duration", 1.0)
        print("待機中: " + str(duration) + "秒...")
        await adv_system.get_tree().create_timer(duration).timeout
        print("待機終了。")
    ```
    `is_synchronous()`が`true`を返す場合、Argodeは`execute_internal_async()`を呼び出し、このメソッドが完了するまで（つまり、その中のすべての`await`操作が解決されるまで）`.rgd`スクリプトを一時停止します。

## ベストプラクティス

-   **1コマンド1ファイル:** 整理とモジュール性を高めるために、各カスタムコマンドを独自の`.gd`ファイルに保持します。
-   **一意の`command_name`と`class_name`:** 競合を避けるために、これらがプロジェクト全体で一意であることを確認します。
-   **明確な`description`と`help_text`:** これらは、あなたやコマンドを使用する他の開発者にとって非常に貴重です。
-   **パラメータの検証:** 必須パラメータが提供されているか、その値が期待される型と範囲内にあるかを常に確認します。問題を適切に報告するために`log_error()`または`log_warning()`を使用します。
-   **`log_command()`の使用:** コマンドの`execute`または`execute_internal_async`メソッド内で`log_command("あなたのメッセージ")`を呼び出して、Argodeの内部コマンドログ（`ui list`または他のデバッグツールで表示可能）にデバッグ情報を出力します。
-   **ArgodeSystemへのアクセス:** `adv_system`パラメータを使用して、他のArgodeマネージャー（例: `adv_system.VariableManager`、`adv_system.UIManager`）にアクセスします。

---

これらのガイドラインに従うことで、Argodeの機能をシームレスに拡張する強力で堅牢なカスタムコマンドを作成できます。
