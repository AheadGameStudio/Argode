# TitleScreen.gd
# タイトル画面のサンプル実装
extends "res://addons/argode/ui/ArgodeUIScene.gd"

@export var start_button: Button
@export var load_button: Button
@export var config_button: Button
@export var exit_button: Button

func _ready():
	super._ready()  # 親クラスの_ready()を呼び出し
	_setup_buttons()

func _setup_buttons():
	"""ボタンの設定"""
	print("🎮 [TitleScreen] Setting up buttons...")
	
	# ボタンがNodePathで指定されている場合は取得
	if not start_button and has_node("StartButton"):
		start_button = get_node("StartButton")
	if not load_button and has_node("LoadButton"):
		load_button = get_node("LoadButton")
	if not config_button and has_node("ConfigButton"):
		config_button = get_node("ConfigButton")
	if not exit_button and has_node("ExitButton"):
		exit_button = get_node("ExitButton")
	
	# シグナル接続
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
		print("✅ [TitleScreen] Start button connected")
	
	if load_button:
		load_button.pressed.connect(_on_load_pressed)
		print("✅ [TitleScreen] Load button connected")
	
	if config_button:
		config_button.pressed.connect(_on_config_pressed)
		print("✅ [TitleScreen] Config button connected")
	
	if exit_button:
		exit_button.pressed.connect(_on_exit_pressed)
		print("✅ [TitleScreen] Exit button connected")

# === ボタンハンドラー ===

func _on_start_pressed():
	"""新しくゲームを開始"""
	print("🎮 [TitleScreen] Start game pressed")
	
	# フラグをリセット
	set_variable("game_started", true)
	set_variable("new_game", true)
	
	# メッセージウィンドウを表示
	show_message_window()
	
	# ゲーム開始ラベルにジャンプ
	execute_argode_command("jump", {"label": "game_start"})
	
	# 自分を閉じる
	close_self()

func _on_load_pressed():
	"""セーブデータをロード"""
	print("📂 [TitleScreen] Load game pressed")
	
	# セーブデータ選択画面を表示
	execute_argode_command("ui", {
		"subcommand": "call",
		"scene_path": "res://screens/save_load/SaveLoadScreen.tscn",
		"mode": "load"
	})

func _on_config_pressed():
	"""設定画面を開く"""
	print("⚙️ [TitleScreen] Config pressed")
	
	# 設定画面を表示
	execute_argode_command("ui", {
		"subcommand": "call", 
		"scene_path": "res://screens/config/ConfigScreen.tscn"
	})

func _on_exit_pressed():
	"""ゲームを終了"""
	print("🚪 [TitleScreen] Exit pressed")
	
	# 終了確認
	var choices = ["はい", "いいえ"]
	var choice = await show_choices(choices)
	
	if choice == 0:  # はい
		# ゲーム終了処理
		execute_argode_command("jump", {"label": "game_exit"})
		close_self()
	# いいえの場合は何もしない

# === 応用例：複雑な処理 ===

func _on_start_with_character_selection():
	"""キャラクター選択付きの開始"""
	print("👥 [TitleScreen] Character selection start")
	
	# キャラクター選択肢
	var character_choices = ["勇者", "魔法使い", "僧侶", "戦士"]
	show_message("システム", "キャラクターを選択してください")
	
	var selected_character = await show_choices(character_choices)
	
	# 選択結果を変数に保存
	set_variable("selected_character", character_choices[selected_character])
	set_variable("character_index", selected_character)
	
	show_message("システム", character_choices[selected_character] + "を選択しました")
	
	# キャラクター固有の開始ラベルにジャンプ
	var start_labels = ["hero_start", "mage_start", "priest_start", "warrior_start"]
	execute_argode_command("jump", {"label": start_labels[selected_character]})
	
	close_self()

# === call_screenとしての使用例 ===

func show_as_modal_with_result():
	"""モーダルダイアログとして結果を返す例"""
	print("🎭 [TitleScreen] Showing as modal dialog")
	
	hide_message_window()  # メッセージウィンドウを隠す
	
	# 何かの選択を行う
	var choices = ["オプション1", "オプション2", "キャンセル"]
	var choice = await show_choices(choices)
	
	if choice == 2:  # キャンセル
		return_result(null)
	else:
		return_result({
			"selected_option": choice,
			"option_name": choices[choice]
		})
