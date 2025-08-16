# RubyTextManager 統合テスト

## テスト目的
ArgodeScreenとRubyTextManagerの基本統合が正しく動作することを確認

## テスト手順

### 1. Godotエディタでのテスト
1. Godotエディタを起動
2. Argodeプロジェクトを開く
3. ArgodeScreenを使用するシーンで以下を確認：
   - use_ruby_text_manager = true に設定
   - コンソール出力でRubyTextManagerの初期化を確認

### 2. 初期化テスト
ArgodeScreenの_ready()実行時に以下のログが出力されるか確認：

```
🚀 Initializing RubyTextManager...
✅ RubyTextManager initialized successfully
🔍 RubyTextManager debug info: {...}
```

### 3. 基本API テスト
以下のコードで簡単なAPIテストが可能：

```gdscript
# ArgodeScreenから呼び出し
if ruby_text_manager:
    ruby_text_manager.print_debug_info()
    var test_result = ruby_text_manager.parse_ruby_syntax("【東京｜とうきょう】")
    print("Test result: %s" % test_result)
```

### 4. シグナルテスト
RubyTextManagerから発信されるシグナルが正しくArgodeScreenで受信されるか確認：

```gdscript
# これらのシグナルハンドラーが呼ばれるか
func _on_ruby_text_updated(ruby_data: Array):
    print("📝 Ruby text updated: %d items" % ruby_data.size())

func _on_ruby_visibility_changed(visible_count: int):
    print("👁️ Ruby visibility changed: %d visible" % visible_count)
```

## 期待される結果

### 成功パターン
- ✅ ArgodeScreenの初期化完了
- ✅ RubyTextManagerインスタンス作成成功
- ✅ デバッグモード設定反映
- ✅ シグナル接続完了
- ✅ エラーなし

### 失敗パターンの対処
- ❌ message_labelがnull → UI要素の自動発見を確認
- ❌ RubyTextManagerが見つからない → preloadパスを確認
- ❌ シグナル接続エラー → 関数名の確認

## 次のステップ
1. 基本統合テスト完了後
2. RubyParserクラスの実装
3. 既存の_parse_ruby_syntax()からの移植
4. 段階的なリファクタリング継続

## 現在の状態
- [x] RubyTextManager基盤クラス作成
- [x] ArgodeScreen統合（変数・初期化）
- [x] シグナル接続
- [ ] 実際のRuby処理移植
- [ ] テスト実行・検証
