# 🚀 Argode v1.2.0 Universal Block Execution Architecture

## 📋 概要

Argode v1.2.0の核心設計思想：**Universal Block Execution + Command Self-Management**
ExecutionServiceによる汎用ブロック実行エンジンと、コマンド自己管理による拡張性の両立を実現。

---

## 🎯 設計哲学の大転換

### **従来の設計問題**
```gdscript
# ❌ StatementManagerによる個別制御（旧設計）
StatementManager:
    - _handle_jump_via_services()     # Jump専用処理
    - _handle_call_via_services()     # Call専用処理  
    - _handle_menu_via_services()     # Menu専用処理
    - _handle_return_via_services()   # Return専用処理
    # → 850行の巨大クラス、拡張性の低下
```

### **✅ 新設計：Universal Block Execution**
```gdscript
# ✅ StatementManager：シンプルなインフラ（200行目標）
StatementManager:
    + execute_block()      # 汎用ブロック実行（すべてに適用）
    + parse_label_block()  # ラベルブロック解析
    + show_message()       # メッセージ表示
    # → 汎用インフラのみ提供

# ✅ 各コマンド：自己完結型実装
JumpCommand: 自分でStatementManager.execute_block()を使用
CallCommand: 自分でスタック管理 + execute_block()を使用
MenuCommand: 自分で選択肢処理 + execute_block()を使用
```

### **核心的な設計洞察**
> **"ラベル実行やコール・メニュー実行のハンドラを用意するの？ブロック実行という抽象化・汎用化した考えで出来るのでは？"**
> 
> **"個別に何かそういったミクロな機能を持たせたいなら、コマンドが自分で管理したらいいと思うんだよね"**

---

## 🏗️ Universal Block Execution Engine

### **ExecutionService: 汎用ブロック実行エンジン**
```gdscript
class ArgodeExecutionService:
    # 🎯 すべての実行タイプに対応する汎用エンジン
    func execute_block(statements: Array, context: Dictionary = {}) -> void:
        """
        汎用ブロック実行：
        - main実行（最上位シナリオ）
        - label実行（Jumpコマンド）
        - call実行（Callコマンド）
        - menu実行（MenuコマンドのChoice）
        すべて同じロジックで処理
        """
        for statement in statements:
            match statement.type:
                "say": handle_say_statement(statement)
                "command": handle_command_statement(statement)
                # すべて統一処理
    
    func execute_statement(statement: Dictionary) -> void:
        # 個別ステートメント実行（汎用）
    
    func execute_regular_command(command_name: String, args: Dictionary) -> void:
        # コマンド実行（汎用）
```

### **StatementManager: Pure Infrastructure（200行目標）**
```gdscript
class ArgodeStatementManager:
    # 🎯 コマンドが使用する汎用インフラのみ提供
    
    # === 汎用ブロック実行API ===
    func execute_block(statements: Array, context: Dictionary = {}) -> void:
        execution_service.execute_block(statements, context)
    
    # === ラベル解析API ===
    func parse_label_block(label_name: String) -> Array:
        var label_info = ArgodeSystem.LabelRegistry.get_label_info(label_name)
        return ArgodeSystem.RGDParser.parse_label_block(label_info)
    
    # === メッセージ表示API ===
    func show_message(text: String, character: String = "") -> void:
        ui_control_service.show_message(text, character)
    
    # === カスタムコマンド向け統一API ===
    func play_from_label(label_name: String) -> bool
    func get_variable(name: String) -> Variant
    func set_variable(name: String, value: Variant) -> void
    func pause_execution(reason: String = "") -> void
    func resume_execution() -> void
    
    # 🚫 個別ハンドラは完全廃止
    # func _handle_jump_via_services()    # 削除
    # func _handle_call_via_services()    # 削除
    # func _handle_menu_via_services()    # 削除
```

---

## 🎮 Command Self-Management Pattern

### **JumpCommand: 自己完結型実装**
```gdscript
class JumpCommand extends ArgodeCommandBase:
    func execute(args: Dictionary) -> void:
        var label_name = args.get("0", "start")
        
        # 1. 自分でラベルブロックを取得
        var statements = statement_manager.parse_label_block(label_name)
        
        # 2. 汎用インフラで実行開始
        statement_manager.execute_block(statements, {"jump_context": true})
        
        # StatementManagerは個別Jump処理を持たない
```

### **CallCommand: 自己完結型実装**
```gdscript
class CallCommand extends ArgodeCommandBase:
    static var call_stack: Array = []  # 自分でスタック管理
    
    func execute(args: Dictionary) -> void:
        var label_name = args.get("0", "")
        
        # 1. 自分で戻り先をスタックに保存
        call_stack.push_back({
            "return_position": execution_service.current_position,
            "return_context": execution_service.current_context
        })
        
        # 2. 自分でラベルブロックを取得
        var statements = statement_manager.parse_label_block(label_name)
        
        # 3. 汎用インフラで実行開始
        statement_manager.execute_block(statements, {"call_context": true})
```

