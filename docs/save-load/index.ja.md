# セーブ・ロードシステム

Argodeシステムは、Ren'Pyに似た包括的なセーブ・ロード機能を提供し、プレイヤーがゲームの進行状況を保存し、後で完全な状態で復元できるようにします。

## 概要

セーブ・ロードシステムは以下を保存します：
- **ゲーム変数**: 全ての変数の状態と値
- **キャラクター状態**: キャラクターの位置、表情、表示状態
- **背景状態**: 現在の背景シーンとレイヤー
- **オーディオ状態**: 現在のBGM、音量設定
- **スクリプト進行状況**: 現在のスクリプト位置とコールスタック

## 基本的な使用方法

### ビルトインコマンド

`.rgd` スクリプトファイル内で直接これらのコマンドを使用できます：

```renpy
# スロット0にセーブ
save 0

# スロット1にカスタム名でセーブ
save 1 "ボス戦前"

# スロット0からロード
load 0

# スロット1からロード
load 1
```

### セーブスロット

- **10個のセーブスロット**: スロット0-9が利用可能
- **オートセーブ**: スロット9はオートセーブ機能専用
- **スロット管理**: 各スロットは完全なゲーム状態を保存

## プログラムAPI

### ArgodeSystemメソッド

```gdscript
# 指定スロットにゲームをセーブ
var success = ArgodeSystem.save_game(slot_number, "セーブ名")

# 指定スロットからゲームをロード
var success = ArgodeSystem.load_game(slot_number)

# セーブ情報を取得
var save_info = ArgodeSystem.get_save_info(slot_number)

# オートセーブ機能
var success = ArgodeSystem.SaveLoadManager.auto_save()
var success = ArgodeSystem.SaveLoadManager.load_auto_save()
```

### セーブ情報構造

```gdscript
{
    "save_name": "プレイヤーセーブ",
    "save_date": "2025-08-13T14:30:15",
    "save_time": 1692800215,
    "script_file": "res://scenarios/main.rgd",
    "line_number": 42
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
├── slot_0.save    # セーブスロット0
├── slot_1.save    # セーブスロット1
├── ...
└── slot_9.save    # オートセーブスロット
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
    "slot": 0,
    "save_name": "プレイヤーセーブ",
    "save_date_string": "2025-08-13T14:30:15",
    "save_time": 1692800215,
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
ArgodeSystem.save_game(0, "第1章クリア")
ArgodeSystem.save_game(1, "最終ボス戦前")
```

### オートセーブ統合

```gdscript
# 重要な場面でオートセーブ
func on_chapter_complete():
    ArgodeSystem.SaveLoadManager.auto_save()

func on_important_choice():
    ArgodeSystem.SaveLoadManager.auto_save()
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
