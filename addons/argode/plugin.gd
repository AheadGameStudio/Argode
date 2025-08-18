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
const PROJECT_SETTING_SYSTEM_FONT_NORMAL = "argode/fonts/system_font_normal"
const PROJECT_SETTING_SYSTEM_FONT_BOLD = "argode/fonts/system_font_bold"
const PROJECT_SETTING_SERIF_FONT_NORMAL = "argode/fonts/serif_font_normal"
const PROJECT_SETTING_SERIF_FONT_BOLD = "argode/fonts/serif_font_bold"


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
    # 注意: プロジェクト設定は削除しません（ユーザーの設定を保持）
    # _remove_project_settings()

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
    
    # システムフォント（通常）設定
    if not ProjectSettings.has_setting(PROJECT_SETTING_SYSTEM_FONT_NORMAL):
        ProjectSettings.set_setting(PROJECT_SETTING_SYSTEM_FONT_NORMAL, "")
    
    # システムフォント（太字）設定
    if not ProjectSettings.has_setting(PROJECT_SETTING_SYSTEM_FONT_BOLD):
        ProjectSettings.set_setting(PROJECT_SETTING_SYSTEM_FONT_BOLD, "")
    
    # セリフフォント（通常）設定
    if not ProjectSettings.has_setting(PROJECT_SETTING_SERIF_FONT_NORMAL):
        ProjectSettings.set_setting(PROJECT_SETTING_SERIF_FONT_NORMAL, "")
    
    # セリフフォント（太字）設定
    if not ProjectSettings.has_setting(PROJECT_SETTING_SERIF_FONT_BOLD):
        ProjectSettings.set_setting(PROJECT_SETTING_SERIF_FONT_BOLD, "")
    
    # 設定のプロパティ情報を定義
    var settings_info = [
        {
            "name": PROJECT_SETTING_SHOW_LOADING,
            "type": TYPE_BOOL,
            "hint": PROPERTY_HINT_NONE,
            "hint_string": ""
        },
        {
            "name": PROJECT_SETTING_COMMAND_DIR,
            "type": TYPE_STRING,
            "hint": PROPERTY_HINT_DIR,
            "hint_string": ""
        },
        {
            "name": PROJECT_SETTING_DEFINITION_DIR,
            "type": TYPE_STRING,
            "hint": PROPERTY_HINT_DIR,
            "hint_string": ""
        },
        {
            "name": PROJECT_SETTING_SCENARIO_DIR,
            "type": TYPE_STRING,
            "hint": PROPERTY_HINT_DIR,
            "hint_string": ""
        },
        {
            "name": PROJECT_SETTING_SYSTEM_FONT_NORMAL,
            "type": TYPE_STRING,
            "hint": PROPERTY_HINT_FILE,
            "hint_string": "*.ttf,*.otf,*.tres,*.res"
        },
        {
            "name": PROJECT_SETTING_SYSTEM_FONT_BOLD,
            "type": TYPE_STRING,
            "hint": PROPERTY_HINT_FILE,
            "hint_string": "*.ttf,*.otf,*.tres,*.res"
        },
        {
            "name": PROJECT_SETTING_SERIF_FONT_NORMAL,
            "type": TYPE_STRING,
            "hint": PROPERTY_HINT_FILE,
            "hint_string": "*.ttf,*.otf,*.tres,*.res"
        },
        {
            "name": PROJECT_SETTING_SERIF_FONT_BOLD,
            "type": TYPE_STRING,
            "hint": PROPERTY_HINT_FILE,
            "hint_string": "*.ttf,*.otf,*.tres,*.res"
        }
    ]
    
    # 各設定をプロジェクト設定に追加
    for info in settings_info:
        ProjectSettings.add_property_info(info)
    
    # 現在の設定値をデバッグ出力
    print("📊 現在のArgode設定値:")
    var all_settings = [
        PROJECT_SETTING_SHOW_LOADING,
        PROJECT_SETTING_COMMAND_DIR,
        PROJECT_SETTING_DEFINITION_DIR,
        PROJECT_SETTING_SCENARIO_DIR,
        PROJECT_SETTING_SYSTEM_FONT_NORMAL,
        PROJECT_SETTING_SYSTEM_FONT_BOLD,
        PROJECT_SETTING_SERIF_FONT_NORMAL,
        PROJECT_SETTING_SERIF_FONT_BOLD
    ]
    
    for setting in all_settings:
        var value = ProjectSettings.get_setting(setting, "未設定")
        print("  %s = %s" % [setting, str(value)])
    
    # 設定を保存（強制）
    var save_result = ProjectSettings.save()
    if save_result == OK:
        print("✅ Argodeプロジェクト設定が正常に保存されました。")
    else:
        print("❌ Argodeプロジェクト設定の保存に失敗しました。エラーコード: %d" % save_result)

func _remove_project_settings():
    # Argodeプロジェクト設定を削除します。
    var settings_to_remove = [
        PROJECT_SETTING_SHOW_LOADING,
        PROJECT_SETTING_COMMAND_DIR,
        PROJECT_SETTING_DEFINITION_DIR,
        PROJECT_SETTING_SCENARIO_DIR,
        PROJECT_SETTING_SYSTEM_FONT_NORMAL,
        PROJECT_SETTING_SYSTEM_FONT_BOLD,
        PROJECT_SETTING_SERIF_FONT_NORMAL,
        PROJECT_SETTING_SERIF_FONT_BOLD
    ]
    
    for setting in settings_to_remove:
        if ProjectSettings.has_setting(setting):
            ProjectSettings.clear(setting)
    
    # 設定を保存（強制）
    var save_result = ProjectSettings.save()
    if save_result == OK:
        print("✅ Argodeプロジェクト設定が正常に削除されました。")
    else:
        print("❌ Argodeプロジェクト設定の削除保存に失敗しました。エラーコード: %d" % save_result)