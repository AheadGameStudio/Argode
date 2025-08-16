# ArgodeScreen.gd 関数分析レポート

## ファイル統計
- **総行数**: 1,357行
- **総関数数**: 62個
- **ファイルサイズ**: 59KB
- **分析日**: 2024年12月

## 責任領域別関数分類

### 1. 初期化・ライフサイクル管理 (9関数)
```
111: func _ready()
142: func _emit_screen_ready()
173: func on_screen_ready()
177: func on_screen_shown(parameters: Dictionary = {})
183: func on_screen_hidden()
188: func on_screen_closing() -> bool
195: func show_screen(parameters: Dictionary = {})
202: func hide_screen()
207: func close_screen(return_val: Variant = null)
```

### 2. 画面・ナビゲーション管理 (4関数)
```
224: func call_screen(screen_path: String, parameters: Dictionary = {}) -> Variant
234: func jump_to(label_name: String)
241: func call_label(label_name: String)
892: func set_script_path(path: String, label: String = "start")
```

### 3. 変数・パラメータ管理 (6関数)
```
250: func set_variable(var_name: String, value: Variant)
258: func get_variable(var_name: String) -> Variant
268: func get_parameter(key: String, default_value: Variant = null) -> Variant
272: func has_parameter(key: String) -> bool
276: func get_screen_name() -> String
280: func is_active() -> bool
```

### 4. UI要素自動検出・設定 (4関数)
```
286: func _auto_discover_ui_elements()
323: func _get_node_from_path_or_fallback(node_path: NodePath, fallback_name: String, parent_node: Node = null) -> Node
346: func _count_exported_paths() -> int
623: func _setup_ui_manager_integration()
```

### 5. タイプライター効果管理 (6関数)
```
360: func _initialize_typewriter()
427: func _on_typewriter_started(_text: String)
434: func _on_typewriter_finished()
453: func _on_typewriter_skipped()
483: func _on_character_typed(_character: String, _position: int)
493: func on_character_typed(_character: String, _position: int)
```

### 6. Ruby文字（ふりがな）システム (11関数) ⭐ 最大責任領域
```
402: func _setup_ruby_rich_text_label()
961: func _draw()
990: func _draw_single_ruby(ruby_info: Dictionary)
1020: func setup_ruby_fonts()
1034: func simple_ruby_line_break_adjustment(text: String) -> String
1083: func _will_ruby_cross_line(...) -> bool
1110: func set_text_with_ruby_draw(text: String)
1146: func _update_ruby_visibility_for_position(typed_position: int)
1187: func _calculate_ruby_positions_for_visible(...)
1263: func _calculate_ruby_positions(rubies: Array, main_text: String)
1340: func _parse_ruby_syntax(text: String) -> Dictionary
1395: func _reverse_ruby_conversion(bbcode_text: String) -> String
1434: func get_current_ruby_data() -> Array
1440: func get_message_label()
1445: func get_adjusted_text() -> String
```

### 7. レイヤー・画面構成管理 (4関数)
```
522: func _ensure_layer_manager_initialization()
539: func _initialize_layer_mappings()
579: func _get_layer_from_path_or_fallback(...)
920: func _initialize_layer_manager()
```

### 8. カスタムコマンド・シグナル処理 (3関数)
```
606: func _connect_custom_command_signals()
613: func _on_dynamic_signal_emitted(...)
617: func on_dynamic_signal_emitted(...)
```

### 9. メッセージ表示・選択肢システム (6関数)
```
672: func show_message(character_name: String = "", message: String = "", name_color: Color = Color.WHITE, override_multi_label_ruby: bool = false)
806: func show_choices(choices: Array, is_numbered: bool = false)
831: func hide_ui()
863: func _on_choice_selected(choice_index: int)
874: func _clear_choice_buttons()
947: func set_message_window_visible(visible: bool)
```

### 10. 入力処理・イベント管理 (2関数)
```
842: func _unhandled_input(event)
501: func _on_glossary_link_clicked(meta: Variant)
```

### 11. スクリプト実行・自動化 (1関数)
```
644: func _start_auto_script()
```

### 12. ユーティリティ・デバッグ (2関数)
```
883: func _process_escape_sequences(text: String) -> String
900: func debug_info() -> Dictionary
```

## 責任分離候補分析

### 🔴 Critical - 即座に分離すべき
1. **RubyTextManager** (11関数) - Ruby文字処理は独立性が高い
2. **MessageDisplayManager** (6関数) - メッセージ表示ロジック
3. **LayerManager** (4関数) - レイヤー構成管理

### 🟡 Medium - 段階的分離推奨
4. **TypewriterController** (6関数) - タイプライター効果
5. **ScreenNavigationManager** (4関数) - 画面遷移・ナビゲーション
6. **VariableManager** (6関数) - 変数・パラメータ管理

### 🟢 Low - 最後に検討
7. **UIElementDiscovery** (4関数) - UI要素自動検出
8. **EventHandler** (5関数) - 入力・イベント処理
9. **CustomCommandManager** (3関数) - カスタムコマンド処理

## リファクタリング戦略

### フェーズ1: RubyTextManager分離
- **目標**: Ruby文字処理の完全分離
- **影響範囲**: `show_message`関数との連携部分
- **リスク**: 低（既存のruby修正で十分テスト済み）

### フェーズ2: MessageDisplayManager分離
- **目標**: メッセージ表示ロジックの分離
- **影響範囲**: 選択肢システムとの連携
- **リスク**: 中（ユーザー体験に直結）

### フェーズ3: LayerManager分離
- **目標**: レイヤー構成管理の分離
- **影響範囲**: 初期化プロセス
- **リスク**: 中（画面構成の基盤）

## 推奨アーキテクチャ

```
ArgodeScreen (コントローラー)
├── RubyTextManager (Ruby文字処理)
├── MessageDisplayManager (メッセージ表示)
├── LayerManager (レイヤー管理)
├── TypewriterController (タイプライター効果)
├── ScreenNavigationManager (画面遷移)
└── VariableManager (変数管理)
```

## 次のアクション
1. RubyTextManagerの分離設計から開始
2. 各マネージャーのインターフェース定義
3. 段階的な実装・テスト・コミット
