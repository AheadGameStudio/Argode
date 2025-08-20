extends ArgodeCommandBase
class_name UICommand

var transition_value:String
var z_index_value:int
var variable_manager:ArgodeVariableManager
var ui_manager:ArgodeUIManager

# 組み込みのUIについてはVariableManagerの変数は利用しないため、
# ArgoSystemから各組み込みUIのパスを取得する必要がある。

func _ready():
	command_class_name = "UICommand"
	command_execute_name = "ui"
	command_description = "UIの表示・非表示・削除を行います"
	command_help = "ui [アクション] [UIエイリアス] [Z-Index 値] [with アニメーション名]"

	# ArgodeSystemの変数として定義したUIを利用するため、
	# VariableManagerで管理されている変数を取得しなければならない。
	# そのため、VariableManagerのインスタンスを取得する必要がある。
	variable_manager = ArgodeSystem.VariableManager
	if not variable_manager:
		log_error("❌ VariableManager is not initialized")
		return
	ui_manager = ArgodeSystem.UIManager
	if not ui_manager:
		log_error("❌ UIManager is not initialized")
		return

func validate_args(args: Dictionary) -> bool:

	var ui_action = args.get("arg0", "")	# show/hide/delete
	var ui_alias = args.get("arg1", "")

	# 1. RegExオブジェクトを作成
	var regex = RegEx.new()
	# 2. 正規表現パターンをコンパイル
	regex.compile("^(show|hide|delete)$")
	var result = regex.search(ui_action)

	if not result:
		log_error("UIコマンドにはアクション（show/hide/delete）が必要です")
		return false

	if not ui_alias:
		log_error("UIコマンドにはUI定義がされた変数またはビルトインUIのエイリアスが必要です")
		return false
	else:
		# UIエイリアスがビルトインUIに含まれるか？
		if ArgodeSystem.built_in_ui_paths.has(ui_alias):
			log_info("UIコマンドにビルトインUIのエイリアスが指定されました: %s" % ui_alias)
		else:
			# そうじゃなければ、VariableManagerで管理されている変数として扱う
			var ui_variable = variable_manager.get_variable(ui_alias)
			# 変数が見つからない場合はエラー
			if not ui_variable:
				log_error("UIコマンドに指定された変数が見つかりません: %s" % ui_alias)
				return false

	# argsから"with"の値があるかを検索
	if get_subcommand_arg(args, "with") == null:
		log_error("UIコマンドに'with'サブコマンドを指定する場合その引数が必要です")
		return false
	else:
		transition_value = str(get_subcommand_arg(args, "with"))

	if get_subcommand_arg(args, "z_index") != null:
		var _z_index = get_subcommand_arg(args, "z_index")

		if _z_index == null:
			# z_indexが指定されているのに次の引数がない場合はエラー
			return false

		if not _z_index : # falseで帰ってきた場合
			# そもそもz_indexが不要な場合はデフォルト値として0を設定
			log_info("Z-Indexが指定されていないため、デフォルト値0を使用します")
			z_index_value = 0
		else:
			log_info("Z-Indexが指定されました: %s" % _z_index)
			# そうでなければ強制的に整数に変換（文字列なので）
			z_index_value = int(_z_index)
	return true

func execute_core(args: Dictionary) -> void:
	# 引数を受け取って処理を行う

	# UIアクションの取得
	var ui_action = args.get("arg0", "")
	# UIのエイリアス（または変数名）
	var ui_alias = args.get("arg1", "")
	# UIのZ-Index
	var ui_z_index = z_index_value
	# UIのトランジション
	var ui_transition = transition_value

	log_info("UIコマンド実行: [%s] %s, Z-Index: %d, Transition: %s" % [ui_action, ui_alias, ui_z_index, ui_transition])


	# UIマネージャーに管理されたUIかを確認
	if not ui_manager.get_all_ui().has(ui_alias):
		log_error("指定されたUIは管理されていません: %s" % ui_alias)
		# 管理されてないので新たにUIをaddする。
		# まずはエイリアスからシーンパスを取得する。
		if ArgodeSystem.built_in_ui_paths.has(ui_alias):
			var scene_path = ArgodeSystem.built_in_ui_paths[ui_alias]
			if ResourceLoader.exists(scene_path):
				ui_manager.add_ui(scene_path, ui_alias)
			else:
				log_error("指定されたUIのシーンパスが見つかりません: %s" % ui_alias)
				return
		elif variable_manager.has_variable(ui_alias):
			var ui_variable = variable_manager.get_variable(ui_alias)
			# ui_variableが有効なシーンパスならaddする
			if ResourceLoader.exists(ui_variable):
				ui_manager.add_ui(ui_variable, ui_alias, ui_z_index)
			else:
				log_error("指定されたUIのシーンパスが見つかりません: %s" % ui_alias)
				return
		else:
			log_error("指定されたUIのエイリアスが見つかりません: %s" % ui_alias)
			return

	# UIアクションの実行
	if ui_action == "show":
		ui_manager.show_ui(ui_alias)
	elif ui_action == "hide":
		ui_manager.hide_ui(ui_alias)
	elif ui_action == "delete":
		ui_manager.delete_ui(ui_alias)
