# Documentation Management Guide

このプロジェクトでは、ドキュメントを別ブランチ（`docs`）で管理し、GitHub Actionsを使用して自動デプロイしています。

## ブランチ構成

### `main` ブランチ
- フレームワーク本体のみ
- ユーザー向け配布用
- ドキュメントファイル（`docs/`, `mkdocs.yml`, `requirements.txt`）は除外

### `docs` ブランチ  
- ドキュメントソースファイルのみ
- MkDocsプロジェクト
- GitHub Pagesへの自動デプロイ

## ドキュメント更新ワークフロー

### 1. docs ブランチでの作業
```bash
# docs ブランチに切り替え
git checkout docs

# ドキュメントを編集
# docs/ 内のMarkdownファイルを更新

# 変更をコミット・プッシュ
git add .
git commit -m "Update documentation"
git push origin docs
```

### 2. 自動デプロイ
- `docs`ブランチへのプッシュで自動的にトリガー
- MkDocsでビルド
- GitHub Pagesに自動デプロイ
- サイト更新：https://aheadgamestudio.github.io/Argode/

## セットアップ手順

### docs ブランチの初期作成
```bash
# docs ブランチを作成（初回のみ）
git checkout -b docs

# main ブランチから docs/ と mkdocs.yml をコピー
git checkout main -- docs mkdocs.yml requirements.txt

# docs ブランチ用の .gitignore に置き換え
cp .gitignore.docs .gitignore

# 不要なファイルを削除
rm -rf addons custom definitions scenarios assets characters scenes ui src test tools

# コミット・プッシュ
git add .
git commit -m "Initial docs branch setup"
git push origin docs
```

### GitHub Pages 設定
1. GitHub リポジトリの Settings > Pages
2. Source: "GitHub Actions" を選択
3. ワークフローが自動的に実行される

## ローカル開発

### docs ブランチでのローカルプレビュー
```bash
# docs ブランチで
pip install -r requirements.txt
mkdocs serve

# http://127.0.0.1:8000 でプレビュー
```

## メリット

- ✅ **分離された管理**: フレームワーク本体とドキュメントの完全分離
- ✅ **自動デプロイ**: docs ブランチ更新で自動サイト更新
- ✅ **軽量配布**: main ブランチはフレームワークのみ
- ✅ **効率的開発**: 各ブランチで専用の開発環境
