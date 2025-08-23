# Phase 3 デバッグテスト

## 🔍 実際の問題の診断

ログから判明した問題：
1. **タグ除去エラー**: `"こ{"` が表示されている
2. **位置ずれ**: 最初の文字の後で止まっている
3. **タイマー復帰問題**: wait完了後の動作が不正

## 🛠️ 実装した修正

### TypewriterTextParser.gd修正
- `_clean_basic_text()`に `{w=X}` タグ除去ロジック追加
- RegEx: `r"\{(w|wait)=([0-9.]+)\}"` でタグを完全除去

### 期待される動作
1. `"こ{w=1.0}んにちは"` → 表示テキスト: `"こんにちは"`
2. 位置1（「こ」の後）で1秒待機
3. wait完了後にタイピング継続

## 🎯 テスト方法

```gdscript
# Godotコンソールで実行
ArgodeSystem.load_and_execute_scenario("res://examples/scenarios/phase3_wait_test.rgd", "test_start")
```

### 確認ポイント
- [ ] 表示テキストに `{` や `}` が含まれない
- [ ] 正確な位置でwait実行
- [ ] wait完了後のスムーズな継続
- [ ] エラーログの解消

Phase 3の完全動作確認をお願いします！
