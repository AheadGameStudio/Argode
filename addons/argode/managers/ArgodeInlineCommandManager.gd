# インラインコマンド管理
# ステートメント内で直接実行されるコマンドを管理
# ArgodeSystemの一部として、他のマネージャーやサービスと連携する

# 1. raw_textを受け取る。
# 2. TagTokenizerを呼び出し、テキストをトークンに分解させる。
# 3. トークンを一つずつループ処理する。
# 4. トークンが特殊タグであれば、TagRegistryに問い合わせ、対応するコマンドクラス（RubyCommandなど）を取得する。
# 5. そのコマンドを実行し、RichTextConverterに処理を委譲する。
# 6. RichTextConverterが返したBBCodeを結合して、最終的なRichTextLabel用のテキストを返す。

extends RefCounted
class_name ArgodeInlineCommandManager

var _raw_text: String
var tag_tokenizer: ArgodeTagTokenizer
var tag_registry: ArgodeTagRegistry
var rich_text_converter: ArgodeRichTextConverter
