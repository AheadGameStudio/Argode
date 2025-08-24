# Argode タイプライター機能 段階的実装計画

## 🎯 実装戦略の概要

**方針**: 既存システムとの競合回避のため、関連クラスを一旦削除してから最小構成で再構築

## 📋 削除対象クラスと依存関係

### **削除対象（競合防止）**
1. `ArgodeTypewriterService.gd` (399行)
2. `ArgodeInlineCommandManager.gd` (328行) 
3. `ArgodeMessageRenderer.gd` (600行+)
4. `ArgodeEffectAnimationManager.gd` (211行)
5. `ArgodeInlineProcessorService.gd` (200行+)

### **影響を受けるクラス（修正必要）**
- `ArgodeUIControlService.gd` - ArgodeMessageRenderer参照
- `ArgodeUIManager.gd` - ArgodeMessageRenderer読み込み
- `ArgodeTextRenderer.gd` - コメントでArgodeMessageRenderer言及
- `ArgodeDecorationRenderer.gd` - 同上  
- `ArgodeAnimationCoordinator.gd` - 同上
- `ArgodeRubyRenderer.gd` - 同上

## 🚀 段階的実装フェーズ

### **Phase 1: 安全な削除とプロトタイプ**

#### 1.1 削除前バックアップ
```bash
# 既存ファイルを安全にバックアップ
cp addons/argode/services/ArgodeTypewriterService.gd addons/argode/services/ArgodeTypewriterService.gd.deleted
cp addons/argode/managers/ArgodeInlineCommandManager.gd addons/argode/managers/ArgodeInlineCommandManager.gd.deleted
cp addons/argode/renderer/ArgodeMessageRenderer.gd addons/argode/renderer/ArgodeMessageRenderer.gd.deleted
cp addons/argode/services/ArgodeEffectAnimationManager.gd addons/argode/services/ArgodeEffectAnimationManager.gd.deleted
cp addons/argode/services/ArgodeInlineProcessorService.gd addons/argode/services/ArgodeInlineProcessorService.gd.deleted
```

#### 1.2 削除とエラー箇所修正
- 削除対象ファイルを移動
- UIControlService, UIManagerの参照エラーを一時的にコメントアウト
- エラーなしでArgodeが起動できる状態にする

#### 1.3 最小限プロトタイプ作成
新設計の骨格のみ実装：

**ArgodeMessageTypewriter.gd (30-50行プロトタイプ)**
```gdscript
class_name ArgodeMessageTypewriter
extends RefCounted

var current_text: String = ""
var position: int = 0
var is_typing: bool = false

# 最小限API
func start_typing(text: String, speed: float = 0.05):
    current_text = text
    position = 0
    is_typing = true
    _process_simple_typing()

func _process_simple_typing():
    # 単純な文字送り（エフェクト・コマンドなし）
    pass
```

### **Phase 2: 基本機能実装**

#### 2.1 TypewriterTextParser実装 (40-60行)
- 基本的なテキスト解析
- 改行・特殊文字対応
- コマンド検出（実行はしない）

#### 2.2 ArgodeMessageTypewriter拡張 (80-120行)
- TextParserとの連携
- 基本タイピング制御
- 一時停止・再開・スキップ

#### 2.3 UI連携のための最小限Bridge (30-50行)
- MessageCanvasへの文字送り
- UI更新イベント

### **Phase 3: コマンド実行機能**

#### 3.1 TypewriterCommandExecutor実装 (60-100行)
- waitコマンド実装
- 位置ベース実行制御
- ArgodeSystem.get_service()との連携

#### 3.2 統合テスト
- waitコマンドの1文字ずれ問題修正確認
- 基本メッセージ表示動作確認

### **Phase 4: エフェクト機能**

#### 4.1 TypewriterEffectManager実装 (80-120行)
- ArgodeGlyphInfoベースのエフェクト管理  
- ArgodeGlyphEffect enum使用
- メッセージエフェクトとの連携

#### 4.2 TypewriterUIBridge完成 (40-60行)
- エフェクトデータのUI連携
- MessageCanvas・MessageWindow更新

### **Phase 5: 完全統合**

#### 5.1 既存システム修復
- UIControlService修正
- UIManager修正
- 関連レンダラークラス調整

#### 5.2 最終テスト
- 全機能動作確認
- パフォーマンステスト
- 後方互換性確認

## 🎛️ 各フェーズでのテスト項目

### **Phase 1 テスト**
- [ ] Argodeが起動する
- [ ] エラーが発生しない
- [ ] 最小限のメッセージ表示ができる

### **Phase 2 テスト** 
- [ ] 基本タイピング効果が動作する
- [ ] 改行が正しく処理される
- [ ] 一時停止・再開・スキップが動作する

### **Phase 3 テスト**
- [ ] waitコマンドが正しい位置で実行される
- [ ] 1文字ずれ問題が解決されている
- [ ] 複数のwaitコマンドが正しく動作する

### **Phase 4 テスト**
- [ ] colorエフェクトが動作する  
- [ ] scaleエフェクトが動作する
- [ ] エフェクトの組み合わせが動作する

### **Phase 5 テスト**
- [ ] 全機能が元の状態と同等に動作する
- [ ] パフォーマンスが改善されている
- [ ] デバッグが容易になっている

## 🛠️ 実装時の注意点

### **削除時の安全対策**
- バックアップを必ず作成
- Git commit前にテスト
- 段階的な削除（一度に全部削除しない）

### **プロトタイプ段階**
- 機能よりも動作の安定性重視
- エラーハンドリングを省略しない
- ログ出力でデバッグしやすく

### **統合段階**  
- 既存のArgodeSystemサービス登録パターンに従う
- log_workflow()を活用した進捗追跡
- エラーログで問題の早期発見

## 💡 Phase 1から始めますか？

この計画で進める場合、まずPhase 1の「安全な削除とプロトタイプ」から開始することをお勧めします。

1. 既存ファイルのバックアップ作成
2. 削除対象ファイルの移動  
3. エラー修正
4. 最小限プロトタイプの動作確認

この順序で進めれば、各段階で動作確認しながら安全にリプレイスメントできます。
