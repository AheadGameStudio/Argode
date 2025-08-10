# Argode v2 GUI

このフォルダには、**Argode v2アドオン**を使用するためのサンプルUIが含まれています。

## ファイル構成

- `AdvGameUI.tscn` - ArgodeScreenベースのサンプルUIシーン
- `AdvGameUI.gd` - 最小限のUI実装（ArgodeScreen継承）
- `README.md` - この説明ファイル

## v2での変更点

### 🎯 **自動化された機能**

v2では以下の機能が**ArgodeScreen基底クラス**で自動提供されます：

- ✅ **UI要素の自動発見** - NodePath export + 自動フォールバック
- ✅ **TypewriterTextの自動初期化** - タイプライター効果
- ✅ **UIManager統合** - 手動連携不要
- ✅ **カスタムコマンド接続** - 動的シグナル自動接続
- ✅ **レイヤーマッピング** - 背景・キャラクター・UIレイヤー
- ✅ **自動スクリプト実行** - エディタで設定可能

### 📝 **使用方法（v2）**

1. **ArgodeScreenを継承** してプロジェクト固有UIを作成
2. **@export NodePath** でUI要素を指定（またはフォールバック名使用）
3. **auto_start_script = true** で自動実行設定
4. **すべての機能が自動提供される**

```gdscript
# AdvGameUI.gd - 最小限の実装例
extends "res://addons/argode/ui/ArgodeScreen.gd"
class_name AdvGameUI

func _ready():
    # 基本設定のみ
    auto_start_script = true
    default_script_path = "res://scenarios/main.rgd"
    start_label = "start"
    
    super._ready()  # 親クラスが全自動処理
```

### 🎛️ **UI要素のNodePath設定**

エディタのインスペクターで柔軟に設定可能：

```gdscript
@export_group("UI Element Paths")
@export var message_box_path: NodePath = ""      # 空なら"MessageBox"を自動発見
@export var name_label_path: NodePath = ""       # 空なら"NameLabel"を自動発見
@export var message_label_path: NodePath = ""    # 空なら"MessageLabel"を自動発見
@export var choice_container_path: NodePath = "" # 空なら"ChoiceContainer"を自動発見
# など...
```

### 🗺️ **レイヤーマッピング**

```gdscript
@export_group("Layer Paths")
@export var background_layer_path: NodePath = ""  # BackgroundLayer自動発見
@export var character_layer_path: NodePath = ""   # CharacterLayer自動発見

# 実行時に自動設定
layer_mappings = {
    "background": BackgroundLayer,
    "character": CharacterLayer, 
    "ui": self
}
```

### 🎮 **カスタムコマンド統合**

動的シグナルを自動受信：

```gdscript
func on_dynamic_signal_emitted(signal_name: String, args: Array, source_command: String):
    # カスタムコマンドからのシグナルを自動受信
    match signal_name:
        "custom_project_signal":
            # プロジェクト固有の処理
            pass
```

## v1からv2への移行

### ❌ **v1で必要だった処理（不要になった）**

```gdscript
# v1 - 手動で必要だった処理
func _ready():
    setup_ui_manager_integration()  # 不要
    connect_to_adv_system()         # 不要
    initialize_typewriter()         # 不要
    setup_input_handling()          # 不要
    configure_layers()              # 不要
```

### ✅ **v2では自動処理**

```gdscript
# v2 - すべて自動
func _ready():
    auto_start_script = true  # これだけで全自動
    super._ready()
```

## ディレクトリ構成

```
src/scenes/gui/
├── AdvGameUI.tscn     # ArgodeScreenベースのUIシーン
├── AdvGameUI.gd       # 最小限の継承実装
└── README.md          # この説明（v2対応）

addons/argode/ui/
└── ArgodeScreen.gd    # すべての機能を提供する基底クラス
```

## カスタマイズ

### 🎨 **UI要素のカスタマイズ**

1. **AdvGameUI.tscn**でレイアウト調整
2. **@export NodePath**でパス指定
3. **virtual method**をオーバーライド

```gdscript
func on_screen_ready():
    # 初期化完了時の処理
    pass

func on_character_typed(character: String, position: int):
    # タイプライター文字入力時の処理
    pass

func on_dynamic_signal_emitted(signal_name: String, args: Array, source_command: String):
    # カスタムコマンドシグナル受信時の処理
    pass
```

**Argode v2**では、ほとんどの機能が自動化され、プロジェクト固有の最小限のコードだけで高機能なADVゲームUIが実現できます！