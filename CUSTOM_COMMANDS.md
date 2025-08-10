# カスタムコマンドリファレンス - Ren' Gd v2

Ren' Gd v2のカスタムコマンド拡張フレームワークにより、シナリオファイル(.rgd)内で豊富な視覚・演出効果を使用できます。

## 📋 サポートされているカスタムコマンド

### 🪟 ウィンドウ操作

#### `window shake`
ウィンドウを揺らす効果。

```rgd
window shake intensity=5.0 duration=0.5
window shake 3.0 0.8  # 位置パラメータ形式
```

**パラメータ:**
- `intensity`: 揺れの強さ（デフォルト: 5.0）
- `duration`: 継続時間（秒）（デフォルト: 0.5）

#### `window fullscreen`
フルスクリーン切り替え。

```rgd
window fullscreen true
window fullscreen false
```

#### `window minimize`
ウィンドウを最小化。

```rgd
window minimize
```

### 📹 カメラエフェクト

#### `camera_shake`
画面全体を揺らす効果。

```rgd
camera_shake intensity=2.0 duration=0.5 type=both
camera_shake 3.0 1.0 horizontal  # 位置パラメータ形式
```

**パラメータ:**
- `intensity`: 揺れの強さ（デフォルト: 1.0）
- `duration`: 継続時間（秒）（デフォルト: 0.5）
- `type`: 揺れの方向 - `both`/`horizontal`/`vertical`（デフォルト: both）

#### `zoom`
ズーム効果。

```rgd
zoom in scale=1.5 duration=1.0
zoom out target=character1
```

**パラメータ:**
- `action`: `in`/`out`（デフォルト: in）
- `scale`: 拡大率（デフォルト: 1.5）
- `duration`: 継続時間（秒）（デフォルト: 1.0）
- `target`: 対象キャラクター名

#### `tint`
画面の色調変更。

```rgd
tint red intensity=0.3 duration=2.0
tint blue intensity=0.5 duration=1.0
tint reset  # 色調リセット
```

**パラメータ:**
- 色名: `red`/`blue`/`green`/`yellow`/`white`/`black`など
- `intensity`: 強度（0.0-1.0）（デフォルト: 0.3）
- `duration`: 継続時間（秒）（デフォルト: 1.0）

#### `blur`
ブラー（ぼかし）効果。

```rgd
blur strength=3.0 duration=1.0
blur off  # ブラー解除
```

**パラメータ:**
- `strength`: ぼかし強度（デフォルト: 2.0）
- `duration`: 継続時間（秒）（デフォルト: 1.0）

### ⚡ 画面エフェクト

#### `screen_flash`
画面フラッシュ効果。

```rgd
screen_flash color=white duration=0.2
screen_flash red 0.5  # 位置パラメータ形式
```

**パラメータ:**
- `color`: 色名またはhex値（デフォルト: white）
- `duration`: 継続時間（秒）（デフォルト: 0.2）

#### `custom_transition`
カスタムトランジション効果。

```rgd
custom_transition spiral speed=2.0 direction=clockwise
```

**パラメータ:**
- 効果名: `spiral`など
- `speed`: 速度（デフォルト: 1.0）
- `direction`: 方向 - `clockwise`/`counterclockwise`

### 📝 テキスト演出

#### `text_animate`
テキストアニメーション効果。

```rgd
text_animate wave amplitude=5.0 frequency=2.0 duration=3.0
text_animate shake intensity=2.0 duration=1.0
text_animate typewriter speed=fast
```

**アニメーション種類:**
- `wave`: 波打ちアニメーション
  - `amplitude`: 振幅（デフォルト: 5.0）
  - `frequency`: 周波数（デフォルト: 2.0）
  - `duration`: 継続時間（デフォルト: 3.0）
- `shake`: テキストシェイク
  - `intensity`: 振動強度（デフォルト: 2.0）
  - `duration`: 継続時間（デフォルト: 0.5）
- `typewriter`: タイプライター速度変更
  - `speed`: `fast`/`slow`/`normal`/`instant`

### 🎞️ UIアニメーション

#### `ui_slide`
UIスライドアニメーション。

```rgd
ui_slide in direction=left duration=0.5
ui_slide out direction=up
```

**パラメータ:**
- `action`: `in`/`out`（デフォルト: in）
- `direction`: `left`/`right`/`up`/`down`（デフォルト: left）
- `duration`: 継続時間（秒）（デフォルト: 0.5）

