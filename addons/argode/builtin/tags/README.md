# Argode カスタムタグシステム

## 📖 概要

Argodeシステムでは、シナリオファイル内でリッチなテキスト演出やゲーム機能を呼び出すための**カスタムタグシステム**を提供しています。

## 🚀 自動発見システム

**重要**: カスタムタグは自動的に発見・登録されます！ArgodeSystemを編集する必要はありません。

### 📁 自動スキャンディレクトリ

以下のディレクトリが自動的にスキャンされ、カスタムタグが登録されます：

1. `res://addons/argode/builtin/tags/` - Argode組み込みタグ（最優先）
2. `res://custom/tags/` - プロジェクト専用カスタムタグ
3. `res://addons/*/tags/` - 他のアドオンからのタグ

### 🔄 登録条件

- `.gd`ファイルであること
- `BaseCustomTag`を継承していること
- `get_tag_name()`, `get_tag_type()`, `get_tag_properties()`メソッドを実装していること

## 🏷️ タグの種類

### 1. **即座実行タグ (IMMEDIATE)**
シナリオ実行時に即座に処理されるタグです。

```rgd
"テキストが表示されて{w=2.0}2秒待機してから続きが表示される。"
"画面が{shake=intensity:2.0:duration:0.5}揺れる演出付き。"
```

**ビルトイン即座実行タグ:**
- `{w=時間}` - 指定時間待機
- `{wait=時間}` - 指定時間待機（w と同じ）
- `{p}` - タイプライター中にユーザー入力待ち
- `{pause}` - タイプライター中にユーザー入力待ち（p と同じ）
- `{clear}` - テキストエフェクトをクリア
- `{shake=パラメータ}` - 画面シェイクエフェクト

### 2. **装飾タグ (DECORATION)**
テキストの見た目を装飾するタグです。BBCodeに自動変換されます。

```rgd
"これは{color=red}赤い文字{/color}です。"
"これは{b}太字{/b}で{i}斜体{/i}のテキストです。"
"これは{a=glossary:key}クリック可能なリンク{/a}です。"
```

**ビルトイン装飾タグ:**
- `{color=色}...{/color}` - テキスト色
- `{size=サイズ}...{/size}` - フォントサイズ
- `{b}...{/b}` - 太字
- `{i}...{/i}` - 斜体
- `{u}...{/u}` - 下線
- `{s}...{/s}` - 取り消し線
- `{bgcolor=色}...{/bgcolor}` - 背景色
- `{a=パラメータ}...{/a}` - リンク（用語集等）

### 3. **カスタムタグ (CUSTOM)**
独自に定義された機能呼び出しタグです。

```rgd
"BGMが{audio=bgm:play:title_music.ogg:fade:2.0}フェードインで再生される。"
"UIが{ui=show:menu.tscn:center:fade}フェード表示される。"
```

## 🛠️ カスタムタグの作成方法

### 基本的な手順

1. **BaseCustomCommandを継承したクラスを作成**
2. **InlineTagProcessorに登録**
3. **シナリオで使用**

### 例: AudioTagの実装

#### 1. カスタムコマンドクラスの作成

```gdscript
# AudioTag.gd
@tool
class_name BuiltinAudioTag
extends BaseCustomCommand

func _init():
    command_name = "audio_tag"
    description = "インラインオーディオタグ処理"

func execute_internal_async(params: Dictionary, adv_system: Node):
    # パラメータを解析
    var action_data = params.get("action", "").split(":")
    
    # AudioCommandを呼び出し
    var audio_command = adv_system.CustomCommandHandler.get_command("audio")
    if audio_command:
        await audio_command.execute_internal_async(converted_params, adv_system)
```

## 🛠️ カスタムタグの作成方法

### 1. BaseCustomTagを継承したクラスを作成

```gdscript
# MyCustomTag.gd
@tool
class_name MyCustomTag
extends BaseCustomTag

func _init():
    set_tag_info(
        "mytag",                                    # タグ名
        InlineTagProcessor.TagType.IMMEDIATE,       # タグタイプ
        "カスタムタグの説明",                        # 説明
        "mytag=value - 使用例の説明"                # ヘルプテキスト
    )
    
    # 実行タイミングを設定（必要に応じて）
    set_execution_timing(InlineTagProcessor.ExecutionTiming.PRE_VARIABLE)

func process_tag(tag_name: String, parameters: Dictionary, adv_system: Node) -> void:
    """タグが実行された時の処理"""
    var value = parameters.get("value", "")
    log_info("Processing tag with value: " + str(value))
    
    # ここに実際の処理を記述
    print("カスタムタグが実行されました: ", value)
```

### 2. 適切なディレクトリに配置

以下のいずれかのディレクトリに`.gd`ファイルを保存：
- `res://custom/tags/MyCustomTag.gd` （推奨：プロジェクト専用）
- `res://addons/your_addon/tags/MyCustomTag.gd` （アドオン用）

### 3. 自動的に登録される！

ゲーム開始時に自動的に発見・登録されます。ArgodeSystemの編集は不要です。

### 4. シナリオで使用

```rgd
label example:
    "カスタムタグを使用{mytag=hello_world}します。"
```

