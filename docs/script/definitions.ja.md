# 定義リファレンス

Argodeの定義を使用すると、さまざまなアセットやエンティティを事前に定義でき、ビジュアルノベルスクリプト全体で簡単にアクセスして再利用できます。定義を一元化することで、メインのストーリースクリプトをクリーンに保ち、物語の流れに集中できます。

## 定義ファイル

定義は`.rgd`ファイルのどこにでも配置できますが、`definitions/`ディレクトリ内の専用の定義ファイル（例: `definitions/characters.rgd`、`definitions/assets.rgd`）に整理することを強くお勧めします。Argodeは、このディレクトリにあるすべての`.rgd`ファイルを起動時に自動的にロードします。

## 定義の種類

### キャラクター定義（`character`）

表示名と、オプションでダイアログのデフォルトの色を含むキャラクターを定義します。

**構文:**
```rgd
character <名前> "<表示名>" [color=<16進数カラーコード>]
```

-   `<名前>`: キャラクターの一意の識別子（例: `alice`、`narrator`）。これはスクリプトで使用します。
-   `<表示名>`: ダイアログボックスに表示される名前。
-   `color`: (オプション) キャラクターのダイアログテキストの16進数カラーコード（例: `#ff69b4`）。

**例:**

```rgd
character alice "アリス" color=#ff69b4
character bob "ボブ" color=#87ceeb
character narrator "ナレーター" color=#ffffff
```

**スクリプトでの使用法:**

```rgd
alice "こんにちは、ボブ！"
bob "やあ、アリス！"
narrator "彼らはお互いに挨拶した。"
```

### 画像定義（`image`）

画像（背景、キャラクターのスプライト、CG）をタグと名前で定義し、ファイルパスにマッピングします。これにより、スクリプト内で長いパスではなく、シンプルな名前で画像を参照できます。

**構文:**
```rgd
image <タグ> <名前> "<画像へのパス>"
```

-   `<タグ>`: 画像のカテゴリ（例: 背景用の`bg`、キャラクターのスプライト用の`char`、CG用の`cg`）。
-   `<名前>`: そのタグ内で画像の一意の識別子（例: `forest_day`、`alice_happy`）。
-   `<画像へのパス>`: 画像ファイルへのリソースパス（例: `"res://assets/images/backgrounds/forest_day.png"`）。

**例:**

```rgd
image bg forest_day "res://assets/images/backgrounds/forest_day.png"
image bg city_night "res://assets/images/backgrounds/city_night.png"
image char alice_happy "res://assets/images/characters/alice_happy.png"
```

**スクリプトでの使用法:**

```rgd
scene forest_day with fade # 'bg'タグを暗黙的に使用
show alice_happy at center # 'char'タグを暗黙的に使用
```

### オーディオ定義（`audio`）

オーディオファイル（音楽、効果音）をタグと名前で定義し、ファイルパスにマッピングします。これにより、スクリプトでのオーディオ再生が簡素化されます。

**構文:**
```rgd
audio <タグ> <名前> "<オーディオへのパス>"
```

-   `<タグ>`: オーディオのカテゴリ（例: 背景音楽用の`music`、効果音用の`sfx`）。
-   `<名前>`: そのタグ内でオーディオの一意の識別子（例: `peaceful`、`door_open`）。
-   `<オーディオへのパス>`: オーディオファイルへのリソースパス（例: `"res://assets/audio/music/peaceful.ogg"`）。

**例:**

```rgd
audio music peaceful "res://assets/audio/music/peaceful.ogg"
audio sfx door_open "res://assets/audio/sfx/door_open.wav"
```

**スクリプトでの使用法:**

```rgd
play_music peaceful
play_sound door_open
```

### シェーダー定義（`shader`）

画面または特定のレイヤーに適用できるカスタムシェーダーを定義します。

**構文:**
```rgd
shader <名前> "<シェーダーへのパス>"
```

-   `<名前>`: シェーダーの一意の識別子（例: `blur`、`grayscale`）。
-   `<シェーダーへのパス>`: シェーダーファイルへのリソースパス（例: `"res://shaders/blur_effect.gdshader"`）。

**例:**

```rgd
shader blur_effect "res://shaders/blur_effect.gdshader"
```

**スクリプトでの使用法:**

```rgd
screen_shader blur_effect intensity=0.5
```

## ベストプラクティス

-   **定義の一元化:** 管理と概要を容易にするために、すべての定義を`definitions/`フォルダに保持します。
-   **一貫した命名:** 定義名とタグには、明確で一貫した命名規則を使用します。
-   **タグによる分類:** タグ（画像とオーディオ用）を利用して、アセットを論理的にグループ化します。

---

定義を効果的に使用することで、Argodeスクリプトをよりクリーンで読みやすく、保守しやすくすることができます。
