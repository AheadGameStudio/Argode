# Ren' Gd - Godot用ADVゲームエンジンアドオン

## プロジェクト概要

Ren'Py風のアドベンチャーゲームエンジンをGodot Engine 4.x用アドオンとして実装。カスタム`.rgd`スクリプトファイルを使用して、ノベルゲーム制作を支援する。

## 実装済み機能 (v2アーキテクチャ完全対応)

### v2統合アーキテクチャ ✅
- **AdvSystem**: 単一オートロードによる統合管理システム
- **AdvScriptPlayer**: `.rgd`ファイルの解析・実行エンジン（v2拡張対応）
- **LabelRegistry**: 複数ファイル間でのラベル管理システム（Ren'Py風）
- **AdvScreen**: v2基底UIクラス（旧BaseAdvGameUI後継）

### v2新機能 ✅
- **カスタムコマンドフレームワーク**: 14種類の拡張可能なカスタムコマンド
- **定義管理システム**: character, image, audio, shader定義ステートメント
- **InlineTagProcessor**: TypewriterText統合によるリアルタイムエフェクト
- **混合パラメータ解析**: 位置パラメータ + key=value形式の柔軟な構文
- **同期コマンド処理**: waitコマンドなどの非同期処理対応

### 統合マネージャーシステム ✅
- **CharacterManager**: キャラクター表示・管理
- **UIManager**: UI制御・メッセージ表示  
- **VariableManager**: 変数管理・保存
- **TransitionPlayer**: トランジション効果システム
- **LayerManager**: レイヤーベース画面制御（v2新機能）
- **Definition Managers**: 各種リソース定義管理（v2新機能）

### UI機能 ✅
- **TypewriterText**: タイプライター効果（BBCode対応）
- **選択肢メニュー**: 動的選択肢生成
- **メッセージボックス**: リッチテキスト対応
- **カスタム視覚効果**: 14種類のカスタムコマンド対応

## スクリプト仕様（.rgdファイル）

### 基本コマンド（v1互換 + v2拡張）
```rgd
# v2新機能: スクリプト中心定義システム
character narrator "ナレーター" color=#ffffff
image bg_classroom "res://bg/classroom.jpg"
audio bgm_intro "res://audio/intro.ogg"
shader blur_effect "res://shaders/blur.gdshader"

# v1互換: リソース定義（推奨は上記v2形式）
define y = Character("res://characters/yuko.tres")

# ラベル定義
label main_demo_start:

# メッセージ表示
"メッセージテキスト"
narrator "キャラクターセリフ（v2定義）"
y "キャラクターセリフ（v1定義）"

# 背景変更（トランジション対応）
scene classroom with fade
scene bg_classroom with dissolve  # v2定義を使用

# キャラクター表示
show y normal at center
show narrator happy at left with fade

# キャラクター非表示
hide y with fade

# v2新機能: カスタムコマンド（14種類）
window shake intensity=3.0 duration=0.8
screen_flash color=white duration=0.3
text_animate shake intensity=2.0 duration=1.0
wait duration=1.0
ui_slide in direction=up duration=0.7
particles sparkle intensity=high duration=3.0
tint red intensity=0.3 duration=1.5

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

### autoload設定（v2統合アーキテクチャ）
v2では単一オートロードによる統合管理に移行：
```
[autoload]
AdvSystem="*res://addons/adv_engine/AdvSystem.gd"
```

AdvSystemが以下を統合管理：
- AdvScriptPlayer（スクリプト実行）
- すべてのManagerクラス（子ノード化）
- LabelRegistry（ラベル管理）
- CustomCommandHandler（カスタムコマンド処理）
- Definition Managers（リソース定義管理）

### UI統合（v2 AdvScreen基盤）
v2ではAdvScreenを継承して使用：
```gdscript
extends "res://addons/adv_engine/ui/AdvScreen.gd"
class_name AdvGameUI

# 自動設定可能
@export var auto_start_script: bool = true
@export var default_script_path: String = "res://scenarios/main_demo.rgd"
@export var start_label: String = "main_demo_start"

# v2新機能: レイヤーマッピング設定
@export var layer_mappings: Dictionary = {
    "background": null,
    "character": null,
    "ui": null
}
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

### Phase 1: v1基本エンジン（完了）
- 基本エンジン実装完了
- タイプライター効果実装
- 複数ファイル対応ラベルシステム実装
- トランジションシステム実装・デバッグ完了

### Phase 2: v2アーキテクチャ移行（完了 ✅）
- **統合アーキテクチャ**: 6個のオートロード→1個のArgodeSystemに統合
- **定義管理システム**: character, image, audio, shader定義ステートメント
- **カスタムコマンドフレームワーク**: 14種類の拡張可能なカスタムコマンド
- **InlineTagProcessor**: リアルタイムテキストエフェクト
- **混合パラメータ解析**: 柔軟な構文サポート
- **同期処理システム**: waitコマンドなどの非同期処理対応
- **プロジェクト構造整理**: テストファイル分離、ドキュメント整備

### Phase 3: Argodeブランド統一・クリーンアップ（完了 ✅）
- **ブランド統一**: adv_engine → argode アドオン名変更
- **参照修正**: AdvSystem → ArgodeSystem 全体統一
- **レガシーファイル削除**: 未使用テストファイル・サンプルスクリプト削除
- **ドキュメント整備**: 包括的なREADME作成、使い方ガイド充実
- **自動発見システム**: カスタムコマンド手動登録→自動発見に移行

### 技術的成果
- **パフォーマンス向上**: ラベルスキャン 20→5 labels（75%削減）
- **メモリ効率化**: 単一オートロード統合による最適化
- **拡張性確保**: プラグイン形式カスタムコマンドシステム
- **v1互換性維持**: 既存スクリプトの動作保証
- **プロジェクト整理**: 不要ファイル削除によるメンテナンス性向上

### 削除されたレガシーファイル（クリーンアップ実施）
以下のファイルは使用されておらず、v2アーキテクチャで不要になったため削除されました：

#### テストファイル類
- `test_visual_effects_refactor.gd` - 構文エラー・未使用
- `test_custom_commands.gd` - 古いv1テストコード
- `test_custom_command_scenario.gd` - 古いテスト実装
- `register_test_commands.gd` - 手動登録テストコード

#### サンプルファイル類
- `src/scenes/gui/usage_sample.gd/.tscn` - 古いv1サンプルUI
- `custom/CustomCommandRegistration.gd` - v1手動登録システム
- `src/CustomCommandReceiver.gd` - v1信号ベース処理システム

#### 理由
- **v1→v2移行**: 手動処理→自動発見システムに変更
- **信号システム変更**: 固定信号→動的信号(`on_dynamic_signal_emitted`)に移行
- **ドキュメント化**: サンプルコード→包括的なREADMEガイドに置き換え
- **メンテナンス性向上**: "ゴミファイル"削減によるプロジェクト整理