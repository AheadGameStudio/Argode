# Ren' Gd - Godot用ADVゲームエンジンアドオン

## プロジェクト概要

Ren'Py風のアドベンチャーゲームエンジンをGodot Engine 4.x用アドオンとして実装。カスタム`.rgd`スクリプトファイルを使用して、ノベルゲーム制作を支援する。

## 実装済み機能

### コアシステム
- **AdvScriptPlayer**: `.rgd`ファイルの解析・実行エンジン
- **LabelRegistry**: 複数ファイル間でのラベル管理システム（Ren'Py風）
- **BaseAdvGameUI**: 継承可能な基本UIクラス

### マネージャーシステム
- **CharacterManager**: キャラクター表示・管理
- **UIManager**: UI制御・メッセージ表示  
- **VariableManager**: 変数管理・保存
- **TransitionPlayer**: トランジション効果システム

### UI機能
- **TypewriterText**: タイプライター効果（BBCode対応）
- **選択肢メニュー**: 動的選択肢生成
- **メッセージボックス**: リッチテキスト対応

## スクリプト仕様（.rgdファイル）

### 基本コマンド
```rgd
# キャラクター定義
define y = Character("res://characters/yuko.tres")

# ラベル定義
label scene_test_start:

# メッセージ表示
"メッセージテキスト"
y "キャラクターセリフ"

# 背景変更（トランジション対応）
scene classroom with fade
scene park with dissolve

# キャラクター表示
show y normal at center
show s happy at left with fade

# キャラクター非表示
hide y with fade

# 選択肢
menu:
    "選択肢1":
        jump label1
    "選択肢2":
        jump label2

# ラベルジャンプ
jump other_label

# ファイル間ジャンプ（LabelRegistry使用）
jump chapter1_start  # 別ファイルのラベル
```

### トランジション種類
- `none`: トランジションなし
- `fade`: フェードイン/アウト
- `dissolve`: ディゾルブ（現在はfadeと同じ）
- `slide_left/right/up/down`: スライド効果

## ファイル構成

### アドオンファイル
```
addons/adv_engine/
├── plugin.gd                    # プラグイン設定
├── AdvScriptPlayer.gd           # メインスクリプトプレイヤー
├── LabelRegistry.gd             # ラベル管理システム
├── ui/
│   └── BaseAdvGameUI.gd         # 基本UIクラス
└── managers/
    ├── CharacterManager.gd      # キャラクター管理
    ├── UIManager.gd             # UI管理
    ├── VariableManager.gd       # 変数管理
    └── TransitionPlayer.gd      # トランジション処理
```

### シナリオファイル
```
scenarios/
├── scene_test.rgd              # メインテスト（scene_test_start）
├── chapter1.rgd                # 第1章（chapter1_start）
├── chapter2.rgd                # 第2章（chapter2_start）
└── *.rgd                       # その他シナリオ
```

## 重要な実装注意点

### ラベル管理システム
- **重複ラベル禁止**: 全ファイル間でラベル名は一意である必要がある
- **ユニークラベル命名**: `ファイル名_ラベル名` 形式を推奨
  - `scene_test_start`（scene_test.rgd）
  - `chapter1_start`（chapter1.rgd）
- **エラー表示**: 重複ラベルは起動時にエラーメッセージを表示
- **軽量メモリ管理**: ラベル位置情報のみメモリ保持、スクリプト内容は必要時読み込み

### autoload設定
project.godotに以下が自動登録される：
```
[autoload]
AdvScriptPlayer="*res://addons/adv_engine/AdvScriptPlayer.gd"
VariableManager="*res://addons/adv_engine/managers/VariableManager.gd"
CharacterManager="*res://addons/adv_engine/managers/CharacterManager.gd"
UIManager="*res://addons/adv_engine/managers/UIManager.gd"
TransitionPlayer="*res://addons/adv_engine/managers/TransitionPlayer.gd"
LabelRegistry="*res://addons/adv_engine/LabelRegistry.gd"
```

### UI統合
BaseAdvGameUIを継承して使用：
```gdscript
extends BaseAdvGameUI

# 自動設定可能
@export var auto_start_script: bool = true
@export var default_script_path: String = "res://scenarios/scene_test.rgd"
@export var start_label: String = "scene_test_start"
```

## トラブルシューティング

### よくある問題

1. **トランジションが動作しない**
   - シナリオファイルで `with fade` が記述されているか確認
   - TransitionPlayerがautoloadに登録されているか確認
   - デバッグログで `transition: none` と表示される場合は構文エラー

2. **ラベルが見つからない**
   - ラベル名のタイポを確認
   - ファイル間ジャンプの場合、LabelRegistryが正常に初期化されているか確認
   - コンソールで「🔍 Label 'xxx' not found」メッセージを確認

3. **重複ラベルエラー**
   - 起動時のエラーメッセージで重複箇所を特定
   - 各ファイルでユニークなラベル名を使用
   - `start` → `scene_test_start` のように変更

### デバッグ情報
以下のログが正常時に出力される：
```
🎬 TransitionPlayer found successfully
🔍 Scene regex matched line: 'scene classroom with fade'
🎬 Parsed scene_name: 'classroom', transition: 'fade'
🎬 Executing transition: fade
✅ Transition completed: fade
```

## 今後の拡張予定
- カスタムシェーダーを使ったトランジション効果
- セーブ・ロード機能
- 音声・BGM制御コマンド
- 条件分岐（if文）サポート
- 変数操作コマンドの拡張

## 開発履歴
- 基本エンジン実装完了
- タイプライター効果実装
- 複数ファイル対応ラベルシステム実装
- トランジションシステム実装・デバッグ完了