# Argodeレイヤーシステム使用ガイド

## 🎨 レイヤー構造の理解

### 推奨シーン構造

```
Main (Node2D または Control)
├── BackgroundLayer (Control) [z_index: 0]   ← 背景画像専用
├── CharacterLayer (Control)  [z_index: 100] ← キャラクター立ち絵専用  
└── GameUI (ArgodeScreen)     [z_index: 200] ← UIレイヤー（メッセージ・選択肢等）
    ├── MessageBox (Control)
    ├── ChoiceContainer (Control)
    └── ... (その他UI要素)
```

## 🚀 自動展開モードの使用方法

### ArgodeScreenでの設定

```gdscript
# GameUI.gd (ArgodeScreenを継承)
extends ArgodeScreen

# エディタで設定
@export var auto_create_layers: bool = true  # ← これをONにする
```

### 手動でのレイヤー作成

```gdscript
# メインシーンの_ready()で実行
func _ready():
    var layers = AutoLayerSetup.create_argode_layers(self)
    # layers["background"], layers["character"], layers["ui"] が使用可能
```

## 🎯 ArgodeScreenの配置パターン

### パターン1: ArgodeScreen = UIレイヤー（推奨）
```
Main
├── BackgroundLayer (自動作成)
├── CharacterLayer (自動作成)
└── GameUI (ArgodeScreen) ← これ自体がUIレイヤー
```

### パターン2: ArgodeScreenを別レイヤー内に配置
```
Main  
├── BackgroundLayer
├── CharacterLayer
└── UILayer
    └── GameUI (ArgodeScreen) ← UIレイヤー内に配置
```

## ⚙️ レイヤー管理のベストプラクティス

### Z-Index値の標準

- **Background Layer**: 0-99
- **Character Layer**: 100-199  
- **UI Layer**: 200-299
- **Overlay/Effect**: 300+

### Control vs CanvasLayer

**Control を使用する理由：**
- ✅ アンカー・マージンでレスポンシブレイアウト
- ✅ 細かいZ-Index制御
- ✅ シェーダー効果の適用が容易
- ✅ レイアウト管理が直感的

**CanvasLayer は以下の場合のみ：**
- 独立したカメラ制御が必要
- 異なる描画順序が必要
- パフォーマンス最適化が重要

## 🔧 カスタムレイヤーの追加

### 追加レイヤーの作成例

```gdscript
# エフェクトレイヤーを追加
func add_effect_layer():
    var effect_layer = Control.new()
    effect_layer.name = "EffectLayer"
    effect_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    effect_layer.z_index = 300
    effect_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    
    get_parent().add_child(effect_layer)
    
    # LayerManagerに登録
    var layer_map = get_layer_mappings()
    layer_map["effects"] = effect_layer
```

## 💡 トラブルシューティング

### よくある問題

1. **レイヤーが表示されない**
   - Z-Indexの重複チェック
   - 親ノードのvisibilityチェック

2. **UIが背景に隠れる**
   - UIレイヤーのZ-Indexを200以上に設定

3. **キャラクターが背景と同じ深度**
   - CharacterLayerのZ-Indexを100に設定

4. **マウスイベントが通らない**  
   - `mouse_filter = Control.MOUSE_FILTER_IGNORE` を設定
