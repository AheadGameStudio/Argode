# Argode 開発ワークフロー

## 🔧 開発環境

### 推奨セットアップ
- **マルチルートワークスペース**: `BE_THE_HERO.code-workspace`で開発
- **F5デバッグ**: BE_THE_HEROプロジェクトのみでデバッグ実行
- **Git管理**: Argode・BE_THE_HERO個別管理

### プロジェクト構造
```
Projects/GodotEngine/
├── BE_THE_HERO/              # ゲームプロジェクト
│   ├── addons/argode/        # → シンボリックリンク
│   ├── .vscode/launch.json   # デバッグ設定（F5実行）
│   └── ...
└── Argode/                   # フレームワーク（このリポジトリ）
    ├── addons/argode/        # フレームワークの実体
    └── ...
```

## 🌟 ブランチ戦略

### mainブランチ
- 安定版のみマージ
- 直接pushは避ける
- テスト済み機能のみ

### フィーチャーブランチ
```bash
# 新機能開発時
git checkout -b feature/your-feature-name
git commit -m "feat: 新機能の説明"
git push origin feature/your-feature-name

# バグ修正時
git checkout -b fix/your-bug-description  
git commit -m "fix: バグ修正の説明"
git push origin fix/your-bug-description

# リファクタリング時
git checkout -b refactor/your-refactor-name
git commit -m "refactor: リファクタ内容の説明"
git push origin refactor/your-refactor-name
```

## 📋 Pull Request ワークフロー

### 1. ブランチ作成・作業
```bash
# mainブランチを最新に更新
git checkout main
git pull origin main

# フィーチャーブランチ作成
git checkout -b feature/ruby-system-refactor

# 作業・コミット
git add .
git commit -m "feat: RubyRichTextLabelの統一実装"
git push origin feature/ruby-system-refactor
```

### 2. Pull Request作成（MCP使用）
```bash
# GitHub MCPを使用してPR作成
# AIエージェント経由で以下を実行:
mcp_github_create_pull_request(
    owner="AheadGameStudio",
    repo="Argode", 
    title="feat: ルビシステムの統一・RubyRichTextLabel実装",
    head="feature/ruby-system-refactor",
    base="main",
    body="## 概要\nルビシステムを統一し、RubyRichTextLabelベースに統合\n\n## 変更点\n- 複数実装方式の統一\n- パフォーマンス改善\n- バグ修正\n\n## 関連Issue\nCloses #7"
)
```

### 3. コードレビュー・マージ
```bash
# Copilotレビュー要求（推奨）
mcp_github_request_copilot_review(
    owner="AheadGameStudio",
    repo="Argode",
    pullNumber=6
)

# レビュー完了後、マージ
mcp_github_merge_pull_request(
    owner="AheadGameStudio", 
    repo="Argode",
    pullNumber=6,
    merge_method="squash"
)
```

### 4. ブランチクリーンアップ
```bash
# ローカルブランチ削除
git checkout main
git pull origin main
git branch -d feature/ruby-system-refactor

# リモート追跡ブランチも削除（自動的に削除される場合が多い）
git fetch --prune
```

## 🚨 重要な制約事項

### シンボリックリンク制約
- **ファイル新規作成**: Argodeリポジトリで実行
- **ファイル編集**: BE_THE_HERO・Argode両方で可能  
- **デバッグ・テスト**: BE_THE_HEROプロジェクトで実行

### AIエージェント連携時の注意
1. 新しいスクリプト作成時は Argodeリポジトリに移動
2. 既存ファイル編集は現在のプロジェクトで可能
3. テストはBE_THE_HEROプロジェクトで実行

## 📊 Issue管理

### 現在のオープンIssue
- #6: 見直し要望  
- #7: ルビシステムの統一・リファクタリング（優先度: High）
- #8: 大型クラスの責任分離・アーキテクチャ整理（優先度: High）
- #9: シンボリックリンク環境でのAIエージェント最適化（優先度: Medium）

### Issue-PR連携
```markdown
## Pull Requestテンプレート

### 概要
[変更内容の簡潔な説明]

### 変更点
- [具体的な変更点1]
- [具体的な変更点2]

### テスト
- [ ] BE_THE_HEROプロジェクトでの動作確認
- [ ] 既存機能の回帰テスト
- [ ] パフォーマンステスト（必要に応じて）

### 関連Issue
Closes #XX
```

## 🛠 デバッグ環境

### F5デバッグ（BE_THE_HEROプロジェクト）
- **Launch BE_THE_HERO Game**: ゲーム実行（ポート6007）
- **Debug Current Scene**: 現在のシーンをデバッグ
- **Attach to Running Game**: 実行中のゲームにアタッチ

### ログ・デバッグ
- Argode修正 → BE_THE_HEROでテスト実行
- Godotコンソールでログ確認
- ブレークポイントはBE_THE_HEROプロジェクト側で設定

## 💡 ベストプラクティス

### コミットメッセージ
```bash
# 推奨フォーマット
feat: 新機能追加
fix: バグ修正
refactor: リファクタリング
docs: ドキュメント更新
test: テスト追加・修正
style: フォーマット修正
perf: パフォーマンス改善
```

### ブランチ命名規則
```bash
feature/機能名-簡潔な説明    # feature/ruby-system-refactor
fix/バグの説明             # fix/typewriter-memory-leak  
refactor/リファクタ対象     # refactor/argode-screen-split
docs/ドキュメント内容       # docs/api-documentation
```

### PR作成時のチェックリスト
- [ ] コードが期待通り動作する
- [ ] BE_THE_HEROプロジェクトでテスト済み
- [ ] 関連Issueが適切に参照されている
- [ ] コミットメッセージが明確
- [ ] 必要に応じてCopilotレビューを要求

---

**📝 このワークフローは開発効率とコード品質の向上を目的としています。**  
**🤖 AIエージェント連携時はMCPサーバーを活用してPR管理を自動化しましょう。**
