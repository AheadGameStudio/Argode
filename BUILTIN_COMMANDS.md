# 組み込みコマンドリファレンス - Argode v2

Argode v2で標準サポートされている基本コマンド一覧です。

## 🏷️ フロー制御

### `label`
ラベル定義。ジャンプ先の目印となります。
```rgd
label start:
label chapter1_ending:
```

### `jump`
指定ラベルにジャンプ。
```rgd
jump start
jump chapter1_ending
```

### `call`
サブルーチン呼び出し。returnで呼び出し元に戻ります。
```rgd
call common_function
call ending_sequence
```

### `return`
callで呼び出された場所に戻る。
```rgd
return
```

## 🤔 選択肢・分岐

### `menu`
選択肢メニューを表示。
```rgd
menu:
    "選択肢1":
        jump choice1_path
    "選択肢2":
        jump choice2_path
```

### `if` / `elif` / `else`
条件分岐。
```rgd
if variable_name > 10:
    "変数が10より大きいです"
elif variable_name == 5:
    "変数は5です"
else:
    "その他の値です"
```

## 👤 キャラクター・シーン表示

### `show`
キャラクターまたはControlシーンを表示。

#### キャラクター表示（従来機能）
```rgd
show character_name
show character_name at left
show character_name happy
show yuko happy at center with fade
```

#### Controlシーン表示（v2.1新機能）
```rgd
show scene_id scene path/to/scene.tscn
show ui_panel scene res://scenes/ui/panel.tscn at center
show popup_menu scene res://ui/menu.tscn at right with fade
```

**パラメータ：**
- `character_name` または `scene_id`: 表示対象の識別子
- `expression`: キャラクターの表情（キャラクター表示時）
- `scene`: Controlシーン表示の指示キーワード
- `scene_path`: 表示するシーンファイルのパス
- `at position`: 表示位置（left, center, right）
- `with transition`: トランジション効果（fade, slide_from_left, slide_from_right, none）

**使用例：**
```rgd
# キャラクター表示
show yuko happy at left with fade
show saitos normal at right

# Controlシーン表示
show status_panel scene res://ui/status.tscn at center with fade
show inventory scene res://ui/inventory.tscn at right with slide_from_right
```

### `hide`
キャラクターを非表示。
```rgd
hide character_name
hide all
```

## 🖼️ 背景・シーン

### `scene`
背景シーンを変更。
```rgd
scene background_image
scene school_hallway with fade
```

### `with`
トランジション効果を適用。
```rgd
with fade
with dissolve
with wiperight
```

## 🧮 変数・データ

### `set`
変数に値を設定。
```rgd
set player_name = "太郎"
set score = 100
set flag_completed = true
```

## 💬 テキスト表示

### ナレーター（台詞なし）
直接テキストを記述でナレーター表示。
```rgd
"これはナレーションです。"
```

### キャラクター台詞
キャラクター名とコロンで台詞を記述。
```rgd
character_name "こんにちは！"
太郎 "元気だよ。"
```

## 🪟 UI制御

### `window`
Argode UI全体（CanvasLayer）の表示状態を制御。
```rgd
window show  # UI全体を常に表示
window hide  # UI全体を常に非表示
window auto  # 自動制御（デフォルト）

# トランジション効果付き
window show with fade
window hide with dissolve
window auto with slide_down
```

**構文:**
```rgd
window <action> [with <transition>]
```

**パラメータ:**
- `<action>` - `show`, `hide`, `auto` のいずれか
- `<transition>` - トランジション効果（fade, dissolve, slide_down 等）

**制御範囲:**
- メッセージボックス
- キャラクター名表示  
- 選択肢ボタン
- その他すべてのArgode UI要素

**使用ケース:**
- `window show` - バトルシステムでUI全体を常時表示したい場合
- `window hide` - マップ探索やパズルゲームで画面全体を使いたい場合  
- `window auto` - 通常のビジュアルノベル（メッセージ表示時のみ表示）

**トランジション効果:**
- `fade` - フェードイン・フェードアウト
- `dissolve` - ディゾルブ効果
- `slide_down` / `slide_up` / `slide_left` / `slide_right` - スライド効果

**技術仕様:**
- UIManager（CanvasLayer）のvisibleプロパティを制御
- トランジション効果はTransitionPlayerで処理
- HIDEモード時でもコンソールログは出力される（デバッグ用）
- トランジション中はスクリプト実行が一時停止

**例:**
```rgd
# マップ探索開始（UIをディゾルブで非表示）
window hide with dissolve
call_screen map_explorer

# バトル開始（UIをフェードで表示）
window show with fade
call_screen battle_system

# 通常会話に戻る（自動制御、スライドで表示）
window auto with slide_down
character_name "お疲れ様でした！"
```