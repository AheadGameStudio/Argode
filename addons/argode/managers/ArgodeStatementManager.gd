# # ステートメント管理
# 各ステートメント（インデントブロック含む）を管理
# 再帰的な構造とし、現在の実行コンテキストを管理
# StatementManagerは、個々のコマンドが持つ複雑なロジックを直接は扱わず、全体の流れを制御することに特化しています。
# スクリプト全体を俯瞰し、実行を指示するのがStatementManagerの役割。
# 一つひとつの具体的なタスク（台詞表示、ルビ描画など）を実行するのが各コマンドやサービスの役割。

extends RefCounted
class_name ArgodeStatementManager