## 🎯 タグの実行タイミング

### PRE_VARIABLE（変数展開前）
変数が展開される前に実行されます。即座実行タグに適しています。

### POST_VARIABLE（変数展開後）
変数展開後に実行されます。装飾タグに適しています。

### DURING_TYPEWRITER（タイプライター中）
タイプライター表示中に実行されます。一時停止タグに適しています。

## 📝 パラメータの解析

### 単純な値
```gdscript
{w=2.5}  # params = {"value": 2.5}
```

### 複合パラメータ（コロン区切り）
```gdscript
{audio=bgm:play:music.ogg:fade:1.0}
# params = {"action": "bgm:play:music.ogg:fade:1.0"}
```

### キーバリューパラメータ
```gdscript
{shake=intensity:2.0:duration:0.5}
# params = {"intensity": 2.0, "duration": 0.5}
```

## 🔧 高度な機能

### 1. **エラーハンドリング**

```gdscript
func execute_internal_async(params: Dictionary, adv_system: Node):
    try:
        # パラメータ検証
        if not params.has("required_param"):
            log_error("Required parameter missing")
            return
        
        # 処理実行
        # ...
        
    except:
        log_error("Tag execution failed")
```

### 2. **非同期処理**

```gdscript
func execute_internal_async(params: Dictionary, adv_system: Node):
    # 非同期でUIアニメーション実行
    await show_ui_with_animation(params)
    
    # 完了後に次の処理へ
    print("UI animation completed")
```

### 3. **既存コマンドとの連携**

```gdscript
func execute_internal_async(params: Dictionary, adv_system: Node):
    # 既存のUICommandを利用
    var ui_command = adv_system.CustomCommandHandler.get_command("ui")
    if ui_command:
        var converted_params = convert_tag_params_to_command_params(params)
        await ui_command.execute_internal_async(converted_params, adv_system)
```

## 📚 実用的なタグ例

### UIタグ
```rgd
"メニューを表示{ui=show:menu.tscn:right:slide}します。"
"ダイアログを表示{ui=show:dialog.tscn:center:fade}します。"
"画面をクリア{ui=hide_all:fade:1.0}します。"
```

### オーディオタグ
```rgd
"戦闘BGM開始{audio=bgm:play:battle.ogg:loop:fade:2.0}！"
"効果音{audio=se:play:explosion.ogg:volume:0.9}！"
"音楽停止{audio=bgm:stop:fade:3.0}。"
```

### エフェクトタグ
```rgd
"画面フラッシュ{flash=color:white:duration:0.3}！"
"画面ぼかし{blur=strength:5.0:duration:1.0}効果。"
"画面シェイク{shake=intensity:3.0:duration:0.8}！"
```

### カメラタグ
```rgd
"カメラズームイン{camera=zoom:2.0:duration:1.5:easing:ease_in_out}。"
"カメラパン{camera=pan:100:50:duration:2.0}移動。"
```

## 🎨 デザインパターン

### 1. **パラメータチェーン**
```rgd
"複合演出{audio=bgm:play:dramatic.ogg:fade:1.0}{shake=2.0:0.5}{flash=red:0.2}発動！"
```

### 2. **条件付きタグ**
```gdscript
# カスタムタグ内で条件分岐
if player_health <= 20:
    execute_low_health_effects()
```

### 3. **タグの組み合わせ**
```rgd
"戦闘開始{audio=bgm:stop:fade:1.0}{w=1.5}{audio=bgm:play:battle.ogg:fade:2.0}{shake=1.5:1.0}！"
```

## 🔍 デバッグとテスト

### ログ出力
```gdscript
func execute_internal_async(params: Dictionary, adv_system: Node):
    print("🏷️ [MyTag] Executing with params: ", params)
    # 処理...
    print("✅ [MyTag] Execution completed")
```

### パラメータ検証
```gdscript
func validate_parameters(params: Dictionary) -> bool:
    var required_keys = ["action", "target"]
    for key in required_keys:
        if not params.has(key):
            log_error("Missing required parameter: " + key)
            return false
    return true
```

## 📋 ベストプラクティス

### 1. **命名規則**
- タグ名は短く、わかりやすく
- パラメータは英語で統一
- 動詞+名詞の組み合わせを推奨

### 2. **パフォーマンス**
- 重い処理は非同期で実行
- 不要なオブジェクト生成を避ける
- キャッシュを活用

### 3. **ユーザビリティ**
- エラーメッセージは具体的に
- ヘルプテキストを充実させる
- 使用例を豊富に提供

### 4. **互換性**
- 既存のタグとの干渉を避ける
- パラメータ形式の一貫性を保つ
- 後方互換性を考慮

## 🚀 拡張のアイデア

- **アニメーションタグ**: キャラクターアニメーション制御
- **パーティクルタグ**: パーティクルエフェクト発動
- **セーブタグ**: 自動セーブポイント設定
- **フラグタグ**: ゲームフラグ操作
- **計算タグ**: 数値計算とUI表示
- **ネットワークタグ**: 外部API呼び出し

カスタムタグシステムにより、シナリオライターは複雑なゲーム機能を簡潔な記法で呼び出せ、より表現豊かなストーリー体験を作成できます。
