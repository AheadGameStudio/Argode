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


- コマンドの読み込み（ArgodeCommandRegistry）:
  - ArgodeSystemはArgodeCommandRegistryの初期化を呼び出します。
  - ArgodeCommandRegistryは、組み込みのコマンドフォルダ（res://addons/argode/builtin/commands/）とユーザー定義のコマンドフォルダ（res://custom_commands/）から.gdファイルを再帰的に読み込みます。
  - 読み込んだファイルは、ClassDB（Godotのクラス情報を扱うクラス）やファイルパス情報を使って、クラス名（例: SayCommand）とコマンド名（例: "say"）を紐づけ、ArgodeSystemのコマンド辞書に登録します。

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


### ArgodeRGDPerser

例：
```
# scenarios/scenario.rgd

show alice
"こんにちは！"
jump main_menu
```

パース結果：
```
[
    {
        "type": "command",
        "name": "show",
        "args": ["alice"],
        "line": 3
    },
    {
        "type": "say",
        "name": "say",
        "args": ["こんにちは！"],
        "line": 4
    },
    {
        "type": "command",
        "name": "jump",
        "args": ["main_menu"],
        "line": 5
    }
]
```


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



## 🧠 全体フローの確認

1. 起動と定義の読み込み
   - ArgodeSystemが起動:
     - ArgodeSystemが起動し、すべてのマネージャーとサービスを初期化します。
   - レジストリの初期化:
     - ArgodeCommandRegistry: 組み込みコマンドとカスタムコマンドのGDScriptファイルを読み込み、コマンド名とインスタンスの紐付けを行います。この時、is_define_commandも合わせて記録します。
     - ArgodeLabelRegistry: 全シナリオファイル（RGDファイル）を高速で走査し、labelステートメントの情報（ラベル名、ファイルパス、行番号）のみを辞書に登録します。
   - 定義の実行:
     - ArgodeDefinitionRegistry: 定義ファイル（RGDファイル）を読み込みます。この時、読み込んだファイルの内容を**ArgodeRGDParserに渡して**パースさせます。
     - ArgodeRGDParserは、定義ファイルのテキストをステートメントのリストに変換します。
     - ArgodeStatementManagerは、そのリストを受け取り、定義コマンドのみ（is_define_command: trueのコマンド）を順次実行します。
     - SetCommandはVariableManagerに、CharacterCommandはキャラクター情報管理サービスに、CharacterDefinePositionCommandはLayerManagerに定義情報を送ります。
2. 実行待ち状態
   - すべての定義の読み込みが完了すると、ArgodeSystemはゲームの実行を待つ状態になります。
3. ラベルの実行
   - ユーザーがゲームを開始するなどして、ArgodeSystem.play("label_name")が呼び出されます。
   - ArgodeSystemは、ArgodeLabelRegistryに"label_name"が登録されているか確認し、対応するRGDファイルのパスを取得します。
   - ArgodeStatementManagerは、そのRGDファイルのパスを**ArgodeRGDParserに渡して、パースを依頼します**。
   - ArgodeRGDParserは、該当のRGDファイルをまるごとパースし、すべてのステートメントをリストとしてArgodeStatementManagerに返します。
4. シナリオの実行
   - ArgodeStatementManagerは、受け取ったステートメントリストをメモリに保持し、"label_name"から順次実行を開始します。
   - 各ステートメント（say、show、ifなど）に到達すると、ArgodeStatementManagerは、ArgodeCommandRegistryから対応するインスタンスを取得し、execute()メソッドを呼び出します。

#### 結論

このフローは、**「必要な情報（ラベル、定義）は起動時に高速に読み込む」一方で、「シナリオの本文は、実行が必要になったタイミングでパースする（遅延パース）」**という、パフォーマンスと管理のしやすさを両立させる、非常に優れた設計です。

この設計であれば、ファイルの数が増えても起動時間が遅くなることはなく、メモリの消費も抑えられます。



## 構成


