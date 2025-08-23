# Phase 3.5 実装完了 - ContinuePrompt 入力待ち表示制御

## 🎯 実装された機能

### ContinuePrompt自動表示/非表示システム
MessageWindowの`ContinuePrompt`ノードが**入力待ちの時にのみ**表示されるようになりました。

## 🔧 実装内容

### 1. ArgodeMessageWindow.gd 拡張
- **初期状態**: ContinuePromptを非表示に設定
- **既存メソッド**: `show_continue_prompt()`, `hide_continue_prompt()` 活用

### 2. ArgodeUIManager.gd 修正
- **入力待ち開始時**: `show_continue_prompt()` 呼び出し
- **入力受信完了時**: `hide_continue_prompt()` 呼び出し
- **全ての入力待ちパス**で統一的に動作

### 3. 動作フロー
```
1. メッセージ表示開始
   ↓
2. タイピング実行（ContinuePrompt非表示）
   ↓
3. タイピング完了
   ↓
4. 入力待ち開始 → 🔹 ContinuePrompt表示
   ↓
5. ユーザー入力
   ↓
6. 入力受信 → 🔹 ContinuePrompt非表示
   ↓
7. 次のメッセージへ
```

## ✅ 対応済みの入力待ちパターン

1. **ArgodeController経由** (メイン)
2. **MessageRenderer経由** (フォールバック1)
3. **MessageWindow経由** (フォールバック2)
4. **汎用入力待ち** (最終フォールバック)

全てのケースでContinuePromptが適切に表示/非表示されます。

## 🧪 テスト方法

```gdscript
# Phase 3テストシナリオで確認
ArgodeSystem.load_and_execute_scenario("res://examples/scenarios/phase3_wait_test.rgd", "test_start")
```

### 確認ポイント
- [ ] タイピング中: ContinuePrompt非表示
- [ ] 入力待ち時: ContinuePrompt表示（▼マーク）
- [ ] 入力後: ContinuePrompt非表示
- [ ] 次メッセージ: 同様の動作繰り返し

## 🚀 Phase 4 準備完了

ContinuePrompt表示制御が完成したので、次のPhase 4（TypewriterEffectManager）に進む準備が整いました！

## 📝 ログ出力

動作確認用のワークフローログ:
- `🎬 [Phase 3.5] Continue prompt shown`
- `🎬 [Phase 3.5] Continue prompt hidden`
