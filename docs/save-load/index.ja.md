# セーブ・ロードシステム

Argodeシステムは、スクリーンショットサムネイルや柔軟なスロット管理などの高度な機能を備えた包括的なセーブ・ロード機能を提供し、プレイヤーがゲームの進行状況を保存し、後で完全な状態で復元できるようにします。

## 概要

セーブ・ロードシステムは以下を保存します：
- **ゲーム変数**: 全ての変数の状態と値
- **キャラクター状態**: キャラクターの位置、表情、表示状態
- **背景状態**: 現在の背景シーンとレイヤー
- **オーディオ状態**: 現在のBGM、音量設定
- **スクリプト進行状況**: 現在のスクリプト位置とコールスタック
- **スクリーンショットサムネイル**: セーブ状態の視覚プレビュー（Base64エンコード）

## スクリーンショットサムネイル

システムは自動的にスクリーンショットを撮影して、セーブ状態の視覚プレビューを提供します。

### 一時スクリーンショット

セーブサムネイルにUI要素が含まれないよう、一時スクリーンショット機能を使用してください：

```rgd
# メニューを開く前に現在のゲームシーンを撮影
capture

# メニューやUIを表示（これは撮影されません）
ui pause_menu show

# クリーンなスクリーンショットでセーブ
save 1 "チャプター完了"
```

### 自動スクリーンショット処理

- **一時スクショ優先**: 利用可能な場合は一時スクリーンショットを使用
- **リアルタイム代替**: 一時スクリーンショットがない場合は現在の画面を撮影
- **自動クリーンアップ**: セーブ・ロード後に一時スクリーンショットが自動削除
- **有効期限**: 一時スクリーンショットは5分後に期限切れ

### スクリーンショット設定

```gdscript
# SaveLoadManager.gd内
const ENABLE_SCREENSHOTS = true        # スクリーンショット有効/無効
const SCREENSHOT_WIDTH = 200          # サムネイル幅
const SCREENSHOT_HEIGHT = 150         # サムネイル高さ
const SCREENSHOT_QUALITY = 0.7        # JPEG品質（0.0-1.0）
```

## 基本的な使用方法

### ビルトインコマンド

`.rgd` スクリプトファイル内で直接これらのコマンドを使用できます：

```argode
# 一時スクリーンショットを撮影（メニューを開く前に）
capture

# スロット1にセーブ（スロット0はオートセーブ専用）
save 1

# スロット2にカスタム名でセーブ
save 2 "ボス戦前"

# オートセーブスロットからロード
load 0

# 手動セーブスロットからロード
load 1
```

### セーブスロット

- **設定可能なスロット**: デフォルト10スロット（オートセーブ1 + 手動セーブ9）
- **オートセーブ**: スロット0がオートセーブ機能専用
- **手動セーブ**: スロット1以降がユーザーセーブ用
- **スロット管理**: 各スロットはスクリーンショットサムネイル付きで完全なゲーム状態を保存

## プログラムAPI

### ArgodeSystemメソッド

```gdscript
# 指定スロットにゲームをセーブ
var success = ArgodeSystem.save_game(slot_number, "セーブ名")

# 指定スロットからゲームをロード
var success = ArgodeSystem.load_game(slot_number)

# セーブ情報を取得（スクリーンショットデータ含む）
var save_info = ArgodeSystem.get_save_info(slot_number)

# オートセーブ機能
var success = ArgodeSystem.SaveLoadManager.auto_save()
var success = ArgodeSystem.SaveLoadManager.load_auto_save()

# 一時スクリーンショット管理
var success = ArgodeSystem.capture_temp_screenshot()
var has_screenshot = ArgodeSystem.has_temp_screenshot()
ArgodeSystem.clear_temp_screenshot()
```

### セーブ情報構造

```gdscript
{
    "save_name": "プレイヤーセーブ",
    "save_date": "2025-08-13T14:30:15",
    "save_time": 1692800215,
    "script_file": "res://scenarios/main.rgd",
    "line_number": 42,
    "has_screenshot": true,
    "screenshot": "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQ..."  # Base64画像データ
}
```

## ファイル保存

### 保存場所

**Windows:**
```
%APPDATA%\Godot\app_userdata\[プロジェクト名]\saves\
```

**macOS:**
```
~/Library/Application Support/Godot/app_userdata/[プロジェクト名]/saves/
```

**Linux:**
```
~/.local/share/godot/app_userdata/[プロジェクト名]/saves/
```

### ファイル構造

```
saves/
├── slot_0.save    # オートセーブスロット
├── slot_1.save    # 手動セーブスロット1
├── slot_2.save    # 手動セーブスロット2
├── ...
└── slot_9.save    # 手動セーブスロット9
```

## セキュリティと暗号化

### 暗号化設定

システムはセーブデータ保護のためのファイル暗号化をサポートしています：

```gdscript
# SaveLoadManager.gd内
const ENABLE_ENCRYPTION = true                    # 暗号化を有効/無効
const ENCRYPTION_KEY = "your_encryption_key"     # 暗号化キー
```

### 暗号化機能

