---
applyTo: '**'
---

## **プロジェクトの概要**

このプロジェクトは、Godot Engine (4.x系) を用いたビジュアルノベルゲームフレームワーク **Argode v1.2.0** の継続的改善を目的としています。GDScriptを中心に開発が行われています。

設計思想と完全なアーキテクチャは `Argode_v1_2_Complete_Architecture.md` に詳細記載されています。
必ず読んで理解してから開発を進めてください。

## **Argodeフレームワークの設計思想 (v1.2.0)**

### **1. Service Layer Pattern による高度なアーキテクチャ**

現在のArgodeは、Service Layer Pattern を基盤とした多層アーキテクチャを実装しています：

* **ArgodeSystem**: フレームワーク統括コア。マネージャー・サービス・レジストリのライフサイクル管理  
* **Manager Layer**: 統一API提供、後方互換性維持（StatementManager、DebugManager等）  
* **Service Layer**: 専門化されたビジネスロジック（ExecutionService、ContextService等）  
* **Registry Layer**: 高速検索インデックス（CommandRegistry、LabelRegistry等）  
* **Command Pattern**: 全命令の独立実装による拡張性確保

### **2. 現実的なリファクタリング方針**

* **品質優先**: 行数目標に固執せず、設計品質と機能安定性を最優先とします
* **段階的改善**: Service Layer への機能委譲を段階的に実施
* **互換性維持**: 既存機能の動作を保証しながら内部構造を改善
* **テスト駆動**: 各段階で必ずユーザーテストを実施し、承認を得てから次へ進行

### **3. Service Layer 委譲の具体的構造**

StatementManager（現在854行）は以下のService層に機能委譲しています：

* **ExecutionService**: 実行フロー制御・状態管理（146行）
* **ContextService**: ネストした実行コンテキスト管理（111行）
* **CallStackService**: Call/Return スタック専用処理（89行）
* **InputHandlerService**: 入力制御・待機状態管理
* **UIControlService**: UI制御とメッセージウィンドウ管理

### **4. 遅延パースとパフォーマンス最適化**

* 起動時: **Registry** が必要最小限の情報（ラベル・定義）のみ高速読み込み
* 実行時: **RGDParser** によるオンデマンド・階層化パース（573行）
* メモリ効率: 不要なデータ構造を保持しない設計

### **5. 拡張性とカスタマイゼーション（v1.2.0の核心目標）**

* **Command Pattern**: 全命令が `ArgodeCommandBase` 継承（182行）の独立クラス
* **Dynamic Loading**: `builtin/commands/` と `custom_commands/` からの自動発見
* **Tag System**: インラインコマンドの柔軟な拡張機能
* **独立開発可能性**: コマンドとして独立して開発でき、ArgodeSystemが汎用的に受け入れる構造

**v1.2.0の最重要事項**: ADVエンジンとしての最低限機能を**コマンドとして**実装可能な状態を実現し、ユーザーが容易にカスタムコマンドを追加できる基盤を確立する。

## **AIへの指示事項 (v1.2.0 更新版)**

### **1. 設計品質を最優先とする開発**

* 新しい機能やコードを提案する際は、**どのサービス・マネージャーがどの役割を担うべきか**を明確にしてください。  
* 行数目標（200行等）は参考値として扱い、**機能安定性と設計品質を優先**してください。
* Service Layer Pattern の恩恵を最大化する構造を提案してください。

### **2. リファクタリング計画の段階的実行**

* **Phase 1**: Service Layer への機能委譲強化（品質重視・行数は副次目標）
* **Phase 2**: API統一化（後方互換性維持）
* **Phase 3**: パフォーマンス最適化
* 各Phase完了時に必ずユーザーテストを実施し、承認後に次段階へ進行

### **3. 現実的なコード改善指針**

* **StatementManager**: 300-400行程度を現実的目標とし、コメント込みで機能完全性を重視
* **Service委譲**: 1つのServiceに5-15個程度のメソッド委譲を標準とする
* **エラーハンドリング**: 統一された例外処理とログ出力の実装
* **テスト容易性**: 各Serviceの独立性を保ち、テスト可能な構造を維持

