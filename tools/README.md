# 🛠️ Argode 開発用ユーティリティツール

このディレクトリには、Argode開発を効率化するためのユーティリティスクリプトが含まれています。

## 📝 利用可能なツール

### 1. UID生成ツール (`generate_uid.gd`)

GodotリソースのユニークIDを生成します。

```bash
# 単一UID生成
godot --headless --script tools/generate_uid.gd --quit

# 複数UID生成（5個）
godot --headless --script tools/generate_uid.gd --quit -- --count 5
```

**出力例:**
```
✅ Generated UID: uid://b8nqpx2hqwert
```

### 2. テストランナー (`test_runner.gd`)

統合テストの自動実行とレポート生成を行います。

```bash
# 全テスト実行
godot --headless --script tools/test_runner.gd --quit

# カスタムコマンドテストのみ
godot --headless --script tools/test_runner.gd --quit -- commands

# システム統合テストのみ
godot --headless --script tools/test_runner.gd --quit -- system

# パフォーマンステストのみ
godot --headless --script tools/test_runner.gd --quit -- performance
```

**レポート例:**
```
📊 TEST REPORT
============================================================
Total tests: 15
Passed: 14 ✅
Failed: 1 ❌
Success rate: 93.3%
============================================================
```

## 🚀 開発ワークフロー統合

### CI/CD パイプライン
```yaml
# 例: GitHub Actions
- name: Run Argode Tests
  run: |
    godot --headless --script tools/test_runner.gd --quit
```

### 開発用エイリアス設定
```bash
# .bashrc または .zshrc に追加
alias argode-test="godot --headless --script tools/test_runner.gd --quit"
alias argode-uid="godot --headless --script tools/generate_uid.gd --quit"
```

## 📋 テスト項目

### カスタムコマンドテスト
- [ ] 全コマンドの登録確認
- [ ] パラメータ検証機能
- [ ] 主要コマンド動作確認
  - text_animate
  - ui_slide  
  - tint
  - screen_flash
  - wait

### システム統合テスト
- [ ] ArgodeSystem初期化
- [ ] 各マネージャーの存在確認
- [ ] ラベルレジストリの動作
- [ ] UI統合確認

### パフォーマンステスト
- [ ] 初期化時間測定
- [ ] メモリ使用量チェック
- [ ] 大量コマンド実行時の安定性

## 🔧 拡張方法

新しいテストを追加する場合は、`test_runner.gd`の該当メソッドに追加してください：

```gdscript
func _test_custom_feature():
    """新機能のテスト"""
    print("\n🆕 Testing New Feature...")
    
    # テストロジックを実装
    var result = your_test_logic()
    _log_result("  - New feature test: " + ("✅" if result else "❌"), result)
```

## 💡 今後の拡張予定

- [ ] シナリオファイルの構文チェックツール
- [ ] パフォーマンスプロファイリングツール
- [ ] 自動回帰テストスイート
- [ ] リソース依存関係チェッカー