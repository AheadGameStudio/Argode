# クイックスタートガイド

わずか数分でArgodeを動かしましょう！このガイドでは、最初のビジュアルノベルシーンの作成方法をご案内します。

## 前提条件

- **Godot Engine 4.0+** ([こちらからダウンロード](https://godotengine.org/))
- **Godotプロジェクトの基本的な知識**





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
        ArgodeSystem.start_script("res://scenarios/story.rgd", "start")
    else:
        print("ArgodeSystemが見つかりません！オートロードに設定されているか確認してください。")
```



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

詳細なセットアップ手順については、以下を参照してください：

[インストールガイド →](installation.ja.md){ .md-button }
[基本セットアップガイド →](basic-setup.ja.md){ .md-button }
