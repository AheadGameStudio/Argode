# Argode v2 シェーダーベース視覚効果システム

## 概要

Argode v2では、レイヤー構造と組み合わせたシェーダーベースの高性能視覚効果システムを提供します。

## シェーダー効果の種類

### 1. **スクリーンフィルタ系**
- `screen_flash` - フラッシュ効果（色・強度・持続時間）
- `screen_fade` - フェードイン/アウト
- `screen_tint` - 画面全体の色調調整
- `screen_sepia` - セピア調効果
- `screen_grayscale` - グレースケール変換

### 2. **歪み・変形系**
- `screen_wave` - 波形歪み効果
- `screen_ripple` - 水面リップル効果
- `screen_spiral` - 螺旋歪み
- `screen_shake` - シェーダーベースの画面揺れ

### 3. **ブラー・ぼかし系**
- `screen_blur` - ガウシアンブラー
- `screen_motion_blur` - モーションブラー
- `screen_radial_blur` - 放射状ブラー

### 4. **特殊効果系**
- `screen_pixelate` - ピクセル化効果
- `screen_vignette` - ビネット効果
- `screen_chromatic` - 色収差効果

## レイヤー統合

### LayerManagerとの連携
```gdscript
# 特定レイヤーに効果を適用
layer_manager.apply_shader_effect("background", "blur", {"intensity": 2.0})
layer_manager.apply_shader_effect("ui", "fade", {"alpha": 0.5})

# 画面全体に効果を適用
layer_manager.apply_screen_effect("flash", {"color": Color.WHITE, "duration": 0.3})
```

### 効果の優先度
1. **UIレイヤー** (z_index: 200) - 最前面効果
2. **キャラクターレイヤー** (z_index: 100) - キャラクター効果
3. **背景レイヤー** (z_index: 0) - 背景効果
4. **スクリーン全体** - 画面全体効果

## シェーダーファイル構成

```
addons/argode/shaders/
├── screen_effects/
│   ├── flash.gdshader          # スクリーンフラッシュ
│   ├── fade.gdshader           # フェード効果
│   ├── tint.gdshader           # 色調調整
│   ├── blur.gdshader           # ブラー効果
│   └── wave.gdshader           # 波形歪み
├── layer_effects/
│   ├── character_glow.gdshader # キャラクター発光
│   ├── background_blur.gdshader# 背景ぼかし
│   └── ui_transition.gdshader  # UI遷移
└── utils/
    ├── ShaderEffectManager.gd  # シェーダー管理システム
    └── EffectController.gd     # 効果制御クラス
```

## カスタムコマンド統合

### v2対応カスタムコマンド例
```gdscript
# custom/commands/ScreenFlashShaderCommand.gd
extends BaseCustomCommand

func _init():
    command_name = "screen_flash"
    description = "Shader-based screen flash effect"

func execute_visual_effect(params: Dictionary, ui_node: Node) -> void:
    var color = get_param_value(params, "color", 0, Color.WHITE)
    var duration = get_param_value(params, "duration", 1, 0.3)
    
    # LayerManagerを通じてシェーダー効果を適用
    var layer_manager = ui_node.get_layer_manager()
    layer_manager.apply_screen_shader("flash", {
        "flash_color": color,
        "flash_intensity": 1.0,
        "duration": duration
    })
```

### シナリオでの使用例
```rgd
label start:
    "通常のメッセージです"
    
    # シェーダーベースエフェクト
    screen_flash color=white duration=0.2
    screen_blur intensity=2.0 duration=1.0
    screen_wave amplitude=0.05 frequency=2.0 duration=0.8
    
    "エフェクト後のメッセージです"
```

## パフォーマンス最適化

### シェーダーの利点
- **GPU並列処理**: CPUベースColorRectより高速
- **メモリ効率**: 動的ノード生成不要
- **レイヤー統合**: 既存のレイヤーシステムと完全統合
- **高品質**: 高度な視覚効果が可能

### キャッシュシステム
- **シェーダーキャッシュ**: 初回読み込み後はメモリに保持
- **パラメータプール**: 頻繁に使用するパラメータセットを事前計算
- **効果の結合**: 複数の効果を1つのシェーダーで処理

## 実装アーキテクチャ

### ShaderEffectManager
```gdscript
class_name ShaderEffectManager
extends Node

# シェーダー管理
var shader_cache: Dictionary = {}
var active_effects: Array[EffectController] = []

func apply_effect(target: Node, shader_name: String, params: Dictionary) -> EffectController
func remove_effect(target: Node, shader_name: String) -> bool
func clear_all_effects(target: Node) -> void
```

### LayerManager拡張
```gdscript
# LayerManager.gdに追加
var shader_effect_manager: ShaderEffectManager

func apply_layer_shader(layer_name: String, shader_name: String, params: Dictionary)
func apply_screen_shader(shader_name: String, params: Dictionary) 
func remove_layer_shader(layer_name: String, shader_name: String)
```

この設計により、**パフォーマンス向上**と**視覚効果の拡張**を同時に実現できます。