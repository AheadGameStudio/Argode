# RubyTextManager 設計仕様書

## 概要
ArgodeScreen.gdからRuby文字（ふりがな）処理機能を分離し、専用のマネージャークラスとして独立させる。

## 現在の課題
- ArgodeScreen.gdが1,357行で肥大化
- Ruby関連機能が11関数に分散
- 責任境界が不明確

## 設計目標
1. **単一責任原則**: Ruby文字処理のみに特化
2. **疎結合**: ArgodeScreenとの依存関係を最小化
3. **テスト容易性**: 独立したテストが可能
4. **拡張性**: 新しいRuby機能の追加が容易

## アーキテクチャ設計

### クラス構造
```
RubyTextManager (独立クラス)
├── RubyParser (Ruby構文解析)
├── RubyRenderer (Ruby描画処理)
├── RubyPositionCalculator (位置計算)
└── RubyLayoutAdjuster (レイアウト調整)
```

### 分離対象関数一覧
| 現在の関数 | 移転先 | 責任 |
|------------|--------|------|
| `_parse_ruby_syntax()` | RubyParser | 【漢字｜ふりがな】構文解析 |
| `_reverse_ruby_conversion()` | RubyParser | BBCode⇔Ruby形式変換 |
| `_draw()` | RubyRenderer | Ruby描画エントリーポイント |
| `_draw_single_ruby()` | RubyRenderer | 個別Ruby描画 |
| `setup_ruby_fonts()` | RubyRenderer | フォント設定 |
| `_calculate_ruby_positions()` | RubyPositionCalculator | 基本位置計算 |
| `_calculate_ruby_positions_for_visible()` | RubyPositionCalculator | 可視範囲位置計算 |
| `_update_ruby_visibility_for_position()` | RubyPositionCalculator | 可視性更新 |
| `simple_ruby_line_break_adjustment()` | RubyLayoutAdjuster | 改行調整 |
| `_will_ruby_cross_line()` | RubyLayoutAdjuster | 行跨ぎ判定 |
| `set_text_with_ruby_draw()` | RubyTextManager | メインAPI |

## インターフェース設計

### 1. RubyTextManager (メインクラス)
```gdscript
class_name RubyTextManager
extends RefCounted

# 依存性注入用プロパティ
var message_label: RichTextLabel
var canvas_layer: CanvasLayer
var debug_enabled: bool = false

# コンストラクタ
func _init(label: RichTextLabel, layer: CanvasLayer = null):
    message_label = label
    canvas_layer = layer
    _initialize()

# メインAPI
func set_text_with_ruby(text: String) -> void
func parse_ruby_syntax(text: String) -> Dictionary
func calculate_positions(rubies: Array, main_text: String) -> Array
func update_ruby_visibility(typed_position: int) -> void
func adjust_line_breaks(text: String) -> String

# 設定API
func setup_fonts(main_font: Font = null, ruby_font: Font = null) -> void
func set_debug_mode(enabled: bool) -> void
func get_current_ruby_data() -> Array
```

### 2. RubyParser (構文解析)
```gdscript
class_name RubyParser
extends RefCounted

static func parse_ruby_syntax(text: String) -> Dictionary
static func reverse_ruby_conversion(bbcode_text: String) -> String
static func extract_ruby_matches(text: String) -> Array
```

### 3. RubyRenderer (描画処理)
```gdscript
class_name RubyRenderer
extends RefCounted

var ruby_font: Font
var debug_enabled: bool = false

func draw_rubies(canvas: CanvasItem, ruby_data: Array) -> void
func draw_single_ruby(canvas: CanvasItem, ruby_info: Dictionary) -> void
func setup_fonts(main_font: Font = null, ruby_font: Font = null) -> void
```

### 4. RubyPositionCalculator (位置計算)
```gdscript
class_name RubyPositionCalculator
extends RefCounted

var message_label: RichTextLabel

func calculate_positions(rubies: Array, main_text: String) -> Array
func calculate_visible_positions(visible_rubies: Array, current_text: String) -> Array
func update_visibility_for_position(typed_position: int, ruby_data: Array) -> Array
```

### 5. RubyLayoutAdjuster (レイアウト調整)
```gdscript
class_name RubyLayoutAdjuster
extends RefCounted

var message_label: RichTextLabel

func adjust_line_breaks(text: String) -> String
func will_ruby_cross_line(text: String, ruby_start_pos: int, kanji_part: String, font: Font, font_size: int, container_width: float) -> bool
```

## 移行戦略

### フェーズ1: 基盤クラス作成
1. RubyTextManager.gd 作成
2. 基本インターフェース実装
3. 単体テスト作成

### フェーズ2: パーサー分離
1. RubyParser.gd 作成
2. `_parse_ruby_syntax()` 移植
3. `_reverse_ruby_conversion()` 移植

### フェーズ3: レンダラー分離
1. RubyRenderer.gd 作成
2. `_draw()` 系関数移植
3. フォント設定移植

### フェーズ4: 位置計算分離
1. RubyPositionCalculator.gd 作成
2. 位置計算関数群移植

### フェーズ5: レイアウト調整分離
1. RubyLayoutAdjuster.gd 作成
2. 改行調整機能移植

### フェーズ6: 統合・テスト
1. ArgodeScreen.gd からRuby関数削除
2. RubyTextManager統合
3. 総合テスト・デバッグ

## ArgodeScreen統合パターン

### Before (現在)
```gdscript
class ArgodeScreen:
    func show_message(...):
        # Ruby処理が直接埋め込まれている
        var result = _parse_ruby_syntax(message)
        # ... 複雑な処理
```

### After (分離後)
```gdscript
class ArgodeScreen:
    var ruby_manager: RubyTextManager
    
    func _ready():
        ruby_manager = RubyTextManager.new(message_label, get_canvas_layer())
    
    func show_message(...):
        ruby_manager.set_text_with_ruby(message)
```

## ファイル構成
```
addons/argode/ui/ruby/
├── RubyTextManager.gd       # メインマネージャー
├── RubyParser.gd           # 構文解析
├── RubyRenderer.gd         # 描画処理
├── RubyPositionCalculator.gd # 位置計算
└── RubyLayoutAdjuster.gd   # レイアウト調整
```

## メリット
1. **可読性向上**: ArgodeScreen.gdが大幅に短縮
2. **保守性向上**: Ruby機能の変更が局所化
3. **再利用性**: 他の画面でもRuby機能を使用可能
4. **テスト性**: Ruby機能の独立テストが可能
5. **拡張性**: 新しいRuby機能の追加が容易

## リスク軽減策
1. **段階的移行**: 一つずつ関数を移植
2. **テスト保持**: 既存動作の維持
3. **バックアップ**: 元のコードをコメントで保持
4. **デバッグ継続**: デバッグ機能は最後まで保持
