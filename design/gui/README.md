# GUI サンプル

このフォルダには、Ren' Gd ADVエンジンを使用するためのサンプルUIが含まれています。

## ファイル構成

- `AdvGameUI.tscn` - サンプルUIシーン
- `AdvGameUI.gd` - UIロジック
- `usage_sample.tscn` - 使用方法のサンプルシーン
- `README.md` - この説明ファイル

## 使用方法

### 1. 基本的な使い方

1. `AdvGameUI.tscn`をあなたのメインシーンにインスタンス化
2. `setup_ui_manager_integration()`を呼び出してUIManagerと連携
3. ADVエンジンが自動的にUIを更新

### 2. カスタマイズ

このサンプルUIは自由にカスタマイズできます：

- **色・フォント**: テーマを変更してスタイルを調整
- **レイアウト**: パネルやラベルの位置・サイズを変更
- **アニメーション**: Tween を使って表示・非表示効果を追加
- **エフェクト**: シェーダーや粒子効果を追加

### 3. UIManagerとの連携

UIManagerは以下の要素を使用します：

```gdscript
# UIManagerに必要な要素
ui_manager.name_label = name_label      # キャラクター名表示
ui_manager.text_label = message_label   # メッセージ表示（RichTextLabel推奨）
ui_manager.choice_container = choice_vbox # 選択肢ボタンの親ノード
```

### 4. 主要機能

- **メッセージ表示**: キャラクター名とメッセージを表示
- **選択肢表示**: 動的にボタンを生成・削除
- **RichText対応**: 色、太字、斜体などの装飾が可能
- **キーボード対応**: Enterキーでメッセージ送り
- **マウス対応**: ボタンクリックで選択肢選択

### 5. シーンのインポート手順

1. あなたのプロジェクトに `AdvGameUI.tscn` をコピー
2. メインシーンで以下のように使用：

```gdscript
# MainScene.gd
extends Node2D

@onready var ui = $AdvGameUI  # UIシーンを追加

func _ready():
    # UIManagerと連携
    ui.setup_ui_manager_integration()
    
    # ADVエンジン開始
    AdvScriptPlayer.load_script("res://scenarios/your_script.rgd")
    AdvScriptPlayer.play_from_label("start")
```

## カスタマイズ例

### テーマの変更
```gdscript
# 背景色を変更（StyleBoxを取得して変更）
var style = message_panel.get_theme_stylebox("panel").duplicate()
style.bg_color = Color.BLUE
message_panel.add_theme_stylebox_override("panel", style)

# フォントサイズを変更
message_label.add_theme_font_size_override("normal_font_size", 20)
```

### アニメーション追加
```gdscript
func show_message_animated(text: String):
    var tween = create_tween()
    tween.tween_property(message_box, "modulate:a", 0.0, 0.0)
    tween.tween_property(message_box, "modulate:a", 1.0, 0.3)
```

このサンプルを基に、あなたのゲームに最適なUIを作成してください！