| 役割 | クラス名 | 説明 |
| --- | --- | --- |
| core | ArgodeSystem | システム全体を管理するコア（オートロード・シングルトン）
マネージャー・コントローラーなどを生成し、ArgodeSystem経由でアクセスが可能になる。
フレームワーク全体の状態やタイマーなども管理する。 |
| controllers | ArgodeController | フレームワーク全体で使うプレイヤー入力を一元管理 |
| managers | ArgodeStatementManager | 各ステートメント（インデントブロック含む）を管理
再帰的な構造とし、**現在の実行コンテキスト**を管理
`StatementManager`は、個々のコマンドが持つ**複雑なロジックを直接は扱わず**、**全体の流れを制御すること**に特化しています。**スクリプト全体を俯瞰し、実行を指示する**のが`StatementManager`の役割。**一つひとつの具体的なタスク**（台詞表示、ルビ描画など）を実行するのが**各コマンドやサービス**の役割。 |
|  | ArgodeInlineCommandManager | 1. raw_textを受け取る。
2. TagTokenizerを呼び出し、テキストをトークンに分解させる。
3. トークンを一つずつループ処理する。
4. トークンが特殊タグであれば、TagRegistryに問い合わせ、対応するコマンドクラス（RubyCommandなど）を取得する。
5. そのコマンドを実行し、RichTextConverterに処理を委譲する。
6. RichTextConverterが返したBBCodeを結合して、最終的なRichTextLabel用のテキストを返す。 |
|  | ArgodeLayerManager | 各レイヤーのセットアップや状態管理 |
|  | ArgodeDebugManager | デバッグ用の管理クラス |
|  | ArgodeAssetManager | アセットの読み込みや解放を管理
主にアセット周りによる処理負荷対策が目的 |
|  | ArgodeVariableManager | フレームワーク内の動的変数を管理するためのクラス |
|  | ArgodeTransitionManager | `with`修飾子の後の遷移アニメーションを管理 |
|  | ArgodeRubyManager | 現在のメッセージのルビの位置情報などを保持・管理 |
| views | ArgodeMessageWindow | ArgodeViewBaseを継承した基本となるメッセージウィンドウ |
| renderer | ArgodeMessageRenderer | 最終的なメッセージを描画するためのレンダラー |
|  | ArgodeRubyRenderer | ルビを描画するレンダラー |
|  | ArgodeCharacterRenderer | キャラクターアセットを描画するレンダラー |
|  | ArgodeBackgroundRenderer | 背景アセットを描画するレンダラー |
| services | ArgodeRGDParser | RGDファイルをパースする機能 |
|  | ArgodeTypewriterService | タイプライター表現のために文章を分割しながらシグナルを発行するだけの機能
コマンドの受付を行うレシーバーも用意し、タイプライター速度変更や停止、スキップなどを可能にする。 |
|  | ArgodeLabelRegistry | プロジェクト内のシナリオ用の特定フォルダ内のRGDファイルを再帰的に検索し、ラベルとシナリオファイルのラベルステートメントの行番号をオブジェクトとして保存する。 |
|  | ArgodeCommandRegistry | プロジェクト内のコマンド用の特定フォルダ内のRGDファイルを再帰的に検索しフレームワークのグローバルアクセスが可能なオブジェクトとして保存する。 |
|  | ArgodeDefinitionRegistry | プロジェクト内のアセットや変数などの定義用のフォルダ内のRGDファイルを最適的に検索し、フレームワーク全体の定義として利用できるように保存する。 |
|  | ArgodeTagTokenizer | テキストをトークン（単語や記号の最小単位）に分解すること。 |
|  | ArgodeTagRegistry | タグ名と、そのタグに対応するコマンドのマップを保持。
`{ "ruby": RubyCommand, "get": GetCommand }`のような辞書 |
|  | ArgodeRichTextConverter | TagTokenizerが分解したトークンをGodotのRichLabelが解釈できるBBCodeに変換すること。 |
|  | ArgodeAnimatedTextureService | 引数として受け取った情報（画像パスと待機時間）をもとに、GodotのAnimatedTextureリソースを動的に生成。 |
| constructs | ArgodeCommandBase | フレームワークで使用するコマンドの基底クラス |
|  | ArgodeViewBase | Argodeフレームワーク汎用のGUI抽象クラス |

## ビルトイン

`addons/argode/builtin`にフレームワークのビルトインとして提供する各機能
アドオンとして配布物に含まれるだけで、ユーザーカスタムとまったく一緒。

| カテゴリ |  |  |
| --- | --- | --- |
| commands | SetCommand | 変数を設定するコマンド |
|  | GetCommand | 変数を呼び出すコマンド |
|  | AudioCommand | 音声を定義するためのコマンド |
|  | ImageCommand | 画像を定義するためのコマンド |
|  | CharacterCommand | キャラクターを定義するためのコマンド |
|  | UICommand | GUIレイヤーにGodotのPackedSceneをインスタンス化し表示・非表示または削除するコマンド |
|  | MenuCommand | UICommandを拡張した選択肢に限定したUIを表示するコマンド |
|  | DialogCommand | UICommandを拡張したダイアログに限定したUIを表示するコマンド |
|  | WaitCommand | フレームワーク全体のタイマーを一時的に停止するコマンド |
|  | TransitionCommand | コマンドの修飾子である`with`キーワードの後に設定する遷移コマンド |
|  | SayCommand | キャラクターを指定してメッセージを表示するコマンド |
|  | LabelCommand | ラベルブロックを定義するコマンド |
|  | CallCommand | ラベルをコールし、サブルーチン的に処理するコマンド |
|  | JumpCommand | ラベルにジャンプし、移動・再生するコマンド |
|  | IfCammand | 条件分岐ブロックを定義・処理するコマンド |
|  | ShowCommand | 表示に関するコマンド（キャラ・背景・GUI） |
|  | HideCommand | 非表示に関するコマンド（キャラ・背景・GUI） |
|  | SaveCommand | ゲームを保存するコマンド |
|  | LoadCommand | ゲームを読み込むコマンド |
|  | RubyCommand | `【ルビ｜るび】`という特殊なタグを使うことでルビを描画するインラインコマンドとする |
|  | NotificationCommand | 通知を表示するコマンド |
|  | CharacterDefinePositionCommand | キャラクターの表示座標を具体的に定義するコマンド
define_position chara_pos_left_center at [800, 800] |
| scenes | ArgodeChoicesDialogue.tscn | プロジェクトで何も指定されない場合使用されるArgodeフレームワークが用意するデフォルトの選択肢UIシーン |
|  | ArgodeConfirmDialogue.tsdn | プロジェクトで何も指定されない場合使用されるArgodeフレームワークが用意するデフォルトの確認ダイアログUIシーン |
|  | ArgodeDefaultMessageWindow.tscn | プロジェクトで何も指定されない場合使用されるArgodeフレームワークが用意するデフォルトのメッセージウィンドウシーン |
|  | ArgodeDefaultNotificationScreen.tscn | プロジェクトで何も指定されない場合使用されるArgodeフレームワークが用意するデフォルトの通知表示用の画面シーン。
通知カードをVBoxContainerに生成し一定時間で削除するシーン |
|  | ArgodeDefaultNotificationCard.tscn | プロジェクトで何も指定されない場合使用されるArgodeフレームワークが用意するデフォルトの通知カードのシーン |