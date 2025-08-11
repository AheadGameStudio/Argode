@tool
extends ResourceFormatLoader
class_name RgdFormatLoader

## Argodeスクリプトファイル（.rgd）のカスタムフォーマットローダー
## Godotエディタでrgdファイルを開けるようにする

# どの拡張子を扱うかを返す
func _get_recognized_extensions() -> PackedStringArray:
    return ["rgd"]

# Godot内部でどういうリソースタイプとして扱うかを返す
func _get_resource_type(path: String) -> String:
    # Textとして扱う（Godot 4の標準）
    return "Resource"

# ファイルシステムドックに表示されるアイコンを指定
func _get_resource_script_class(path: String) -> String:
    # テキストファイルのアイコンを使用
    return ""

# このローダーが外部のリソース（ファイル）を扱うことを示す
func _handles_type(type: StringName) -> bool:
    return type == &"Resource"

# ファイルを実際に読み込む処理
func _load(path: String, original_path: String = "", use_sub_threads: bool = false, cache_mode: int = 0) -> Resource:
    # ファイルからテキストを読み込む
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        print("❌ RgdFormatLoader: Failed to open file: ", path)
        return null # エラーハンドリング

    var content := file.get_as_text()
    file.close()

    # カスタムリソースクラスを作成
    var rgd_resource := RgdResource.new()
    rgd_resource.content = content
    rgd_resource.resource_path = path
    
    # デバッグ出力
    print("📄 RgdFormatLoader: Loaded RGD file: ", path, " (", content.length(), " characters)")
    
    return rgd_resource