#### `ui_fade`
UIフェードアニメーション。

```rgd
ui_fade in duration=1.0
ui_fade out alpha=0.3
```

**パラメータ:**
- `action`: `in`/`out`（デフォルト: in）
- `duration`: 継続時間（秒）（デフォルト: 1.0）
- `alpha`: 透明度（0.0-1.0）

### ✨ パーティクルエフェクト

#### `particles`
パーティクル効果表示。

```rgd
particles sparkle intensity=high duration=3.0
particles explosion position=center
```

**エフェクト種類:**
- `sparkle`: スパークル効果
  - `intensity`: `low`/`normal`/`high`（デフォルト: normal）
  - `duration`: 継続時間（秒）（デフォルト: 2.0）
- `explosion`: 爆発効果
  - `position`: 位置 - `center`など（デフォルト: center）

### ⏱️ タイミング制御

#### `wait`
指定時間待機。

```rgd
wait duration=2.0
wait 1.5  # 位置パラメータ形式
```

**パラメータ:**
- `duration`: 待機時間（秒）（デフォルト: 1.0）

### 📳 モバイル機能

#### `vibrate`
端末バイブレーション（モバイル限定）。

```rgd
vibrate duration=100
vibrate pattern=short
```

**パラメータ:**
- `duration`: 振動時間（ミリ秒）（デフォルト: 100）
- `pattern`: 振動パターン - `short`/`long`/`double`

### 🔊 サウンドエフェクト

#### `sound_effect`
効果音再生。

```rgd
sound_effect button_click volume=0.8
sound_effect explosion.ogg
```

**パラメータ:**
- `file`: 音声ファイル名
- `volume`: 音量（0.0-1.0）（デフォルト: 1.0）

## 🛠️ カスタムコマンドの拡張

### 新しいコマンドの追加方法

1. **CustomCommandHandlerにコマンド追加**
```gdscript
# CustomCommandHandler.gd内
func _on_custom_command_executed(command_name: String, parameters: Dictionary, line: String):
    match command_name:
        "my_custom_effect":
            _handle_my_custom_effect(parameters)
```

2. **シグナル定義**
```gdscript
signal my_effect_requested(parameters: Dictionary)
```

3. **UI側でシグナル処理**
```gdscript
# AdvGameUI.gd内
handler.my_effect_requested.connect(_on_my_effect_requested)
```

### パラメータ処理

カスタムコマンドは以下の形式をサポート:

- **キーワードパラメータ**: `command key=value key2=value2`
- **位置パラメータ**: `command arg1 arg2 arg3`
- **混合パラメータ**: `command arg1 key=value`

### デバッグ支援

未知のコマンドは自動的にログ出力され、汎用シグナルとして発行されます:

```
❓ Unknown custom command 'my_command' - forwarding as generic signal
📡 Emitting generic signal: custom_my_command_requested
```

## 📖 使用例

```rgd
# main_demo.rgd - カスタムコマンドサンプル

label demo_start:

"カスタムエフェクトのデモンストレーションを開始します。"

# 基本的なウィンドウ効果
window shake intensity=3.0 duration=0.8
"ウィンドウが揺れました。"

# 画面フラッシュ
screen_flash color=white duration=0.3
"画面が光りました。"

# テキストアニメーション
text_animate shake intensity=2.0 duration=1.0
"テキストがシェイクしています。"

# 待機
wait duration=1.0

# UIアニメーション  
ui_slide in direction=up duration=0.7
"UIがスライドインしました。"

# パーティクルエフェクト
particles sparkle intensity=high duration=3.0
"スパークル効果が表示されました。"

# 色調変更
tint red intensity=0.3 duration=1.5
"画面が赤く染まりました。"

wait duration=2.0

tint reset
"色調がリセットされました。"

"デモンストレーション完了です！"
return
```

## ⚙️ 技術仕様

- **アーキテクチャ**: シグナル駆動型拡張システム
- **パラメータ解析**: 自動型変換（文字列→数値、ブール値など）
- **エラーハンドリング**: 未知コマンドの汎用シグナル転送
- **拡張性**: プラグイン形式で新しいエフェクトを追加可能
- **パフォーマンス**: 非同期実行対応（`await`サポート）

---

このカスタムコマンドフレームワークにより、Ren'Pyライクな豊富な演出表現が可能になり、ゲーム開発者は視覚的に魅力的なアドベンチャーゲームを作成できます。