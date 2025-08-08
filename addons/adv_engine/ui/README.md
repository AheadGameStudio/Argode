# BaseAdvGameUI - ADVゲーム用ベースUIクラス

## 概要

`BaseAdvGameUI`は、ADVゲーム（アドベンチャーゲーム）用の汎用ベースUIクラスです。
タイプライター効果、メッセージ表示、選択肢表示などの基本機能を提供します。

## 使い方

### 1. 基本的な使用方法

```gdscript
extends BaseAdvGameUI
class_name MyGameUI

# 初期化処理をオーバーライド
func initialize_ui():
    # 独自の初期化処理
    show_message("システム", "ゲームを開始します！", Color.WHITE)
```

### 2. シーンでの使用

1. 新しいシーンを作成
2. `res://addons/adv_engine/ui/BaseAdvGameUI.tscn`をインスタンス化
3. 独自のスクリプトを作成して継承

### 3. 主な機能

#### メッセージ表示
```gdscript
# キャラクター名、メッセージ、名前の色
show_message("主人公", "こんにちは！", Color.CYAN)
```

#### 選択肢表示
```gdscript
var choices = ["はい", "いいえ", "わからない"]
show_choices(choices)
```

#### タイプライター制御
```gdscript
# タイプライター中かチェック
if typewriter.is_typing_active():
    # スキップ処理
    typewriter.skip_typing()
```

## カスタマイズ

### オーバーライド可能なメソッド

- `initialize_ui()`: UI初期化処理
- `_on_choice_selected(choice_index: int)`: 選択肢選択時の処理
- `_on_character_typed(character: String, position: int)`: 文字タイプ時の処理

### 利用可能なシグナル

- `typewriter_started(text: String)`: タイプライター開始
- `typewriter_finished()`: タイプライター完了
- `typewriter_skipped()`: タイプライタースキップ
- `character_typed(character: String, position: int)`: 文字タイプ

## ファイル構成

- `BaseAdvGameUI.gd`: ベースクラス実装
- `BaseAdvGameUI.tscn`: UIシーンファイル
- `README.md`: 使用方法説明

## 依存関係

- `TypewriterText`: タイプライター機能
- Godot 4.x