- **AES暗号化**: Godotの組み込み暗号化を使用
- **自動**: 透明な暗号化・復号化
- **設定可能**: プロジェクトごとに有効・無効を設定可能

### 本番環境での推奨事項

本番ビルドでは以下を検討してください：

```gdscript
# 環境変数を使用
var encryption_key = OS.get_environment("GAME_SAVE_KEY")

# ユーザー固有キーを生成
var user_key = OS.get_unique_id() + "salt_string"
```

## エラーハンドリング

### 一般的なエラーケース

```gdscript
# セーブ結果をチェック
if not ArgodeSystem.save_game(0, "マイセーブ"):
    print("セーブに失敗しました！")

# ロード結果をチェック
if not ArgodeSystem.load_game(0):
    print("ロードに失敗 - ファイルが見つからないか破損しています")

# スロット番号を検証
if slot < 0 or slot >= 10:
    print("無効なスロット番号です")
```

### エラーシグナル

```gdscript
# セーブ・ロードシグナルに接続
ArgodeSystem.SaveLoadManager.save_failed.connect(_on_save_failed)
ArgodeSystem.SaveLoadManager.load_failed.connect(_on_load_failed)

func _on_save_failed(slot: int, error: String):
    print("スロット ", slot, " のセーブに失敗: ", error)

func _on_load_failed(slot: int, error: String):
    print("スロット ", slot, " のロードに失敗: ", error)
```

## 高度な機能

### セーブデータ構造

セーブファイルには以下が含まれます：

```json
{
    "version": "2.0",
    "slot": 1,
    "save_name": "プレイヤーセーブ",
    "save_date_string": "2025-08-13T14:30:15",
    "save_time": 1692800215,
    "screenshot": "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQ...",
    "variables": {
        "player_name": "主人公",
        "level": 5,
        "gold": 1000
    },
    "characters": {},
    "background": {},
    "audio": {
        "volume_settings": {
            "master_volume": 1.0,
            "bgm_volume": 0.8,
            "se_volume": 0.9
        }
    },
    "current_script_path": "res://scenarios/main.rgd",
    "current_line_index": 42,
    "call_stack": []
}
```

### スクリーンショットの操作

```gdscript
# セーブデータからスクリーンショットを取得
var save_info = ArgodeSystem.get_save_info(slot)
if save_info.has("screenshot"):
    var texture = ArgodeSystem.SaveLoadManager.create_image_texture_from_screenshot(
        save_info["screenshot"]
    )
    # UIでテクスチャを使用
    save_thumbnail.texture = texture
```

### カスタムセーブデータ

カスタムデータでセーブシステムを拡張：

```gdscript
# カスタムスクリプト内
func add_custom_save_data(save_data: Dictionary):
    save_data["custom_data"] = {
        "achievements": unlocked_achievements,
        "statistics": game_statistics
    }
```

## ベストプラクティス

### セーブの命名

```gdscript
# 分かりやすいセーブ名を使用
ArgodeSystem.save_game(1, "第1章クリア")
ArgodeSystem.save_game(2, "最終ボス戦前")

# オートセーブは命名不要
ArgodeSystem.SaveLoadManager.auto_save()
```

### オートセーブ統合

```gdscript
# 重要な場面でオートセーブ
func on_chapter_complete():
    ArgodeSystem.SaveLoadManager.auto_save()

func on_important_choice():
    ArgodeSystem.SaveLoadManager.auto_save()
```

### スクリーンショットのベストプラクティス

```gdscript
# UI操作前にクリーンなスクリーンショットを撮影
func open_save_menu():
    # 最初に現在のゲーム状態を撮影
    ArgodeSystem.capture_temp_screenshot()
    
    # その後メニューUIを表示
    show_save_menu()

func save_game_with_clean_thumbnail(slot: int, name: String):
    # スクリーンショットはメニューを開く前に既に撮影済み
    ArgodeSystem.save_game(slot, name)
```

### セーブ検証

```gdscript
# ロード前にセーブの存在をチェック
var save_info = ArgodeSystem.get_save_info(slot)
if save_info.is_empty():
    print("スロット ", slot, " にセーブデータがありません")
else:
    ArgodeSystem.load_game(slot)
```

## トラブルシューティング

### よくある問題

1. **セーブが動作しない**
   - ファイル権限を確認
   - ディスク容量を確認
   - 暗号化設定を確認

2. **ロードが失敗する**
   - セーブファイルの存在を確認
   - バージョン互換性を確認
   - 暗号化キーを検証

3. **パフォーマンスの問題**
   - 大きなセーブファイルは遅延を引き起こす可能性
   - セーブデータの圧縮を検討
   - UIには非同期操作を使用

### デバッグ情報

```gdscript
# セーブシステムの状態を取得
print("暗号化有効: ", ArgodeSystem.SaveLoadManager.is_encryption_enabled())
print("セーブディレクトリ: ", ArgodeSystem.SaveLoadManager.get_save_directory())
print("全セーブ情報: ", ArgodeSystem.SaveLoadManager.get_all_save_info())
```

## 関連項目

- [変数システム](../variables/index.ja.md)
- [キャラクター管理](../characters/index.ja.md)
- [オーディオシステム](../audio/index.ja.md)
