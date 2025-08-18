# plugin.gd
@tool
extends EditorPlugin

## Argodeフレームワークのオートロードを管理するエディタプラグインです。
## このプラグインを有効にすることで、プロジェクト全体でArgodeSystemが利用可能になります。

# オートロード名
const AUTOLOAD_NAME = "ArgodeSystem"
# オートロードするスクリプトのパス
const AUTOLOAD_PATH = "res://addons/argode/core/ArgodeSystem.gd"

# プロジェクト設定のキー定数
const PROJECT_SETTING_SHOW_LOADING = "argode/general/show_loading_screen"
const PROJECT_SETTING_COMMAND_DIR = "argode/general/custom_command_directory"
const PROJECT_SETTING_DEFINITION_DIR = "argode/general/definition_directory"
const PROJECT_SETTING_SCENARIO_DIR = "argode/general/scenario_directory"


func _enter_tree():
    # プラグインが有効になったときに呼び出されます。
    # ArgodeSystemをオートロードとして追加します。
    _add_autoload()
    # プロジェクト設定を追加します。
    _add_project_settings()

func _exit_tree():
    # プラグインが無効になったときに呼び出されます。
    # ArgodeSystemをオートロードから削除します。
    _remove_autoload()
    # プロジェクト設定を削除します。
    _remove_project_settings()

func _add_autoload():
    # オートロードを追加する処理
    # エディタにArgodeSystemをオートロードとして登録します。
    # EditorInterfaceクラスのadd_autoload_singletonメソッドを使用します。
    if not Engine.has_singleton(AUTOLOAD_NAME):
        add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)
        print("🎉ArgodeSystem has been added as a singleton.")

func _remove_autoload():
    # オートロードを削除する処理
    # エディタからArgodeSystemをオートロード登録から削除します。
    # EditorInterfaceクラスのremove_autoload_singletonメソッドを使用します。
    if Engine.has_singleton(AUTOLOAD_NAME):
        remove_autoload_singleton(AUTOLOAD_NAME)
        print("👋ArgodeSystem has been removed from singletons.")

func _add_project_settings():
    # Argodeプロジェクト設定を追加します。
    
    # 初期化プログレス画面の表示設定
    if not ProjectSettings.has_setting(PROJECT_SETTING_SHOW_LOADING):
        ProjectSettings.set_setting(PROJECT_SETTING_SHOW_LOADING, true)
    
    # カスタムコマンドディレクトリ設定
    if not ProjectSettings.has_setting(PROJECT_SETTING_COMMAND_DIR):
        ProjectSettings.set_setting(PROJECT_SETTING_COMMAND_DIR, "res://custom_commands/")
    
    # 定義ディレクトリ設定
    if not ProjectSettings.has_setting(PROJECT_SETTING_DEFINITION_DIR):
        ProjectSettings.set_setting(PROJECT_SETTING_DEFINITION_DIR, "res://definitions/")
    
    # シナリオディレクトリ設定
    if not ProjectSettings.has_setting(PROJECT_SETTING_SCENARIO_DIR):
        ProjectSettings.set_setting(PROJECT_SETTING_SCENARIO_DIR, "res://scenarios/")
    
    # 設定のプロパティ情報を定義
    var setting_info = {}
    
    # 初期化プログレス画面の表示
    setting_info[PROJECT_SETTING_SHOW_LOADING] = {
        "name": PROJECT_SETTING_SHOW_LOADING,
        "type": TYPE_BOOL,
        "hint": PROPERTY_HINT_NONE,
        "hint_string": ""
    }
    
    # カスタムコマンドディレクトリ
    setting_info[PROJECT_SETTING_COMMAND_DIR] = {
        "name": PROJECT_SETTING_COMMAND_DIR,
        "type": TYPE_STRING,
        "hint": PROPERTY_HINT_DIR,
        "hint_string": ""
    }
    
    # 定義ディレクトリ
    setting_info[PROJECT_SETTING_DEFINITION_DIR] = {
        "name": PROJECT_SETTING_DEFINITION_DIR,
        "type": TYPE_STRING,
        "hint": PROPERTY_HINT_DIR,
        "hint_string": ""
    }
    
    # シナリオディレクトリ
    setting_info[PROJECT_SETTING_SCENARIO_DIR] = {
        "name": PROJECT_SETTING_SCENARIO_DIR,
        "type": TYPE_STRING,
        "hint": PROPERTY_HINT_DIR,
        "hint_string": ""
    }
    
    # 各設定をプロジェクト設定に追加
    for setting_path in setting_info:
        var info = setting_info[setting_path]
        ProjectSettings.add_property_info(info)
    
    # 設定を保存
    ProjectSettings.save()
    print("🎛️ Argodeプロジェクト設定が追加されました。")

func _remove_project_settings():
    # Argodeプロジェクト設定を削除します。
    var settings_to_remove = [
        PROJECT_SETTING_SHOW_LOADING,
        PROJECT_SETTING_COMMAND_DIR,
        PROJECT_SETTING_DEFINITION_DIR,
        PROJECT_SETTING_SCENARIO_DIR
    ]
    
    for setting in settings_to_remove:
        if ProjectSettings.has_setting(setting):
            ProjectSettings.clear(setting)
    
    # 設定を保存
    ProjectSettings.save()
    print("🗑️ Argodeプロジェクト設定が削除されました。")