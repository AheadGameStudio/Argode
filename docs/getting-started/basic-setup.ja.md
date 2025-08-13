# 基本設定ガイド

このガイドでは、ArgodeをGodotプロジェクトで動作させるための基本的な設定手順を説明します。

## オートロードの設定

1.  **プロジェクト設定**（`プロジェクト → プロジェクト設定`）を開きます。
2.  **オートロード**タブに移動します。
3.  **ArgodeSystem**を追加します。
    *   **パス**: `res://addons/argode/core/ArgodeSystem.gd`
    *   **ノード名**: `ArgodeSystem`
    *   **有効**にチェックを入れます。

![オートロード設定](../images/autoload-setup.png)

## メインシーンの設定

1.  まだ作成していない場合は、新しいシーンを作成し（`シーン → 新しいシーン`）、保存します（例：`Main.tscn`）。
2.  **プロジェクト設定**（`プロジェクト → プロジェクト設定`）に移動します。
3.  **アプリケーション → 実行**セクションで、**メインシーン**を`Main.tscn`（またはメインシーンに付けた名前）に設定します。

## 視覚レイヤーの準備

Argodeは、Godotの`CanvasLayer`ノードを利用して、背景、キャラクター、UI要素の視覚的な深度と表示を管理します。これらのレイヤーを手動で設定することもできますが、Argodeは`ArgodeScreen`ノードを使用した合理化されたアプローチを提供します。

### 推奨アプローチ: `ArgodeScreen`の使用（最も簡単）

`ArgodeScreen`ノード（`res://addons/argode/ui/ArgodeScreen.tscn`にあります）は、レイヤー管理を簡素化するために設計された、事前に構成された`Control`ノードです。「レイヤー自動展開」プロパティが有効になっている場合（デフォルト）、一般的な役割（背景、キャラクター、UI、エフェクト）の`CanvasLayer`ノードの作成と割り当てを自動的に処理します。

1.  メインシーン（`Main.tscn`）で、ルートノードの直接の子として`ArgodeScreen`ノードを追加します。
2.  インスペクターで`ArgodeScreen`ノードの「レイヤー自動展開」プロパティが有効になっていることを確認します（通常はデフォルトでオンになっています）。
3.  シーンツリーは次のようになります。

    ```
    - Main (Node2DまたはControl)
      - ArgodeScreen (Control)
        - Background (CanvasLayer)
        - Characters (CanvasLayer)
        - UI (CanvasLayer)
        - Effects (CanvasLayer)
    ```

    `CanvasLayer`ノードは、視覚的な深度に適した値に`Layer`プロパティが自動的に設定されます。

### 代替: 手動での`CanvasLayer`設定（上級者向け）

上級ユーザーや特定のプロジェクトのニーズに合わせて、`CanvasLayer`ノードを手動で作成および構成できます。

1.  メインシーン（`Main.tscn`）で、ルートノードの直接の子として以下の`CanvasLayer`ノードを作成します。
    *   **背景レイヤー**: 背景を表示します。`Layer`プロパティを低い値（例：`0`または`1`）に設定します。
    *   **キャラクターレイヤー**: キャラクターを表示します。`Layer`プロパティを背景よりも高い値（例：`2`または`3`）に設定します。
    *   **UIレイヤー**: ユーザーインターフェース要素を表示します。`Layer`プロパティを高い値（例：`10`または`100`）に設定します。
    *   **エフェクトレイヤー**: （オプションですが推奨）画面全体のエフェクトを表示します。`Layer`プロパティを最も高い値（例：`200`）に設定します。

2.  シーンツリーは次のようになります。

    ```
    - Main (Node2DまたはControl)
      - BackgroundLayer (CanvasLayer)
      - CharactersLayer (CanvasLayer)
      - UILayer (CanvasLayer)
      - EffectsLayer (CanvasLayer)
    ```

## ArgodeSystemの初期化

メインシーン（`Main.tscn`）にアタッチされたスクリプトで、準備した`CanvasLayer`ノードをそれぞれの役割にマッピングして`ArgodeSystem`を初期化する必要があります。

```gdscript
# Main.gd（メインシーンのルートノードにアタッチ）
extends Node2D # またはControl、ルートノードのタイプに応じて

func _ready():
    # CanvasLayerノードをArgodeのレイヤーロールにマッピングします
    # ArgodeScreenを使用している場合は、その子CanvasLayersにアクセスします
    var layer_map = {
        "background": $ArgodeScreen/Background, # または手動設定の場合は$BackgroundLayer
        "character": $ArgodeScreen/Characters, # または手動設定の場合は$CharactersLayer
        "ui": $ArgodeScreen/UI,             # または手動設定の場合は$UILayer
        "effects": $ArgodeScreen/Effects    # または手動設定の場合は$EffectsLayer（オプション）
    }

    # ArgodeSystemを初期化します
    if ArgodeSystem.initialize_game(layer_map):
        print("ArgodeSystemが正常に初期化されました！")
        # 最初のRGDスクリプトを開始します
        ArgodeSystem.start_script("res://scenarios/main.rgd", "start")
    else:
        print("ArgodeSystemの初期化に失敗しました。")
        # 初期化エラーを処理します（例：エラーメッセージを表示）

```

## プロジェクトの実行

**F5**キーを押してプロジェクトを実行します。すべてが正しく設定されていれば、Argodeが初期化され、`res://scenarios/main.rgd`スクリプトの実行が開始されます。
