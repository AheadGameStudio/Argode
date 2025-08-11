# クイックスタートガイド

わずか数分でArgodeを動かしましょう！このガイドでは、最初のビジュアルノベルシーンの作成方法をご案内します。

## 前提条件

- **Godot Engine 4.0+** ([こちらからダウンロード](https://godotengine.org/))
- **Godotプロジェクトの基本的な知識**

## ステップ 1: Argodeのインストール

### オプション A: AssetLibから（推奨）
1. Godot Engineを開く
2. **AssetLib** タブに移動
3. **"Argode"** を検索
4. **ダウンロード** して **インストール** をクリック

### オプション B: 手動インストール
1. [GitHub](https://github.com/AheadGameStudio/Argode)から最新リリースをダウンロード
2. `addons/argode/` フォルダをプロジェクトの `addons/` ディレクトリに展開
3. **プロジェクト設定 → プラグイン** でプラグインを有効化

## ステップ 2: オートロードの設定

1. **プロジェクト設定** を開く（`Project → Project Settings`）
2. **オートロード** タブに移動
3. **ArgodeSystem** を追加：
   - **パス**: `res://addons/argode/core/ArgodeSystem.gd`
   - **ノード名**: `ArgodeSystem`
   - **有効** にチェック

![オートロード設定](../images/autoload-setup.png)

## ステップ 3: 最初のスクリプトを作成

新しいファイル `scenarios/story.rgd` を作成：

```gdscript
# story.rgd - あなたの最初のビジュアルノベルスクリプト

# キャラクターを定義
character narrator "ナレーター" color=#ffffff
character alice "アリス" color=#ff69b4  

label start:
    narrator "あなたの最初のArgodeビジュアルノベルへようこそ！"
    
    show alice happy at center with fade
    alice "こんにちは！私はアリス、この新しい世界へのガイドです。"
    alice "まず何をしたいですか？"
    
    menu:
        "ストーリーについて学ぶ":
            jump learn_story
        "世界を探検する":
            jump explore_world
        "他のキャラクターに会う":
            jump meet_characters

label learn_story:
    alice "ここからあなたの素晴らしいストーリーが始まります！"
    alice "分岐パスを持つ複雑な物語を作ることができます。"
    narrator "'jump'を使ってストーリーセクション間を移動します。"
    jump continue_story

label explore_world:
    scene background_forest with fade
    alice "魔法の森へようこそ！"
    alice "シーンはスムーズなトランジションで背景を変更できます。"
    jump continue_story

label meet_characters:
    hide alice with fade
    show bob normal at left with fade
    bob "やあ！僕はボブ、アリスの友達だよ。"
    
    show alice happy at right with fade
    alice "キャラクターは必要に応じて表示・非表示できます！"
    jump continue_story

label continue_story:
    narrator "これはあなたのビジュアルノベルジャーニーの始まりに過ぎません。"
    narrator "より高度な機能についてはドキュメントをチェックしてください！"
```

## ステップ 4: メインシーンの作成

1. 新しいシーンを作成（`Scene → New Scene`）
2. `Control` ノードをルートとして追加し、`Main.tscn` として保存
3. Controlノードにこのスクリプトをアタッチ：

```gdscript
extends Control

func _ready():
    # Argodeを初期化してスクリプトを読み込み
    if ArgodeSystem:
        ArgodeSystem.load_and_play_script("res://scenarios/story.rgd", "start")
    else:
        print("ArgodeSystemが見つかりません！オートロードに設定されているか確認してください。")
```

## ステップ 5: メインシーンとして設定

1. **プロジェクト設定** に移動
2. **メインシーン** を作成した `Main.tscn` に設定
3. **F5** を押してビジュアルノベルを実行！

## 完成したもの

おめでとうございます！以下の要素を含む完全なビジュアルノベルを作成しました：

- ✅ **キャラクター定義** 名前と色付き
- ✅ **ダイアログシステム** キャラクターポートレート付き
- ✅ **選択肢メニュー** プレイヤーインタラクション用
- ✅ **シーントランジション** 背景変更付き
- ✅ **分岐ナラティブ** ラベルとジャンプ付き

## 次のステップ

さらに深く探求する準備はできましたか？これらのトピックを探索してください：

### 🎨 **ビジュアル強化**
- [キャラクターの表情と位置設定](../script/commands.ja.md#show)
- [背景トランジションとエフェクト](../script/commands.ja.md#scene)
- [カスタムUIテーマ](../ui/themes.ja.md)

### 🎯 **インタラクティビティ追加**
- [変数と条件ロジック](../script/variables.ja.md)
- [セーブ・ロードシステム](../advanced/save-system.ja.md)
- [エフェクト用カスタムコマンド](../custom-commands/creating.ja.md)

### 📚 **サンプル学習**
- [シンプルなビジュアルノベル](../examples/simple-vn.ja.md)
- [高度な機能デモ](../examples/custom-features.ja.md)
- [ベストプラクティスガイド](../examples/best-practices.ja.md)

---

**トラブル？** [トラブルシューティングガイド](../advanced/debugging.ja.md)をチェックするか、Discordコミュニティに参加してください！

[インストール詳細へ続く →](installation.ja.md){ .md-button }
[スクリプトリファレンスを見る →](../script/rgd-syntax.ja.md){ .md-button }