### **ReturnCommand: 自己完結型実装**
```gdscript
class ReturnCommand extends ArgodeCommandBase:
    func execute(args: Dictionary) -> void:
        # 1. 自分でスタックから戻り先を取得
        if CallCommand.call_stack.is_empty():
            ArgodeSystem.log_error("Return without Call")
            return
        
        var return_info = CallCommand.call_stack.pop_back()
        
        # 2. 汎用インフラで戻り先実行再開
        execution_service.resume_from_position(return_info.return_position)
```

### **MenuCommand: 自己完結型実装**
```gdscript
class MenuCommand extends ArgodeCommandBase:
    func execute(args: Dictionary) -> void:
        # 1. 自分で選択肢を表示
        var choices = args.get("choices", [])
        var selected = await ui_manager.show_menu(choices)
        
        # 2. 自分で選択されたブロックを取得
        var choice_statements = selected.statements
        
        # 3. 汎用インフラで選択肢ブロック実行
        statement_manager.execute_block(choice_statements, {"menu_context": true})
        
        # 4. 選択肢完了後、メイン実行を継続
        execution_service.continue_main_execution()
```

---

## 📊 Architecture Benefits

### **🎯 コード量の激減**
```
旧StatementManager: 850行
  ├─ Jump処理: 100行
  ├─ Call処理: 150行  
  ├─ Menu処理: 120行
  ├─ Return処理: 80行
  └─ その他: 400行

新StatementManager: 200行
  ├─ execute_block(): 汎用処理
  ├─ parse_label_block(): 汎用解析
  ├─ show_message(): 汎用表示
  └─ 統一API: カスタムコマンド向け
```

### **🚀 拡張性の飛躍的向上**
```gdscript
# ✅ カスタムコマンド開発者の視点
class MyCustomCommand extends ArgodeCommandBase:
    func execute(args: Dictionary) -> void:
        # StatementManagerの汎用インフラを使うだけ
        var statements = statement_manager.parse_label_block("my_label")
        statement_manager.execute_block(statements)
        
        # 個別の複雑なService階層を理解する必要なし
```

### **🔧 保守性の向上**
- **Single Responsibility**: 各コマンドが自分の責任のみ持つ
- **Unified Interface**: すべてexecute_block()統一
- **Simple Testing**: コマンド単位でのテスト容易
- **Clear Debugging**: 問題のあるコマンドを特定しやすい

---

## 🔄 Migration Status

### **✅ 完了した変更**
- [x] **ExecutionService**: 汎用execute_block()エンジン実装
- [x] **CallCommand**: 超シンプル化（静的スタック + Jump統一）
- [x] **ReturnCommand**: 自己完結型実装  
- [x] **MenuCommand**: Choice自己管理実装

### **🔄 移行中の項目**
- [ ] **StatementManager**: 個別ハンドラ削除（850行 → 200行）
  - [ ] `_handle_jump_via_services()` 削除
  - [ ] `_handle_call_via_services()` 削除
  - [ ] `_handle_menu_via_services()` 削除
  - [ ] `_handle_return_via_services()` 削除
- [ ] **JumpCommand**: 完全自己完結型実装

### **🎯 最終アーキテクチャ目標**
```
ArgodeStatementManager (200行)
├─ execute_block() ← すべてのコマンドが使用
├─ parse_label_block() ← すべてのコマンドが使用
├─ show_message() ← Sayコマンドが使用
└─ Unified APIs ← カスタムコマンドが使用

Individual Commands (各50-100行)
├─ JumpCommand: 自己完結
├─ CallCommand: 自己完結 + 静的スタック
├─ ReturnCommand: 自己完結
├─ MenuCommand: 自己完結
└─ CustomCommands: 汎用インフラ使用
```

---

## 💡 Key Design Insights

### **Universal Block Execution原理**
> すべての実行（main/label/call/menu）は本質的に「ステートメント配列の順次実行」である。
> 個別のハンドラは不要で、execute_block()一つで全てカバーできる。

### **Command Self-Management原理**
> コマンドは自分の機能を自分で管理すべき。StatementManagerは汎用インフラを提供するのみ。
> 拡張性とシンプルさを両立する最適解。

### **設計の一貫性**
> ArgodeCommandBase継承によりすべてのコマンドが統一インターフェース。
> 新規カスタムコマンドも同じパターンで開発可能。

---

**作成日**: 2025年8月23日  
**対象バージョン**: Argode v1.2.0  
**設計思想**: Universal Block Execution + Command Self-Management  
**目標**: StatementManager 200行、拡張性最大化、保守性向上
