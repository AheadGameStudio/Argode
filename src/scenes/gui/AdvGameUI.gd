# AdvGameUI.gd
# v2設計: AdvScreenを継承した最小限のADVゲーム用UI実装例
# 大部分の機能はAdvScreenで自動提供されます
extends ArgodeScreen
class_name AdvGameUI

# === プロジェクト固有の設定をここで初期化 ===

func _ready():
	# ArgodeScreen基底クラスの設定を行う（継承したプロパティを使用）
	auto_start_script = true
	default_script_path = "res://scenarios/main.rgd"
	start_label = "start"
	
	super._ready()
	print("🎨 AdvGameUI initialized (minimal v2 implementation)")
	
	# 初期状態設定（必要に応じて）
	if choice_container:
		choice_container.visible = false
	if message_box:
		message_box.visible = true
	if continue_prompt:
		continue_prompt.visible = false

# === 継承可能な仮想メソッド ===

func on_screen_ready():
	"""画面初期化完了時の処理（AdvScreenで自動実行される）"""
	# 必要に応じてカスタム初期化処理を追加
	pass

func on_screen_shown(parameters: Dictionary = {}):
	"""画面表示時の処理"""
	super.on_screen_shown(parameters)
	# 必要に応じてカスタム表示処理を追加

# === プロジェクト固有のカスタマイズ ===

func on_character_typed(_character: String, _position: int):
	"""文字が入力された時のカスタム処理"""
	# 例: 文字入力時のサウンド効果など
	pass

func on_dynamic_signal_emitted(signal_name: String, args: Array, source_command: String):
	"""カスタムコマンドからの動的シグナル受信時の処理"""
	super.on_dynamic_signal_emitted(signal_name, args, source_command)
	
	# プロジェクト固有の動的シグナル処理を追加
	match signal_name:
		"custom_project_signal":
			# プロジェクト固有の処理
			pass
		_:
			# 未処理のシグナルはそのまま
			pass

# === 注意：基本機能はAdvScreenで自動提供されます ===
# show_message(), show_choices(), hide_ui() などの基本機能は
# AdvScreen基底クラスで提供されるため、ここで実装する必要はありません。
# 
# 必要に応じて、これらのメソッドをオーバーライドして
# プロジェクト固有のカスタマイズを追加できます。

# === 実装完了 ===
#
# この最小限のAdvGameUIクラスは、AdvScreenの標準機能をすべて自動継承し、
# プロジェクト固有の設定（auto_start_script等）のみを定義します。
#
# 追加したい機能がある場合は、以下の仮想メソッドをオーバーライドしてください：
# - on_screen_ready(): 画面初期化完了時
# - on_screen_shown(): 画面表示時  
# - on_character_typed(): タイプライター文字入力時
# - on_dynamic_signal_emitted(): カスタムコマンドシグナル受信時
#
# 基本的なUI機能（show_message, show_choices, hide_ui, 入力処理等）は
# すべてAdvScreen基底クラスで自動提供されます。