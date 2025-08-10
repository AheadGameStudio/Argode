# Argode v2 カスタムコマンドガイド

このフォルダ（`custom/commands/`）に**BaseCustomCommand**を継承したクラスを配置すると、**自動で発見・登録**されます。

## 🚀 **自動発見システム**

**手動登録は不要！** ファイルを置くだけで自動的に使用可能になります：

```
custom/commands/
├── MyCustomCommand.gd      ← 自動発見・登録
├── ScreenFlashCommand.gd   ← 自動発見・登録  
├── WindowCommand.gd        ← 自動発見・登録
└── YourNewCommand.gd       ← 追加すると自動発見
```

## 📝 **基本的なカスタムコマンドの作り方**

### 1. **BaseCustomCommandを継承**

```gdscript
# custom/commands/YourNewCommand.gd
extends BaseCustomCommand
class_name YourNewCommand

func _init():
    command_name = "your_command"  # シナリオで使用する名前
    description = "Your custom command description"

func execute(params: Dictionary, adv_system: Node) -> bool:
    # パラメータ取得
    var text = get_param_value(params, "text", "arg0", "Hello!")
    var duration = get_param_value(params, "duration", "arg1", 2.0)
    
    print("🎯 Your command executed: ", text, " for ", duration, "s")
    
    # 必要に応じて処理
    # return true  # 同期処理（スクリプト一時停止）
    return false   # 非同期処理（スクリプト継続）
```

### 2. **シナリオファイルで使用**

```rgd
# scenarios/your_script.rgd
label start:
    "通常のメッセージです"
    
    # カスタムコマンド実行
    your_command text="カスタム効果!" duration=3.0
    
    "カスタムコマンドの後のメッセージです"
```

## 🎛️ **パラメータの扱い方**

### **混合パラメータ対応**

```gdscript
# 位置パラメータ + key=value 形式をサポート
func execute(params: Dictionary, adv_system: Node) -> bool:
    # 位置パラメータ（arg0, arg1, ...）
    var arg0 = get_param_value(params, "missing_key", "arg0", "default")
    
    # 名前付きパラメータ
    var intensity = get_param_value(params, "intensity", -1, 1.0)  
    var duration = get_param_value(params, "duration", -1, 2.0)
    
    # 両方に対応
    var message = get_param_value(params, "message", "arg0", "Default message")
```

### **シナリオでの呼び出し例**

```rgd
# 位置パラメータ
your_command "Hello" 3.0

# 名前付きパラメータ  
your_command intensity=2.5 duration=1.0 message="Test"

# 混合
your_command "Hello" duration=2.0 intensity=3.0
```

## 🎨 **高度なカスタムコマンドの例**

### **UI操作コマンド**

```gdscript
extends BaseCustomCommand
class_name UIEffectCommand

func _init():
    command_name = "ui_effect"
    description = "UI visual effects"

func execute(params: Dictionary, adv_system: Node) -> bool:
    var effect = get_param_value(params, "effect", "arg0", "fade")
    var target = get_param_value(params, "target", "arg1", "message_box")
    
    match effect:
        "shake":
            _shake_ui_element(target, adv_system)
        "fade":
            _fade_ui_element(target, adv_system)
        "pulse":
            _pulse_ui_element(target, adv_system)
    
    return false  # 非同期実行
```

### **同期処理（waitコマンド系）**

```gdscript
extends BaseCustomCommand
class_name WaitCommand

func _init():
    command_name = "wait"
    description = "Wait for specified duration"

func execute(params: Dictionary, adv_system: Node) -> bool:
    var duration = get_param_value(params, "duration", "arg0", 1.0)
    
    print("⏳ Waiting for ", duration, " seconds...")
    
    # タイマー作成
    await adv_system.get_tree().create_timer(duration).timeout
    
    print("✅ Wait completed!")
    return true  # 同期処理（スクリプト停止して完了を待つ）
```

## 🔧 **自動発見の仕組み**

ArgodeSystemが起動時に以下をチェック：

1. **`res://custom/commands/` スキャン**
2. **`.gd` ファイルを検出**
3. **`extends BaseCustomCommand` を含むかチェック**
4. **自動でインスタンス化・登録**

```
🔍 Scanning for commands in: res://custom/commands/
   🎯 Found custom command: YourNewCommand.gd
✅ Registered custom command: your_command
```

## 📋 **現在登録されているコマンド**

システム起動時に以下のようなログが表示されます：

```
✅ Registered custom command: async_effect
✅ Registered custom command: camera_shake  
✅ Registered custom command: hello_world
✅ Registered custom command: my_effect
✅ Registered custom command: particles
✅ Registered custom command: screen_flash
✅ Registered custom command: wait
✅ Registered custom command: window
📝 Auto-registration completed: 8 commands registered
```

## ⚡ **ベストプラクティス**

### **DO（推奨）**
- ✅ **BaseCustomCommand継承**
- ✅ **class_name指定**で再利用可能に
- ✅ **command_name設定**でシナリオから呼び出し
- ✅ **get_param_value()使用**で安全なパラメータ取得
- ✅ **適切なreturn値**（同期/非同期の判断）

### **DON'T（非推奨）**
- ❌ 手動登録スクリプト作成
- ❌ autoloadに追加
- ❌ 直接パラメータ辞書アクセス
- ❌ エラーハンドリング無し

**Argode v2では、ファイルを置くだけでカスタムコマンドが使えます！**