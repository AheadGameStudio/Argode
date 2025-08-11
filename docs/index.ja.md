# Argode へようこそ

[![Godot](https://img.shields.io/badge/Godot-4.0+-blue.svg)](https://godotengine.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-2.0-orange.svg)](https://github.com/AheadGameStudio/Argode/releases)

**Argode** は、**Godot Engine 4.0+** 向けに構築された強力なビジュアルノベルフレームワークです。柔軟性と拡張性を保ちながら、美しいインタラクティブストーリーを簡単に作成できます。

## ✨ 主要機能

!!! tip "🎯 **設計思想**"
    
    Argodeは**シングルオートロードアーキテクチャ**を採用し、**ArgodeSystem**のみをグローバルシングルトンとします。すべてのマネージャーは子ノードとして整理され、Godotプロジェクトへのクリーンな統合を実現します。

### 🎬 **ビジュアルノベルコア機能**
- **RGDスクリプト言語**: 直感的なビジュアルノベル向けスクリプト記法
- **キャラクターシステム**: 表情と位置設定による動的なキャラクター定義
- **背景・シーン管理**: スムーズなトランジションとレイヤード シーン
- **選択肢メニュー**: インタラクティブな分岐ナラティブ
- **セーブ・ロードシステム**: 完全なゲームステート管理

### 🎨 **高度な機能**
- **カスタムコマンド**: シグナルベースアーキテクチャによる無限の拡張性
- **定義システム**: アセットと変数の一元管理
- **レイヤーアーキテクチャ**: ロールベース割り当てによる柔軟なシーン構造
- **UIフレームワーク**: 複雑なインターフェースのためのプロフェッショナルなAdvScreenシステム
- **アセット管理**: スマートなプリロードとメモリ最適化

### 🛠️ **開発者体験**
- **シングルファイルセットアップ**: アドオンをインポートするだけですぐに開始
- **ホットリロード**: 開発中のスクリプトの即座更新
- **Visual Studio Code サポート**: シンタックスハイライト拡張が利用可能
- **包括的なドキュメント**: 詳細なガイドとAPIリファレンス
- **サンプルプロジェクト**: 実用的な実装例から学習

## 🚀 クイックスタート

わずか数分でArgodeを始められます：

```gdscript
# 1. ArgodeSystemをオートロードに追加
# 2. 最初のスクリプトファイルを作成

label start:
    narrator "Argodeへようこそ！"
    "これがあなたの最初のビジュアルノベルシーンです。"
    
    menu:
        "ストーリーを続ける":
            jump next_scene
        "Argodeについてもっと知る":
            jump tutorial
```

[今すぐ始める →](getting-started/quick-start.ja.md){ .md-button .md-button--primary }
[サンプルを見る →](examples/simple-vn.ja.md){ .md-button }

## 📚 ドキュメントセクション

<div class="grid cards" markdown>

-   :material-rocket-launch: **はじめに**
    
    ---
    
    インストールガイド、基本セットアップ、最初のビジュアルノベル
    
    [:octicons-arrow-right-24: クイックスタート](getting-started/quick-start.ja.md)

-   :material-architecture: **アーキテクチャ**
    
    ---
    
    Argodeの設計思想とコアコンポーネントの詳細
    
    [:octicons-arrow-right-24: 詳細はこちら](architecture/design-philosophy.ja.md)

-   :material-script: **スクリプトリファレンス**
    
    ---
    
    RGDシンタックスの完全なリファレンスとサンプル付きコマンド
    
    [:octicons-arrow-right-24: RGD シンタックス](script/rgd-syntax.ja.md)

-   :material-puzzle: **カスタムコマンド**
    
    ---
    
    独自のコマンドとエフェクトでArgodeを拡張
    
    [:octicons-arrow-right-24: カスタムコマンド](custom-commands/overview.ja.md)

-   :material-palette: **UIシステム**
    
    ---
    
    AdvScreenフレームワークで美しいインターフェースを構築
    
    [:octicons-arrow-right-24: UIフレームワーク](ui/advscreen.ja.md)

-   :material-code-array: **APIリファレンス**
    
    ---
    
    すべてのArgodeコンポーネントの完全なAPIドキュメント
    
    [:octicons-arrow-right-24: API ドキュメント](api/argode-system.ja.md)

</div>

## 🎮 サンプルプロジェクト

これらのサンプル実装でArgodeの実際の動作を確認：

- **[シンプルなビジュアルノベル](examples/simple-vn.ja.md)**: キャラクターと選択肢のある基本的なストーリー
- **[高度な機能デモ](examples/custom-features.ja.md)**: 高度なエフェクトとカスタムコマンド
- **[モバイル最適化](examples/best-practices.ja.md)**: モバイルデプロイメントのパフォーマンステップス

## 🤝 コミュニティ・サポート

- **GitHub**: [AheadGameStudio/Argode](https://github.com/AheadGameStudio/Argode)
- **Discord**: コミュニティサーバーに参加
- **Issues**: バグレポートと機能リクエスト

## 📄 ライセンス

Argodeは[MIT ライセンス](https://github.com/AheadGameStudio/Argode/blob/main/LICENSE)の下で公開されています。商用・非商用問わず無料でご利用いただけます。

---

*ビジュアルノベルを作成する準備はできましたか？ [クイックスタートガイドから始めましょう →](getting-started/quick-start.ja.md)*
