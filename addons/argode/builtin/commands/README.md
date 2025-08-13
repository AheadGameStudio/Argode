# Argode Built-in Commands

このディレクトリには、Argodeエンジンの組み込みカスタムコマンドが格納されています。これらのコマンドは、Argodeシステムの初期化時に自動的に検出・登録されます。

## 含まれるコマンド

### SetCommand.gd
- **コマンド名**: `set`
- **説明**: 変数に値を設定（ドット記法サポート・辞書自動作成）
- **使用例**: 
  - `set player_name = "主人公"`
  - `set player.level = 5` (辞書の個別キー設定・playerが存在しなければ自動作成)
  - `set player.stats.hp = 100` (ネストした辞書も自動作成)
  - `set settings.audio.bgm = 0.8` (多層ネストも対応)

### SetArrayCommand.gd
- **コマンド名**: `set_array`  
- **説明**: 配列リテラルから変数に配列を設定
- **使用例**: `set_array inventory ["sword", "potion", "key"]`

### SetDictCommand.gd
- **コマンド名**: `set_dict`
- **説明**: 辞書リテラルから変数に辞書を設定
- **使用例**: `set_dict player {"name": "主人公", "level": 1}`

### UICommand.gd  
- **コマンド名**: `ui`
- **説明**: UI要素を制御（表示・非表示・呼び出し・解放など）
- **使用例**: 
  - `ui show path/to/scene.tscn at center with fade`
  - `ui call path/to/screen.tscn`
  - `ui free`
  - `ui list`

### WaitCommand.gd
- **コマンド名**: `wait`  
- **説明**: 指定時間待機してからスクリプト実行を継続
- **使用例**: `wait 2.0` （2秒待機）

## 設計方針

- これらのコマンドは**最優先で登録**されます（他のカスタムコマンドより先）
- `res://custom/commands/` にある同名コマンドがあっても、組み込みコマンドが優先されます
- 各コマンドは `BaseCustomCommand` を継承し、標準的なカスタムコマンドAPIに準拠しています

## カスタマイズ

これらの組み込みコマンドを無効化したい場合は：

1. `res://custom/commands/` に同じコマンド名で別実装を配置（上書き）
2. または、`ArgodeSystem._auto_discover_and_register_commands()` の検索対象ディレクトリから `"res://addons/argode/builtin/commands/"` を削除

## 開発者向け

新しい組み込みコマンドを追加する場合：

1. このディレクトリに `.gd` ファイルを作成
2. `BaseCustomCommand` を継承したクラスとして実装  
3. `@tool` アノテーションを必須で付与
4. ユニークなクラス名を設定（例：`BuiltinXXXCommand`）
5. 自動発見システムが自動的に検出・登録します
