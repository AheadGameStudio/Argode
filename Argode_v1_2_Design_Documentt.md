# Argode v1.2 実行プロセス

ユーザーはプロジェクトにArgodeプラグインをインストール・有効化することで、プラグインは自動的に`ArgodeSystemCore`を`ArgodeSystem`としてオートロードに登録しグローバル化します。

以下はゲーム起動時に`ArgodeSystem`から行われる処理プロセスをまとめています。

## 初期化

1. ArgodeSystemが各マネージャー・コントローラーをインスタンス化し、ArgodeSystemを介してアクセス可能な状態にセットアップ
   - ArgodeStatementManagerは特に大きなマネージャーで、RGDファイルの各ステートメントを管理する役割なので、これがないと以降何も動かない。
2. Argodeプラグインによる「プロジェクト設定」を読み込み、各マネージャーに設定を反映
3. もし`user://`ディレクトリ以下にArgodeSystemに関するユーザー設定ファイルがあれば、各マネージャーの設定を上書き
4. 各レジストリの非同期処理を開始（場合によってはハングアップしてしまうので、その回避）
   1. 全レジストリの完了には時間がかかる可能性があるため、一時的に組み込みのローディング画面（`res://addons/argode/buitin/scene/argode_loading/argode_loading.tscn`）を表示し待機
   2. 各Registryから全体量と進捗を受け取れるようにする
   3. ArgodeCommandRegistryの実行（後述する「レジストリのプロセス」を参照）
      - コマンドがないとRGDファイルの定義コマンドが動かないので先に実行し結果を待つ
      - コマンドリストを動的に作成し、ArgodeSystemのコマンド辞書に登録
   4. ArgodeDefinitionRegistryの実行
      - 各コマンドによる定義になるため必要に応じて各Serviceを呼び出して処理を行う
   5. ArgodeLabelRegistryの実行
      - 全シナリオファイルからlabelステートメントのヘッダだけを抽出し、そのラベル名・ファイルパス・行番号をArgodeSystemの辞書に登録
   6. 組み込みのローディング画面を消去

以上で、ArgodeSystemが必要とするマネージャーやコントローラーのセットアップをし、ユーザーが任意で作成するRGDファイルや設定ファイルの情報を集積し、保持することに成功しました。  


### レジストリのプロセス

#### ArgodeCommandRegistry

ArgodeCommandRegistryは以下のフォルダの`.rgd`ファイルを再帰的に検索し、コマンドとして`ArgodeStatementManager`が扱える形でコマンドを登録していきます。

```
res://addons/argode/builtin/commands/
res://custom_commands/
```

プロジェクト設定のArgodeSystem設定で「Custom Command Directory」が設定されている場合は、そのディレクトリも検索対象に含めます。

#### ArgodeDefinitionRegistry

ArgodeDefinitionRegistryは以下のフォルダの`.rgd`ファイルを再帰的に検索し、定義コマンドを抽出して、実際にArgoSystemに定義処理を行います。

```
res://addons/argode/builtin/definitions/
res://definitions/
```

プロジェクト設定のArgodeSystem設定で「Definition Directory」が設定されている場合は、そのディレクトリも検索対象に含めます。  
ArgoSystemで配列`definition_commands_list`に定義された「定義コマンド群」と一致するステートメントだけを抽出します。

#### ArgodeLabelRegistry

ArgodeLabelRegistryは、以下のフォルダの`.rgd`ファイルを再帰的に検索し、シナリオ定義ファイルとして扱い、ラベル名・シナリオファイルパス・行番号を辞書とラベル名だけを検索するための配列（PackedStringArray）として保存します。

```
res://scenarios/
```

プロジェクト設定のArgodeSystem設定で「Senario Directory」が設定されている場合は、そのディレクトリも検索対象に含めます。


```
# 保存される辞書の例：

{ label:"Start", path:"res://scenarios/scenario.rgd", line:0 }
```

ラベルを発見次第順次登録するため、登録時に既にラベルが存在する場合エラーを出します。

---

次は各ユースケースにおけるプロセスを説明します。
主にArgodeStatementManagerが他サービスと連携しながら読み込むためのプロセスが多いので注意しましょう。


### ステートメント説明

#### Sayステートメント

Sayもコマンドなので、コマンドとして実行するためには通常以下のように記述します。

```
say alice "こんにちは！"
```

しかし、シナリオファイルとしては冗長になるため、以下の記述でもsayコマンドが実行されます。

```
alice "こんにちは！"
```

つまりコマンド辞書に登録されていない文字列か、ダブルクォーテーションによる文字列が行頭にある場合、sayコマンドとして最優先で実行されることになります。
もし、キャラクターエイリアスとコマンドが重複した場合はコマンドが優先され、キャラクター定義のエイリアスは無視され、`ArgodeDefinitionRegistery`で定義を走査・設定する場合にエラーが出ます。

### コメント行

```
# これはコメントステートメントです
```

`#`で始まる行はコメント行として処理されません。

### 変数定義ステートメント

変数は2種類の定義方法があります。

```
# 通常の変数定義
set player_name = "プレイヤー"
set player_score = 0
set player_pos_x = 10
set player_pos_y = 10

# または

# ネストされた変数定義
set player.name = "プレイヤー"
set player.score = 0
set player.pos_x = 10
set player.pos_y = 10
```

Godot上の型はVariantで登録されるため、値に合わせて型が定義されます。
辞書・配列は利用できません。


### 変数呼び出しステートメント

コマンドとしては以下で値を取り出すことができます。

```
get player.name
```

しかし、値を取り出しても処理がないためこの場合単純に`ArgoSystem.log()`でログとして出力されるだけです。
変数の値を利用する場合は以下のように使用します。

```
# IFコマンドで使用する
if player.name == "プレイヤー":
    # セリフ内で変数を呼び出す
    "プレイヤーの名前は[player.name]です。"
```

### キャラクター定義ステートメント

```
# character <alias> <actual name> [color] [image_prefix] [voice_prefix]
character alice "アリス" color "#ffcc00" image_prefix "alice" voice_prefix "alice"
```  

characterコマンドの第1引数はセリフで使用するエイリアスです。
`alice "こんにちは"`として使用します。