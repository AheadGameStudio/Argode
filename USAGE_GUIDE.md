# Ren' Gd 使用ガイド 🎮

このガイドでは、Ren' Gd ADVエンジンの使用方法を説明します。

## 🚀 クイックスタート

### 1. 基本的な動作確認（コンソールモード）

現在の `main.tscn` はコンソールベースでの動作確認ができます：

- 背景とキャラクター: プレースホルダーで表示
- メッセージ: コンソールに出力  
- 選択肢: 数字キー（1-5）で選択
- トランジション: 背景・キャラクターで動作確認可能

### 2. ビジュアルUI表示（推奨）

美しいUIでテストするには、メインシーンを変更してください：

#### 手順A: プロジェクト設定で変更
1. Godotエディタで `Project` → `Project Settings` を開く
2. `Application` → `Run` → `Main Scene` を変更
3. `res://src/scenes/gui/usage_sample.tscn` を選択
4. ゲームを実行

#### 手順B: シーンを直接実行
1. Godotエディタで `src/scenes/gui/usage_sample.tscn` を開く
2. シーンを実行（F6キー）

## 🎨 UIサンプルの機能

### 視覚的なUI要素
- **メッセージボックス**: 半透明の背景付きテキスト表示
- **キャラクター名表示**: 色付きの名前表示  
- **選択肢ボタン**: マウスクリック可能なボタン
- **RichTextLabel**: カラーテキスト、太字、斜体対応

### 操作方法
- **Enterキー**: メッセージ送り
- **数字キー(1-3)**: 選択肢選択
- **マウス**: 選択肢ボタンをクリック
- **Spaceキー**: テストメッセージ表示

## 📝 .rgdスクリプトの書き方

### 基本的なスクリプト
```
# キャラクター定義
define y = Character("res://characters/yuko.tres")
define s = Character("res://characters/saitos.tres")

label start:
    "物語が始まります。"
    
    scene classroom with fade
    "教室の背景が表示されました。"
    
    show y happy at center with slide_left
    y "こんにちは！優子です。"
    
    menu:
        "質問する":
            jump question
        "終了する":
            jump ending
            
label question:
    y "何か質問はありますか？"
    jump start
    
label ending:
    "物語は終了しました。"
```

### 使用可能なコマンド

#### キャラクター・背景表示
- `show キャラID 表情 at 位置 with トランジション`
- `hide キャラID with トランジション`
- `scene 背景名 with トランジション`

#### トランジション効果
- `fade` - フェード効果
- `dissolve` - ディゾルブ効果  
- `slide_left/right/up/down` - スライド効果

#### ウィンドウ制御（v2新機能）
```rgd
# ゲームモード切り替え例 - トランジション効果付きUI制御
label game_menu:
    y "何をしますか？"
    menu:
        "バトルをする":
            jump battle_mode
        "マップを探索":
            jump explore_mode
        "普通に会話":
            jump normal_chat

label battle_mode:
    window show with fade  # UIをフェードインで表示
    "バトルモード開始！UIがフェードインします。"
    # call_screen battle_system
    window auto with dissolve  # 終了後はディゾルブで自動制御
    jump game_menu

label explore_mode:
    window hide with dissolve  # UIをディゾルブで非表示
    "マップ探索モード開始！UIがディゾルブして消えます。"
    # call_screen map_explorer
    window auto with slide_down  # 終了後はスライドで自動制御
    jump game_menu

label normal_chat:
    window auto with fade  # 通常の会話（フェードで自動制御）
    y "のんびりお話ししましょう。"
    jump game_menu
```
- `none` - トランジションなし

#### フロー制御
- `jump ラベル名` - ラベルにジャンプ
- `call ラベル名` - サブルーチン呼び出し
- `return` - 呼び出し元に戻る

#### 変数・条件分岐
- `set 変数名 = 式` - 変数設定
- `if 条件式:` - 条件分岐開始
- `else:` - else節
- `{変数名}` - テキスト内で変数展開

## 🛠️ カスタマイズ

### 独自UIの作成
1. `src/scenes/gui/AdvGameUI.tscn` をコピー
2. レイアウト・色・フォントを変更  
3. `setup_ui_manager_integration()` メソッドを実装
4. メインシーンで使用

### キャラクターリソース作成
1. `characters/` フォルダに新しい `.tres` ファイル作成
2. `CharacterData` リソースとして設定
3. `display_name` と `name_color` を設定

### カスタム画像素材
- 背景: `assets/images/backgrounds/背景名.png`
- キャラクター: `assets/images/characters/キャラID_表情.png`

## 🎯 完成済み機能一覧

✅ **コア機能**
- スクリプト解析・実行エンジン
- キャラクター管理システム  
- 変数管理・条件分岐
- UI管理システム
- トランジション効果システム

✅ **スクリプトコマンド**
- すべての基本コマンド（say, set, jump, call, return等）
- すべての演出コマンド（scene, show, hide, with句）
- 選択肢システム（menu）
- キャラクター定義（define）
- UI全体制御（window show/hide/auto）🆕

✅ **UI・表示**
- プレースホルダー画像システム
- コンソール出力モード
- ビジュアルUIサンプル
- RichTextLabel対応
- Argode UI全体制御システム（CanvasLayer）🆕

✅ **サンプル・ドキュメント**  
- 複数のテストシナリオ
- UIサンプルシーン
- 完全なドキュメント

## 🎉 次のステップ

このアドオンは既に完全に機能する ADV エンジンです！

1. **独自のシナリオ作成**: `.rgd` ファイルでストーリーを書く
2. **UI カスタマイズ**: デザインを自分好みに変更
3. **画像素材追加**: キャラクターや背景画像を用意  
4. **音響効果**: BGM・SE システムの追加検討

楽しいADVゲーム作成をお楽しみください！🚀