### **4. GDScriptとGodot 4.xの最適活用**

* 提案するコードは、Godot 4.xの仕様とGDScriptの記法に準拠してください。  
* Service Layer Pattern に適した RefCounted クラスの活用を推奨します。
* Expressionクラスなど、Godotの組み込み機能を積極的に活用してください。

### **5. RGD言語記法の厳格遵守（重要）**

RGDファイル作成時は、以下の記法ルールを**必ず遵守**してください：

#### **コマンド分類の理解**
* **定義コマンド（is_define_command = true）**: ラベル外でも記述可能
  ```gdscript
  character ayane "彩音" prefix "ayane" path "res://assets/ayane" color "#FF69B4"
  image bg room path "res://assets/room.png"
  message_animation add fade 0.2
  ```

* **実行コマンド（is_define_command = false）**: **必ずラベル内にネスト**
  ```gdscript
  label start:
      "ゲーム開始"          # Say文
      set player.name = "主人公"  # 変数設定
      jump next_scene       # ジャンプ
  ```

#### **絶対禁止事項**
```gdscript
# ❌ これらは絶対に書かないでください
"最上位のSay文は不正"     # Say文のラベル外配置

label wrong_label         # コロン忘れ
    "エラーになります"

akira "{player.name}さん"  # 変数参照の括弧間違い（波括弧は装飾用）
```

#### **注意事項**
```gdscript
# ✅ setコマンドは定義段階でも使用可能（グローバル変数初期化等）
set game.title = "マイゲーム"
set config.auto_save = true

# ✅ ただし、実行時の変数操作は必ずラベル内
label game_start:
    set player.name = "主人公"
    set player.level = 1
```

#### **必須記法ルール**
* ラベル定義は**必ずコロン付き**: `label name:`
* 変数参照は**角括弧**: `[player.name]`
* インデントは**タブまたは4スペース統一**
* 実行コマンドは**必ずラベル内**

### **6. 外部システム統合への準備（v1.2.1対応）**

将来の双方向イベント統合に向けた開発指針：

* **統一API設計**: 外部システムからの呼び出しやすさを重視
* **EventCommand準備**: 外部システム制御用のコマンド基盤整備
* **同期・非同期制御**: リアルタイム処理とイベント待機の両対応
* **状態管理**: RPG・アクション・パズルゲームとの状態共有準備

### **7. 統一ログシステムの活用**

* デバッグやエラーログを提案する際は、ArgodeSystem.log()関数を使用してください：
  ```gdscript
  ArgodeSystem.log_workflow("🎬 WORKFLOW: 重要な処理フロー")
  ArgodeSystem.log_critical("🚨 CRITICAL: 重要なエラー")
  ArgodeSystem.log_debug("🔧 DEBUG: デバッグ情報") 
  ```
* 毎フレーム出力されるような連続的なログは、**AIのコンテキストを汚染するため避けてください**。

### **8. アーキテクチャ文書の活用**

* 設計議論の際は、`Argode_v1_2_Complete_Architecture.md` の依存関係マップを参照してください。
* 新機能は既存のService Layer Pattern に適合する形で提案してください。
* RGD言語仕様定義に従った正確な記法でコード例を提示してください。

### **9. 継続的改善管理**

* プロジェクトルートの `TODO.md` で改善進捗を管理しています。
* ユーザーがテスト完了を報告した時点で、該当項目を完了済みに更新してください。
* **品質確保を最優先**とし、機能の安定性を犠牲にしてまで数値目標を追求しないでください。
* 各改善完了時には必ずユーザーテストを実施し、承認を得てから次の改善に進行してください。

### **10. カスタムコマンド拡張性の維持**

* カスタムコマンド開発者が容易に拡張できる構造を維持してください。
* Service Layer の内部実装を隠蔽し、Manager Layer の統一APIを保持してください。
* 将来のv1.2.1（双方向イベント統合）、v1.3（セーブシステム強化）を考慮した提案を行ってください。

これらの指示を遵守することで、Argodeフレームワークの設計思想を維持しながら、
技術的品質の継続的向上と安定した機能拡張が実現できます。
