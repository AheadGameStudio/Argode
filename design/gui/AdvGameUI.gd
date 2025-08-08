extends BaseAdvGameUI
class_name AdvGameUI

func _ready():
	# テスト実装では自動スクリプトを無効化
	auto_start_script = false
	
	# ベースクラスの初期化を呼び出し
	super._ready()
	print("🎨 AdvGameUI (Test Implementation) initialized")
	
	# 継承先の初期化処理
	initialize_ui()

# テスト用のUI初期化をオーバーライド
func initialize_ui():
	# テスト用メッセージを表示
	show_test_message()

func show_test_message():
	"""テスト用のメッセージ表示"""
	show_message("テストキャラクター", "これはサンプルUIのテストメッセージです。\\n[color=cyan]RichTextLabel[/color]を使用しているため、[b]太字[/b]や[i]斜体[/i]も使えます。", Color.YELLOW)
