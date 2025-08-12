# 基本セットアップガイド

このガイドでは、ArgodeをGodotプロジェクトで動作させるための基本的なセットアップ手順を説明します。

## オートロードの設定

1. **プロジェクト設定** を開く（`Project → Project Settings`）
2. **オートロード** タブに移動
3. **ArgodeSystem** を追加：
   - **パス**: `res://addons/argode/core/ArgodeSystem.gd`
   - **ノード名**: `ArgodeSystem`
   - **有効** にチェック

![オートロード設定](../images/autoload-setup.png)

## メインシーンとして設定

1. まだ作成していない場合は、新しいシーンを作成し（`Scene → New Scene`）、保存します（例: `Main.tscn`）。
2. **プロジェクト設定** を開きます（`Project → Project Settings`）。
3. **アプリケーション → 実行** セクションで、**メインシーン** を`Main.tscn`（またはメインシーンに付けた名前）に設定します。
4. **F5** を押してプロジェクトを実行します。
