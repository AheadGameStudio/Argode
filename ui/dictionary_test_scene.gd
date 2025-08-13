extends ArgodeUIScene

@onready var status_label: Label = $StatusLabel
@onready var level_button: Button = $LevelUpButton
@onready var friendship_button: Button = $FriendshipButton

func _ready():
	super._ready()
	setup_ui()
	update_display()

func setup_ui():
	# ゲームデータの初期化
	setup_character_status()
	setup_story_flags()
	
	# 初期キャラクター設定
	set_nested_variable("characters.player.name", "テストプレイヤー")
	set_nested_variable("characters.player.level", 1)
	set_nested_variable("characters.player.experience", 0)
	
	# 好感度システムの初期化
	set_nested_variable("characters.player.friendship.yuko", 50)
	set_nested_variable("characters.player.friendship.saitos", 30)
	
	# ストーリーフラグの設定
	set_flag_in_group("story", "tutorial_complete", true)
	set_flag_in_group("story", "chapter1_started", true)
	
	# ボタンイベントの接続
	if level_button:
		level_button.pressed.connect(_on_level_up_pressed)
	if friendship_button:
		friendship_button.pressed.connect(_on_friendship_up_pressed)

func update_display():
	if not status_label:
		return
		
	var player_name = get_nested_variable("characters.player.name")
	var player_level = get_nested_variable("characters.player.level")
	var yuko_friendship = get_character_friendship("yuko")
	var saitos_friendship = get_character_friendship("saitos")
	
	var tutorial_complete = get_flag("story.tutorial_complete")
	var chapter1_started = get_flag("story.chapter1_started")
	
	var display_text = "=== ゲーム状況 ===\n"
	display_text += "プレイヤー名: %s\n" % player_name
	display_text += "レベル: %d\n" % player_level
	display_text += "\n=== 好感度 ===\n"
	display_text += "ユウコ: %d\n" % yuko_friendship
	display_text += "サイトス: %d\n" % saitos_friendship
	display_text += "\n=== ストーリー進行 ===\n"
	display_text += "チュートリアル: %s\n" % ("完了" if tutorial_complete else "未完了")
	display_text += "Chapter1: %s\n" % ("開始済み" if chapter1_started else "未開始")
	
	status_label.text = display_text

func _on_level_up_pressed():
	var current_level = get_nested_variable("characters.player.level")
	set_nested_variable("characters.player.level", current_level + 1)
	
	var current_exp = get_nested_variable("characters.player.experience") 
	set_nested_variable("characters.player.experience", current_exp + 100)
	
	update_display()
	print("レベルアップ！現在レベル: ", get_nested_variable("characters.player.level"))

func _on_friendship_up_pressed():
	modify_character_friendship("yuko", 5)
	modify_character_friendship("saitos", 3)
	update_display()
	print("好感度アップ！ユウコ: ", get_character_friendship("yuko"), 
		  ", サイトス: ", get_character_friendship("saitos"))

func _on_test_dictionary_pressed():
	# 辞書機能の実践的なテスト
	print("=== 辞書機能テスト開始 ===")
	
	# 複雑な辞書構造のテスト
	create_variable_group("game_settings", {
		"graphics": {"quality": "high", "vsync": true},
		"audio": {"master_volume": 100, "bgm_volume": 80, "se_volume": 90},
		"input": {"key_bindings": {"jump": "space", "attack": "z", "menu": "escape"}}
	})
	
	print("グラフィック品質: ", get_nested_variable("game_settings.graphics.quality"))
	print("マスターボリューム: ", get_nested_variable("game_settings.audio.master_volume"))
	print("ジャンプキー: ", get_nested_variable("game_settings.input.key_bindings.jump"))
	
	# 動的にデータを変更
	set_nested_variable("game_settings.audio.master_volume", 75)
	print("ボリューム変更後: ", get_nested_variable("game_settings.audio.master_volume"))
	
	print("=== 辞書機能テスト終了 ===")
