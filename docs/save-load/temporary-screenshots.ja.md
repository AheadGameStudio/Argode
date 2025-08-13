# 一時スクリーンショット

一時スクリーンショット機能は、UI要素が表示される前にクリーンなゲームシーンを撮影することで、セーブサムネイルがメニューやダイアログではなく実際のゲームプレイ内容を表示することを保証します。

## 概要

プレイヤーがセーブメニューを開くとき、現在の画面にはセーブサムネイルに表示されるべきではないUI要素が含まれています。一時スクリーンショットシステムは以下によってこの問題を解決します：

1. **事前撮影**: UIが表示される前にスクリーンショットを撮影
2. **一時保存**: スクリーンショットを一時的にメモリに保持
3. **優先使用**: 利用可能な場合、セーブ時に一時スクリーンショットを使用
4. **自動クリーンアップ**: 使用後に一時スクリーンショットを自動削除

## 使用パターン

### 基本的な使用方法

```argode
# シナリオスクリプト内で
scene classroom
show yuko happy center
yuko "なんて美しい日でしょう！"

# メニューを開く前にクリーンなスクリーンショットを撮影
capture

# UI操作は保存されるスクリーンショットに影響しません
ui save_menu show
```

### プログラムによる使用

```gdscript
# UIを表示する前に
func show_pause_menu():
    # 現在のゲーム状態を撮影
    ArgodeSystem.capture_temp_screenshot()
    
    # UIを表示 - これは撮影されません
    pause_menu.show()

# セーブ時にクリーンなスクリーンショットを使用
func save_to_slot(slot: int, name: String):
    ArgodeSystem.save_game(slot, name)  # 利用可能であれば一時スクショを使用
```

### 自動撮影ヘルパー

```gdscript
# UIシステム用の組み込みヘルパー
func show_menu_with_capture(menu_name: String):
    var save_manager = ArgodeSystem.SaveLoadManager
    save_manager.auto_capture_before_ui(menu_name)
    
    # メニューUIを表示
    show_menu(menu_name)
```

## 技術詳細

### 保存とライフサイクル

- **メモリのみ**: スクリーンショットはRAMに保存、ディスクには保存されません
- **Base64形式**: 圧縮されたJPEGがBase64文字列としてエンコード
- **固定サイズ**: サムネイルは200x150ピクセルにリサイズ
- **自動期限切れ**: 使用されない場合、5分後にスクリーンショットが期限切れ

### 動作ロジック

```gdscript
# セーブ時に、システムは以下をチェックします：
func _get_screenshot_for_save() -> String:
    if has_valid_temp_screenshot():
        return temp_screenshot_data  # 一時スクリーンショットを使用
    else:
        return capture_current_screen()  # リアルタイム撮影にフォールバック
```

### クリーンアップイベント

一時スクリーンショットは以下の場合に自動的にクリアされます：

- **セーブ完了**: 任意のスロットへの正常なセーブ後
- **ロード完了**: 任意のスロットからのロード後
- **期限切れ**: 5分間の非活動後
- **手動クリア**: コードで明示的にクリアされた時

## API リファレンス

### コアメソッド

```gdscript
# SaveLoadManagerメソッド
capture_temp_screenshot() -> bool              # 一時スクリーンショットを撮影
has_temp_screenshot() -> bool                  # 有効な一時スクショの存在チェック
get_temp_screenshot_age() -> float             # 経過時間を秒で取得
auto_capture_before_ui(ui_name: String) -> bool  # UI操作用ヘルパー

# ArgodeSystemラッパーメソッド
ArgodeSystem.capture_temp_screenshot() -> bool
ArgodeSystem.has_temp_screenshot() -> bool
ArgodeSystem.clear_temp_screenshot()
```

### 設定定数

```gdscript
# SaveLoadManager.gd内
const ENABLE_SCREENSHOTS = true        # スクリーンショット機能の有効/無効
const SCREENSHOT_WIDTH = 200          # サムネイル幅（ピクセル）
const SCREENSHOT_HEIGHT = 150         # サムネイル高さ（ピクセル）
const SCREENSHOT_QUALITY = 0.7        # JPEG品質（0.0-1.0）
const TEMP_SCREENSHOT_LIFETIME = 300.0  # 期限切れ時間（秒）（5分）
```

## ベストプラクティス

### 撮影するタイミング

**良いタイミング:**
```argode
# 選択肢の前に
narrator "あなたの道を選んでください..."
capture
choice "左に行く" go_left
choice "右に行く" go_right
```

**メニューアクセス前:**
```gdscript
func on_menu_key_pressed():
    ArgodeSystem.capture_temp_screenshot()
    show_game_menu()
```

### 撮影すべきではないもの

**以下の間は撮影を避けてください:**
- ローディング画面
- トランジション効果
- テキストボックスやダイアログ（クリーンな背景が欲しい場合）
- その他のUI要素

### セーブシステムとの統合

```gdscript
# セーブメニュー統合の例
class SaveMenu:
    func _ready():
        # このメニューを表示する前に撮影は既に完了
        populate_save_slots()
    
    func save_to_slot(slot: int):
        var save_name = save_name_input.text
        # メニューを開く前に撮影された一時スクリーンショットを使用
        ArgodeSystem.save_game(slot, save_name)
        
        # 一時スクリーンショットはセーブ後に自動的にクリア
        close_menu()
```

## トラブルシューティング

### よくある問題

**スクリーンショットが撮影されない:**
- `ENABLE_SCREENSHOTS` が true かチェック
- ビューポートアクセス権限を確認
- capture コマンドが正常に実行されたか確認

**スクリーンショットにUIが写る:**
- UIを表示する前に `capture` が呼ばれているか確認
- タイミングをチェック - 撮影中にUIが表示されている可能性

**スクリーンショットが期限切れになる:**
- デフォルト寿命は5分間
- 実際にセーブする時により近いタイミングで撮影
- タイミングを確認するため `get_temp_screenshot_age()` をチェック

### デバッグ情報

```gdscript
var save_manager = ArgodeSystem.SaveLoadManager
print("一時スクショあり: ", save_manager.has_temp_screenshot())
print("スクショ経過時間: ", save_manager.get_temp_screenshot_age(), " 秒")
print("スクショ機能有効: ", save_manager.is_screenshot_enabled())
```

## 関連項目

- [セーブ・ロードシステム](index.ja.md)
- [UI統合](../ui/index.ja.md)
- [ベストプラクティス](../getting-started/best-practices.ja.md)
