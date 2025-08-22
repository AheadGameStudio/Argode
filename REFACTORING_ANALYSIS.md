# 🔍 StatementManager肥大化問題　詳細分析レポート

## 📊 現状分析

### **基本情報**
- **現在の行数**: 782行（目標200行の391%）
- **関数数**: 47個（推定）
- **Service Layer Pattern実装済み**: ✅ 

### **🚨 肥大化の原因分析**

#### **1. 本来Serviceに分離すべき機能がStatementManagerに残存**

**メッセージ表示関連（約200行）**:
```gdscript
func _ensure_message_system_ready()          # L519 - UIManager連携
func _try_fallback_message_display()        # L531 - フォールバック処理
func _create_default_message_window()       # L542 - デフォルトウィンドウ作成
func _create_message_renderer()              # L563 - レンダラー作成
func _on_message_rendering_completed()       # L589 - 完了コールバック
func _display_message_via_window()           # L600 - ウィンドウ表示（48行）
```

**Definition実行関連（約100行）**:
```gdscript
func execute_definition_statements()         # L669 - 定義文実行（42行）
func _execute_definition_statement_fallback() # L712 - フォールバック（50行）
```

**Typewriter制御関連（約30行）**:
```gdscript
func pause_typewriter()                     # L763
func resume_typewriter()                    # L768  
func push_typewriter_speed()                # L773
func pop_typewriter_speed()                 # L778
func get_current_typewriter_speed()         # L783
```

#### **2. Service Layerが機能していない**

**Service初期化の問題**:
```gdscript
# L55-67: _initialize_services()
# Services作成はしているが、実際の処理は全てStatementManagerに残存
```

**本来の設計意図との乖離**:
- Serviceクラスは作成済み
- しかし機能移譲が不十分
- StatementManagerが依然として「何でもできるクラス」

### **📋 機能別責任分析**

#### **🟢 適切にStatementManagerに残すべき機能**
```gdscript
- play_from_label()                    # 公開API
- pause_execution() / resume_execution() # 実行制御API  
- get_variable() / set_variable()      # 変数API
- handle_command_result()              # コマンド結果処理
- push_call_context() / pop_call_context() # 呼び出しスタック
```
**推定行数**: 約150行

#### **🔴 Serviceに移譲すべき機能**

**1. UIControlServiceに移譲すべき（約250行）**:
```gdscript
- _ensure_message_system_ready()
- _try_fallback_message_display()  
- _create_default_message_window()
- _create_message_renderer()
- _display_message_via_window()
- pause_typewriter() / resume_typewriter()
- push_typewriter_speed() / pop_typewriter_speed()
```

**2. ExecutionServiceに移譲すべき（約200行）**:
```gdscript
- _execute_main_loop()               # メイン実行ループ（70行）
- _execute_single_statement()        # 単文実行
- _execute_command_via_services()    # コマンド実行
- _handle_text_statement()           # テキスト文処理
```

**3. DefinitionServiceに移譲すべき（約150行）**:
```gdscript
- execute_definition_statements()
- _execute_definition_statement_fallback()
```

**4. InputHandlerServiceに移譲すべき（約50行）**:
```gdscript
- _on_valid_input_received()         # 入力処理（33行）
```

## 🎯 段階的リファクタリング計画

### **Phase 1: Serviceクラス機能拡張（安全性重視）**

#### **Step 1-1: UIControlService機能移譲**
```gdscript
# 移譲対象
ArgodeUIControlService {
  + ensure_message_system_ready()
  + create_default_message_window()  
  + create_message_renderer()
  + display_message_via_window()
  + control_typewriter_speed()
}

# StatementManagerから削除予定
- _ensure_message_system_ready() (~12行)
- _create_default_message_window() (~21行)  
- _create_message_renderer() (~26行)
- _display_message_via_window() (~48行)
- pause_typewriter()等 (~25行)
```
**削減効果**: -132行

#### **Step 1-2: ExecutionService機能移譲**
```gdscript
# 移譲対象  
ArgodeExecutionService {
  + execute_main_loop()
  + execute_single_statement()
  + execute_command_via_services()
  + handle_text_statement()
}

# StatementManagerから削除予定
- _execute_main_loop() (~70行)
- _execute_single_statement() (~14行)
- _execute_command_via_services() (~28行)  
- _handle_text_statement() (~6行)
```
**削減効果**: -118行

#### **Step 1-3: 新規DefinitionService作成**
```gdscript
# 新規作成
ArgodeDefinitionService {
  + execute_definition_statements()
  + execute_definition_fallback()
}

# StatementManagerから削除予定
- execute_definition_statements() (~42行)
- _execute_definition_statement_fallback() (~50行)
```
**削減効果**: -92行

### **Phase 2: StatementManager API統一化**

#### **Step 2-1: Service呼び出し統一**
```gdscript
# StatementManager最終形（目標150行）
class ArgodeStatementManager {
  # 公開API層（カスタムコマンド向け）
  func play_from_label(label_name: String) -> bool
  func pause_execution(reason: String = "")
  func resume_execution()
  func get_variable(name: String)
  func set_variable(name: String, value)  
  func show_message(text: String, character: String = "")
  func handle_command_result(result_data: Dictionary)
  
  # 内部Service呼び出し統括
  func _delegate_to_execution_service()
  func _delegate_to_ui_control_service()
  func _delegate_to_definition_service()
}
```

#### **Step 2-2: 機能テスト・承認**
- 各Step完了後にユーザーテスト実施
- 既存機能の完全互換性確認
- カスタムコマンドAPI影響なし確認

## 📈 期待効果

### **削減効果予測**
```
現在: 782行
Step 1-1: 782 - 132 = 650行 (17%削減)
Step 1-2: 650 - 118 = 532行 (32%削減)  
Step 1-3: 532 - 92 = 440行 (44%削減)
最終調整: 440 - 240 = 200行 (目標達成)
```

### **設計品質向上**
- **単一責任の原則**: 各Service専門特化
- **拡張性**: カスタムコマンド向け統一API維持
- **保守性**: 機能別クラス分離による理解容易性
- **テスト性**: Service単位での単体テスト可能

## ⚠️ リスク管理

### **高リスク作業**
1. **メッセージ表示系移譲**: UI連携の複雑性
2. **実行ループ移譲**: コア機能のため慎重に
3. **Definition処理移譲**: 初期化処理との連携

### **安全対策**
1. **段階的実施**: Step完了毎にテスト・承認
2. **バックアップ**: `.gd.backup`形式での保存
3. **機能テスト**: 既存シナリオでの動作確認
4. **ロールバック計画**: 各Step毎の復旧手順準備

## 🚀 実施スケジュール提案

| Phase | Step | 作業内容 | 予想工数 | リスク |
|-------|------|----------|----------|--------|
| 1 | 1-1 | UIControlService機能移譲 | 2-3時間 | 中 |
| 1 | 1-2 | ExecutionService機能移譲 | 3-4時間 | 高 |  
| 1 | 1-3 | DefinitionService作成・移譲 | 2-3時間 | 中 |
| 2 | 2-1 | StatementManager API統一 | 1-2時間 | 低 |
| 2 | 2-2 | 総合テスト・最終調整 | 1-2時間 | 低 |

**総予想工数**: 9-14時間
**完了目標**: 1-2日間での段階的実施

---

**最終更新**: 2025/08/22 - StatementManager肥大化問題詳細分析完了
