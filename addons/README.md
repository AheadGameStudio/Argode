# Ren' Gd - ADVエンジンアドオン

Godot Engine用のRen'Pyライクなアドベンチャーゲームエンジンです。

## 主要機能

- **スクリプト解析**: `.rgd`形式のスクリプトファイル対応
- **タイプライター効果**: 文字送りアニメーション
- **キャラクター管理**: キャラクター表示・管理システム
- **変数管理**: ゲーム進行用変数システム
- **UI管理**: 汎用的なADVゲーム用UI
- **トランジション**: 画面切り替え効果

## 使用方法

### 1. アドオンの有効化

1. プロジェクト設定 > プラグイン
2. "Ren' Gd - ADV Engine"を有効化

### 2. UIの作成

```gdscript
extends BaseAdvGameUI
class_name MyGameUI

func initialize_ui():
    show_message("システム", "ゲームを開始します！")
```

### 3. スクリプトの作成

```
# sample.rgd
@start
msg "主人公" "こんにちは！"
choice "返事をする" choice_hello "無視する" choice_ignore

@choice_hello
msg "主人公" "こんにちは！"
jump end

@choice_ignore
msg "主人公" "..."
jump end

@end
msg "システム" "終了です"
```

## ディレクトリ構成

```
addons/adv_engine/
├── AdvScriptPlayer.gd          # スクリプト実行エンジン
├── CharacterData.gd            # キャラクターデータ定義
├── TypewriterText.gd           # タイプライター効果
├── ui/
│   ├── BaseAdvGameUI.gd        # ベースUIクラス
│   ├── BaseAdvGameUI.tscn      # UIシーン
│   └── README.md               # UI使用方法
├── managers/
│   ├── CharacterManager.gd     # キャラクター管理
│   ├── VariableManager.gd      # 変数管理
│   ├── UIManager.gd            # UI管理
│   └── TransitionPlayer.gd     # トランジション管理
├── plugin.cfg                  # プラグイン設定
└── plugin.gd                   # プラグインスクリプト
```

## サンプル

`design/gui/usage_sample.tscn`でUIのサンプルを確認できます。

## ライセンス

MIT License